module mf6_post_module
  ! -- modules
  use utilsmod, only: i4b, i8b, r4b, r8b, mxslen, tBb, DZERO, DONE, &
    errmsg, logmsg, swap_slash, open_file, chkexist, get_jd, get_ymd_from_jd, ta
  use raster_io, only: raster_t, raster_open, raster_read_block, raster_write
  !
  implicit none
  !
  private
  !
  ! -- parameters
  logical :: include_sea = .true.
  !
  character(len=1), parameter :: comment = '#'
  real(r8b) :: r8nodata = -9999.D0
  !
  integer(i4b), parameter :: i_hds = 0
  integer(i4b), parameter :: i_wtd = 1
  !
  ! mf6 binary head record: kstp, kper, pertim, totim, text(16), ncol, nrow, ilay
  integer(i8b), parameter :: nbhdr = 4 + 4 + 8 + 8 + 16 + 4 + 4 + 4
  !
  ! -- global variables
  integer(i4b) :: gncol = 0
  integer(i4b) :: gnrow = 0
  integer(i4b) :: gnlay = 0
  real(r8b)    :: gxmin = DZERO
  real(r8b)    :: gymin = DZERO
  real(r8b)    :: gcs   = DZERO
  character(len=mxslen) :: sdate = ''
  !
  ! top of the uppermost layer, a window of the global grid: global index
  ! minus topicoff/topiroff, as tData in mf6_module
  type(raster_t) :: topr
  integer(i4b) :: topicoff = 0
  integer(i4b) :: topiroff = 0
  !
  ! types
  type tGen
    character(len=mxslen) :: in_dir   = ''
    character(len=mxslen) :: in_postf = ''
    character(len=mxslen) :: out_dir  = ''
    character(len=mxslen) :: out_pref = ''
    integer(i4b)          :: itype    = 0
    integer(i4b)          :: il_min   = 0
    integer(i4b)          :: il_max   = 0
    integer(i4b)          :: kper_beg = 0
    integer(i4b)          :: kper_end = 0
  end type tGen
  !
  type tPostMod
    integer(i4b)                              :: modid = 0
    character(len=6)                          :: modname = ''
    integer(i4b)                              :: iu = -1
    type(tBb)                                 :: bb
    integer(i4b)                              :: nodes = 0
    integer(i4b), dimension(:,:), allocatable :: giliric
    real(r8b)                                 :: totim_read = DZERO
    real(r8b), dimension(:), allocatable      :: top
    real(r8b), dimension(:), allocatable      :: r8buff
    !
    type(tGen), pointer :: gen => null()
  contains
    procedure :: init        => mf6_post_mod_init
    procedure :: read_nodbin => mf6_post_mod_read_nodbin
    procedure :: read_top    => mf6_post_mod_read_top
    procedure :: read        => mf6_post_mod_read
    procedure :: get_data    => mf6_post_mod_get_data
    procedure :: clean       => mf6_post_mod_clean
  end type tPostMod
  !
  type tPostSol
    integer(i4b)                              :: solid = 0
    character(len=3)                          :: solname = ''
    type(tBb)                                 :: bb
    integer(i4b)                              :: nmod = 0
    type(tPostMod), dimension(:), allocatable :: mod
    !
    type(tGen), pointer :: gen => null()
  contains
    procedure :: init  => mf6_post_sol_init
    procedure :: write => mf6_post_sol_write
    procedure :: clean => mf6_post_sol_clean
  end type tPostSol
  !
  save
  !
  public :: include_sea
  public :: comment
  public :: r8nodata
  public :: tPostSol
  public :: gncol, gnrow, gnlay, gxmin, gymin, gcs, sdate
  public :: mf6_post_init_top
  
  contains
  !
  subroutine mf6_post_init_top(f)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: f
! ------------------------------------------------------------------------------
    call raster_open(topr, f)
    if (abs(topr%dx - gcs) > 1.d-9*gcs) then
      call errmsg('cell size of '//trim(f)//' differs from the model grid')
    end if
    topicoff = nint((topr%xmin - gxmin)/gcs)
    topiroff = nint(((gymin + gnrow*gcs) - topr%ymax)/gcs)
    !
    return
  end subroutine mf6_post_init_top

! ==============================================================================
! subroutines/functions type tPostMod
! ==============================================================================
  
  subroutine mf6_post_mod_init(this, gen)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
    type(tGen), pointer, intent(in) :: gen
    ! --- local
    character(len=mxslen) :: f
! ------------------------------------------------------------------------------
    this%gen => gen
    write(this%modname,'(a,i5.5)') 'm', this%modid
    !
    call this%read_nodbin()
    if (this%nodes == 0) return
    !
    if (gen%itype == i_wtd) then
      call this%read_top()
    end if
    !
    f = trim(gen%in_dir)//'models\run_output_bin\'// &
      trim(this%modname)//trim(gen%in_postf)
    call swap_slash(f)
    call chkexist(f)
    call open_file(f, this%iu, 'r', .true.)
    !
    return
  end subroutine mf6_post_mod_init
  
  subroutine mf6_post_mod_read_nodbin(this)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
    ! --- local
    integer(i4b) :: iu, i, j
    character(len=mxslen) :: f
! ------------------------------------------------------------------------------
    f = trim(this%gen%in_dir)//'models\post_mappings\'//trim(this%modname)// &
      '.nodmap.bin'
    call swap_slash(f)
    !
    call open_file(f, iu, 'r', .true.)
    read(iu) this%bb%ic0, this%bb%ic1, this%bb%ir0, this%bb%ir1
    this%bb%ncol = this%bb%ic1 - this%bb%ic0 + 1
    this%bb%nrow = this%bb%ir1 - this%bb%ir0 + 1
    read(iu) this%nodes
    allocate(this%giliric(3,this%nodes))
    read(iu)((this%giliric(j,i),j=1,3),i=1,this%nodes)
    close(iu)
    !
    return
  end subroutine mf6_post_mod_read_nodbin
  
  subroutine mf6_post_mod_read_top(this)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
    ! --- local
    real(r4b), dimension(:,:), pointer :: blk => null()
    real(r4b) :: r4nodata
    integer(i4b) :: i, ic, ir
! ------------------------------------------------------------------------------
    call raster_read_block(topr, &
      this%bb%ir0-topiroff, this%bb%ir1-topiroff, &
      this%bb%ic0-topicoff, this%bb%ic1-topicoff, blk)
    r4nodata = real(topr%nodata, r4b)
    !
    allocate(this%top(this%nodes))
    do i = 1, this%nodes
      ir = this%giliric(2,i) - this%bb%ir0 + 1
      ic = this%giliric(3,i) - this%bb%ic0 + 1
      if (blk(ic,ir) == r4nodata) then
        call errmsg('top is nodata at node '//ta((/i/))//' of '//trim(this%modname))
      end if
      this%top(i) = real(blk(ic,ir),r8b)
    end do
    deallocate(blk)
    !
    return
  end subroutine mf6_post_mod_read_top
    
  subroutine mf6_post_mod_read(this, kper)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
    integer(i4b), intent(in) :: kper
    ! --- local
    ! mf6 header:
    character(len=16) :: text_in ! ulasav
    integer(i4b) :: kstp_in, kper_in, ncol_in, nrow_in, ilay_in
    real(r8b) :: pertim_in, totim_in
    !
    integer(i4b) :: ios, i
    integer(i8b) :: ipos
! ------------------------------------------------------------------------------
    ipos = (kper - 1)*(nbhdr + 8*this%nodes) + 1
    read(unit=this%iu,iostat=ios,pos=ipos) kstp_in, kper_in, pertim_in, totim_in, &
      text_in, ncol_in, nrow_in, ilay_in
    if (ios /= 0) then
      call errmsg('Stress period '//ta((/kper/))//' not found in heads of model '// &
        trim(this%modname)//'.')
    end if
    if (ncol_in /= this%nodes) then
      call errmsg('Invalid number of nodes reading for model '// &
        trim(this%modname)//'.')
    end if
    if (kper_in /= kper) then
      call errmsg('Invalid stress period reading for model '// &
        trim(this%modname)//'.')
    end if
    !
    this%totim_read = totim_in
    !
    if (.not.allocated(this%r8buff)) then
      allocate(this%r8buff(this%nodes))
    end if
    read(unit=this%iu,iostat=ios)(this%r8buff(i),i=1,this%nodes)
    if (ios /= 0) then
      call errmsg('Could not read data.')
    end if
    !
    return
  end subroutine mf6_post_mod_read
  
  function mf6_post_get_out_pref(name, totim, il, gen) result(f)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: name
    real(r8b), intent(in) :: totim
    integer(i4b), intent(in) :: il
    type(tGen), pointer, intent(in) :: gen
    character(len=:), allocatable :: f
    ! --- local
    character(len=mxslen) :: ts
    integer(i4b) :: y, m, d, idum
    real(r8b) :: jd
! ------------------------------------------------------------------------------
    read(sdate(1:4),*) y; read(sdate(5:6),*) m
    d = 1
    jd = get_jd(y, m, d) + totim - DONE
    call get_ymd_from_jd(jd, idum, y, m, d)
    ts = ta((/y/))//ta((/m/),'(i2.2)')//ta((/d/),'(i2.2)')
    !
    f = trim(gen%out_dir)//trim(name)//'_'//trim(gen%out_pref)// &
      trim(ts)//'_l'//ta((/il/))//'.nc'
    !
    call swap_slash(f)
    return
  end function mf6_post_get_out_pref
  !
  function mf6_post_mod_get_data(this, il) result(r8x)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
    integer(i4b), intent(in) :: il
    real(r8b), dimension(:,:), allocatable :: r8x
    ! --- local
    logical :: ladd
    integer(i4b) :: gil, gir, gic, ir, ic, i
    integer(i4b), dimension(:,:), allocatable :: laytop
! ------------------------------------------------------------------------------
    allocate(r8x(this%bb%ncol,this%bb%nrow), laytop(this%bb%ncol,this%bb%nrow))
    r8x = r8nodata
    laytop = 0
    !
    do i = 1, this%nodes
      gil = this%giliric(1,i); gir = this%giliric(2,i); gic = this%giliric(3,i) ! global
      if (include_sea) gil = abs(gil)
      ir = gir - this%bb%ir0 + 1; ic = gic - this%bb%ic0 + 1 ! local
      !check
      if ((ir < 1).or.(ir > this%bb%nrow).or.(ic < 1).or.(ic > this%bb%ncol)) then
        call errmsg('mf6_post_mod_get_data')
      end if
      ladd = .true.
      if (il == 0) then
        if (laytop(ic,ir) == 1) then
          ladd = .false.
        else
          laytop(ic,ir) = 1
        end if
      else
        if (gil /= il) ladd = .false.
      end if
      if (ladd) then
        if (this%gen%itype == i_wtd) then
          r8x(ic,ir) = this%top(i) - this%r8buff(i) !Water table depth > 0!
        else
          r8x(ic,ir) = this%r8buff(i)
        end if
      end if
    end do
    !
    deallocate(laytop)
    !
    return
  end function mf6_post_mod_get_data
  
  subroutine mf6_post_mod_clean(this)
! ******************************************************************************
    ! -- arguments
    class(tPostMod) :: this
! ------------------------------------------------------------------------------
    if (this%iu > 0) close(this%iu)
    this%iu = -1
    if (allocated(this%giliric)) deallocate(this%giliric)
    if (allocated(this%r8buff))  deallocate(this%r8buff)
    if (allocated(this%top))     deallocate(this%top)
    this%gen => null()
    !
    return
  end subroutine mf6_post_mod_clean
  
! ==============================================================================
! subroutines/functions type tPostSol
! ==============================================================================
  
  subroutine mf6_post_sol_init(this, sa)
! ******************************************************************************
    ! -- arguments
    class(tPostSol) :: this
    character(len=*), dimension(:), intent(in) :: sa
    ! --- local
    type(tGen), pointer :: gen => null()
    character(len=mxslen) :: f
    integer(i4b) :: i, iu, ys, mns, y, mn
    integer(i4b), dimension(:), allocatable :: i4wk
! ------------------------------------------------------------------------------
    !
    ! 1                              2 3 4       5 6 7 8      9      10 11        12
    ! ../output/mf6ggm/steady-state/ s 1 .ss.hds 1 1 2 196001 196001 nc ../out/ wtd.ss.
    if (size(sa) /= 12) then
      call errmsg('Expected 12 fields: <in_dir> s <solution> <hds postfix> '// &
        '<0: head | 1: water table depth> <il_min> <il_max> <yyyymm beg> <yyyymm end> '// &
        'nc <out_dir> <out_pref>')
    end if
    !
    allocate(this%gen); gen => this%gen
    gen%in_dir = sa(1)
    if (trim(sa(2)) /= 's') then
      call errmsg('Unsupported mode '''//trim(sa(2))//'''; only s (solution).')
    end if
    read(sa(3),*) this%solid
    gen%in_postf = sa(4)
    read(sa(5),*) gen%itype
    if ((gen%itype /= i_hds).and.(gen%itype /= i_wtd)) then
      call errmsg('Unsupported type '//trim(sa(5))//'; 0 (head) or 1 (water table depth).')
    end if
    read(sa(6),*) gen%il_min
    read(sa(7),*) gen%il_max
    if ((gen%il_min < 0).or.(gen%il_min > gen%il_max).or.(gen%il_max > gnlay)) then
      call errmsg('Invalid layer range '//trim(sa(6))//' '//trim(sa(7))//'.')
    end if
    if ((len_trim(sa(8)) /= 6).or.(len_trim(sa(9)) /= 6).or.(len_trim(sdate) /= 6)) then
      call errmsg('Dates must be yyyymm.')
    end if
    !
    read(sdate(1:4),*) ys; read(sdate(5:6),*) mns
    read(sa(8)(1:4),*) y; read(sa(8)(5:6),*) mn
    gen%kper_beg = y*12 + (mn - 1) - (ys*12 + mns - 1) + 1
    read(sa(9)(1:4),*) y; read(sa(9)(5:6),*) mn
    gen%kper_end = y*12 + (mn - 1) - (ys*12 + mns - 1) + 1
    if ((gen%kper_beg < 1).or.(gen%kper_end < gen%kper_beg)) then
      call errmsg('Invalid date range '//trim(sa(8))//' '//trim(sa(9))// &
        ' for start date '//trim(sdate)//'.')
    end if
    !
    if (trim(sa(10)) /= 'nc') then
      call errmsg('Unsupported output format '''//trim(sa(10))//'''; only nc.')
    end if
    gen%out_dir  = sa(11)
    gen%out_pref = sa(12)
    !
    write(this%solname,'(a,i2.2)') 's', this%solid
    f = trim(gen%in_dir)//'solutions\post_mappings\'//trim(this%solname)//'.modmap.bin'
    call swap_slash(f)
    call chkexist(f)
    !
    call open_file(f, iu, 'r', .true.)
    read(iu) this%nmod
    allocate(this%mod(this%nmod), i4wk(this%nmod))
    read(iu)(i4wk(i),i=1,this%nmod)
    close(iu)
    !
    ! initialize the models
    do i = 1, this%nmod
      this%mod(i)%modid = i4wk(i)
      call this%mod(i)%init(gen)
    end do
    deallocate(i4wk)
    !
    ! determine the bounding box
    do i = 1, this%nmod
      if (this%mod(i)%nodes == 0) cycle
      this%bb%ic0 = min(this%bb%ic0, this%mod(i)%bb%ic0)
      this%bb%ic1 = max(this%bb%ic1, this%mod(i)%bb%ic1)
      this%bb%ir0 = min(this%bb%ir0, this%mod(i)%bb%ir0)
      this%bb%ir1 = max(this%bb%ir1, this%mod(i)%bb%ir1)
    end do
    this%bb%ncol = this%bb%ic1 - this%bb%ic0 + 1
    this%bb%nrow = this%bb%ir1 - this%bb%ir0 + 1
    !
    return
  end subroutine mf6_post_sol_init
  
  subroutine mf6_post_sol_write(this)
! ******************************************************************************
    ! -- arguments
    class(tPostSol) :: this
    ! --- local
    character(len=:), allocatable :: f
    integer(i4b) :: i, il, ic, ir, jc, jr, kper
    real(r8b) :: t, xmin, ymin
    real(r8b), dimension(:,:), allocatable :: sr8wk, mr8wk
! ------------------------------------------------------------------------------
    allocate(sr8wk(this%bb%ncol,this%bb%nrow))
    xmin = gxmin + (this%bb%ic0-1)*gcs
    ymin = gymin + (gnrow-this%bb%ir1)*gcs
    !
    do kper = this%gen%kper_beg, this%gen%kper_end
      t = -DONE
      do i = 1, this%nmod
        if (this%mod(i)%iu <= 0) cycle
        call this%mod(i)%read(kper)
        if (t < DZERO) t = this%mod(i)%totim_read
        if (this%mod(i)%totim_read /= t) then
          call errmsg('Inconsistent totim for stress period '//ta((/kper/))//'.')
        end if
      end do
      if (t < DZERO) then
        call errmsg('No model heads found for '//trim(this%solname)//'.')
      end if
      !
      do il = this%gen%il_min, this%gen%il_max
        sr8wk = r8nodata
        do i = 1, this%nmod
          associate(m => this%mod(i))
          if (m%iu <= 0) cycle
          mr8wk = m%get_data(il)
          do ir = 1, m%bb%nrow
            do ic = 1, m%bb%ncol
              if (mr8wk(ic,ir) /= r8nodata) then
                jr = ir + m%bb%ir0 - this%bb%ir0; jc = ic + m%bb%ic0 - this%bb%ic0
                if ((jr < 1).or.(jr > this%bb%nrow).or.(jc < 1).or.(jc > this%bb%ncol)) then
                  call errmsg('mf6_post_sol_write')
                end if
                sr8wk(jc,jr) = mr8wk(ic,ir)
              end if
            end do
          end do
          end associate
        end do
        f = mf6_post_get_out_pref(this%solname, t, il, this%gen)
        call logmsg('Writing '//f//'...')
        call raster_write(f, real(sr8wk,r4b), xmin, ymin, gcs, real(r8nodata,r4b))
      end do
    end do
    !
    deallocate(sr8wk)
    if (allocated(mr8wk)) deallocate(mr8wk)
    !
    return
  end subroutine mf6_post_sol_write
  
  subroutine mf6_post_sol_clean(this)
! ******************************************************************************
    ! -- arguments
    class(tPostSol) :: this
    ! --- local
    integer(i4b) :: i
! ------------------------------------------------------------------------------
    do i = 1, this%nmod
      call this%mod(i)%clean()
    end do
    deallocate(this%mod)
    deallocate(this%gen); this%gen => null()
    this%nmod = 0
    this%bb = tBb()
    !
    return
  end subroutine mf6_post_sol_clean

end module mf6_post_module
