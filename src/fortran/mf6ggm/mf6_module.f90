! ==============================================================================
module mf6_module
   ! -- modules
  use, intrinsic :: iso_fortran_env , only: error_unit, output_unit, &
     i1b => int8, i2b => int16, i4b => int32, i8b => int64, r4b => real32, r8b => real64
  use utilsmod, only: getlun, chkexist, readline, change_case, errmsg, logmsg_u => logmsg, &
    create_dir, ta_u => ta, get_work_dir, &
    get_jd, jd_next_month, getwords, getminmax, &
    IZERO, RZERO, DZERO, DONE, tBB, &
    get_ymd_from_jd, get_month_days_s
  use raster_io, only: raster_t, raster_open, raster_read_block, raster_write, raster_time, &
    raster_create_i4
  use omp_lib, only: omp_get_wtime, omp_get_thread_num
  use chunk_io, only: read_slice_chunks, write_raster_chunks
  use, intrinsic :: iso_c_binding, only: c_int64_t, c_int, c_ptr, c_funptr, c_null_ptr, c_null_funptr

  implicit none 

  ! data keys
  integer(i4b), parameter :: i_top               = 1; public :: i_top !debug
  integer(i4b), parameter :: i_bot               = 2
  integer(i4b), parameter :: i_k                 = 3
  integer(i4b), parameter :: i_k33               = 4
  integer(i4b), parameter :: i_strt              = 5; public :: i_strt !debug
  integer(i4b), parameter :: i_drn_elev          = 6
  integer(i4b), parameter :: i_drn_cond          = 7
  integer(i4b), parameter :: i_riv_stage         = 8
  integer(i4b), parameter :: i_riv_cond          = 9
  integer(i4b), parameter :: i_riv_rbot          = 10
  integer(i4b), parameter :: i_wel               = 11
  integer(i4b), parameter :: i_recharge          = 12
  integer(i4b), parameter :: i_part              = 13
  integer(i4b), parameter :: i_sol               = 14
  integer(i4b), parameter :: i_print_option      = 15
  integer(i4b), parameter :: i_complexity        = 16
  integer(i4b), parameter :: i_outer_hclose      = 17
  integer(i4b), parameter :: i_outer_maximum     = 18
  integer(i4b), parameter :: i_inner_maximum     = 19
  integer(i4b), parameter :: i_inner_hclose      = 20
  integer(i4b), parameter :: i_inner_rclose      = 21
  integer(i4b), parameter :: i_relaxation_factor = 22
  integer(i4b), parameter :: i_prim_sto          = 23
  integer(i4b), parameter :: i_ghb1_bhead        = 24
  integer(i4b), parameter :: i_ghb1_cond         = 25
  integer(i4b), parameter :: i_ghb2_bhead        = 26
  integer(i4b), parameter :: i_ghb2_cond         = 27
  integer(i4b), parameter :: i_ndrnsys           = 28
  integer(i4b), parameter :: i_nrivsys           = 29
  integer(i4b), parameter :: nkey                = i_nrivsys
  !  
  character(len=20), dimension(nkey) :: keys
            !12345678901234567890    12345678901234567890
  data keys/'top                 ', 'bot                 ', &
             'k                  ', 'k_33                ', &
             'strt               ', &
             'drn_elev           ', 'drn_cond            ', &
             'riv_stage          ', 'riv_cond            ', &
             'riv_rbot           ', 'wel_q               ', &
             'recharge           ', 'partitions          ', &
             'solutions          ', &
             'print_option       ', 'complexity          ', &
             'outer_hclose       ', 'outer_maximum       ', &
             'inner_maximum      ', 'inner_hclose        ', &
             'inner_rclose       ', 'relaxation_factor   ', &
             'prim_sto           ',                         &
             'ghb_bhead          ', 'ghb_cond            ', &
             'ghb2_bhead         ', 'ghb2_cond           ', &
             'ndrnsys            ', 'nrivsys              '/
  
  ! parameters
  integer(i4b),          parameter :: mxslen = 1024
  character(len=mxslen), parameter :: resultsbindir = '../../models/run_output_bin'
  character(len=mxslen), parameter :: resultslstdir = '../../models/run_output_lst'
  logical                          :: ltransient = .false.
  character(len=2)                 :: ctim = 'ss'
  !
  integer(i4b), parameter :: inam  =  1
  integer(i4b), parameter :: itdis =  2
  integer(i4b), parameter :: idisu =  3
  integer(i4b), parameter :: iic   =  4
  integer(i4b), parameter :: ioc   =  5
  integer(i4b), parameter :: inpf  =  6
  integer(i4b), parameter :: isto  =  7
  integer(i4b), parameter :: ichd1 =  8
  integer(i4b), parameter :: ichd2 =  9
  integer(i4b), parameter :: idrn  = 10
  integer(i4b), parameter :: iriv  = 11
  integer(i4b), parameter :: irch  = 12
  integer(i4b), parameter :: iwel  = 13
  integer(i4b), parameter :: ighb1 = 14
  integer(i4b), parameter :: ighb2 = 15
  integer(i4b), parameter :: npck = ighb2
  character(len=4), dimension(npck) :: pck
  data pck/'nam ', 'tdis', 'disu', 'ic  ', 'oc  ', 'npf ', 'sto ', 'chd ', 'chd ',&
           'drn ', 'riv ', 'rch ', 'wel ', 'ghb ', 'ghb '/
  
  integer(i4b), parameter :: maxrun = 6
  character(len=10), dimension(npck,maxrun) :: pr
  integer(i4b), parameter :: irun0ss = 1, irun1ss = 3, irun0tr = 4, irun1tr = 6
  !
    !------------------------------------------------------------------------------------------------------------
    ! ss/tr |run| nam      | tdis | disu | ic  | oc | npf| sto | chd1 | chd2 | drn | riv | rch | wel | ghb | ghb2|
    !------------------------------------------------------------------------------------------------------------
    ! ss    | 1 | chd_intf | #    | #    | #   | sm | #  | #   | #    | intf | #   | #   | #   | #   | #   | #   |
    ! ss    | 2 | ic_sm    | #    | #    | sm  | #  | #  | #   | #    | -    | #   | #   | #   | #   | #   | #   |
    ! ss    | 3 | ic_sh0   | #    | #    | #   | #  | #  | #   | #    | -    | #   | #   | #   | #   | #   | #   |
    ! tr    | 1 | spu      | spu  | #    | ss  | spu| #  | #   | #    | -    | spu | spu | spu | spu | spu | spu |
    ! tr    | 2 | ic_spu   | #    | #    | spu | #  | #  | #   | #    | -    | #   | #   | #   | #   | #   | #   |
    ! tr    | 3 | ic_ss    | #    | #    | ss  | #  | #  | #   | #    | -    | #   | #   | #   | #   | #   | #   |
  !
  !       inam         itdis        idisu        iic          ioc         inpf          isto         ichd1        ichd2        idrn         iriv         irch         iwel         ighb         ighb2        
  !       1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890   1234567890
  data pr/'.chd_intf ','          ','          ','          ','.sm       ','          ','          ','.sea      ','.intf     ','          ','          ','          ','          ','.1        ','.2        ', &
          '.ic_sm    ','          ','          ','.sm       ','          ','          ','          ','.sea      ','-         ','          ','          ','          ','          ','.1        ','.2        ', &
          '.ic_sh0   ','          ','          ','          ','          ','          ','          ','.sea      ','-         ','          ','          ','          ','          ','.1        ','.2        ', &
          '.spu      ','.spu      ','          ','.ss       ','.spu      ','          ','          ','.sea      ','-         ','.spu      ','.spu      ','.spu      ','.spu      ','.1.spu    ','.2.spu    ', &
          '.ic_spu   ','          ','          ','.spu      ','          ','          ','          ','.sea      ','-         ','          ','          ','          ','          ','.1        ','.2        ', &
          '.ic_ss    ','          ','          ','.ss       ','          ','          ','          ','.sea      ','-         ','          ','          ','          ','          ','.1        ','.2        '/
  !
  ! gfortran's deferred-length function results (character(len=:),
  ! allocatable) are not thread-safe: under OpenMP a result comes back empty
  ! or as another thread's. Code that threads run therefore calls no such
  ! function: integers are formatted here into results of automatic, exact
  ! length; the one real-valued string, the cell area, is formatted once
  ! before the threads start; utilsmod's ta stays for reals in the serial
  ! parts; the .inp integers are parsed by atoi.
  interface ta
    module procedure :: ta_i4_pure, ta_i8_pure, ta_i4_pad, ta_i8_pad, ta_r4_serial, ta_r8_serial
  end interface ta
  character(len=64) :: area_str

  ! netCDF turns HDF5's automatic error printing off for the thread that
  ! initialises it only; every other thread that writes a raster does it here
  interface
    function h5eset_auto2(estack, func, cdata) bind(C, name='H5Eset_auto2') result(err)
      import :: c_int64_t, c_int, c_ptr, c_funptr
      integer(c_int64_t), value :: estack
      type(c_funptr), value :: func
      type(c_ptr), value :: cdata
      integer(c_int) :: err
    end function h5eset_auto2
  end interface

  ! stencil
  integer(i4b), parameter :: jp = 1
  integer(i4b), parameter :: jt = 2
  integer(i4b), parameter :: jn = 3
  integer(i4b), parameter :: jw = 4
  integer(i4b), parameter :: je = 5
  integer(i4b), parameter :: js = 6
  integer(i4b), parameter :: jb = 7
  integer(i4b), parameter :: ns = jb
  
  private
  
  integer(I4B), parameter :: maxnraw = 1000
  
  ! A whole raster, one period, in the raster's own (windowed) indices: global
  ! index minus icoff/iroff. Nodata cells hold the file _FillValue.
  type tSlice
    real(r4b), dimension(:,:), pointer :: a => null()
    integer(i4b)                       :: iper = -1
  end type tSlice

  ! Two buffers so one stage can be gathered while the next is loaded; a
  ! raster without a time axis lives in buffer 1 with iper 0.
  type tData
    character(mxslen)       :: s = ''
    logical                 :: lraster = .false.
    type(raster_t)          :: r
    integer(i4b)            :: icoff = 0
    integer(i4b)            :: iroff = 0
    type(tSlice), dimension(2) :: buf
    real(r8b)               :: r8mult = DONE
    real(r8b)               :: r8add = DZERO
  end type tData
  
  type tRaw
    character(mxslen) :: key = ''
    type(tData), pointer :: dat => null()
    integer(I4B)      :: ilay_min = 0
    integer(I4B)      :: ilay_max = 0
    integer(I4B)      :: iper_min = 0
    integer(I4B)      :: iper_max = 0
    integer(I4B)      :: isys_min = 0
    integer(I4B)      :: isys_max = 0
  end type tRaw
  type tRawDat
    type(tRaw), dimension(maxnraw) :: raw
    integer(I4B)      :: nraw = 0
    integer(I4B)      :: nper = 0
    character(len=mxslen):: sdate = ''
    character(len=mxslen), dimension(:), allocatable :: perdate
  contains
    procedure :: init => mf6_raw_init
    procedure :: load => mf6_raw_load
    procedure :: free => mf6_raw_free
    procedure :: slice => mf6_raw_slice
    procedure :: mf6_raw_get_index
    procedure :: mf6_raw_key_exists
    procedure :: mf6_raw_get_name_char, mf6_raw_get_name_i4b
    generic   :: exists => mf6_raw_key_exists
    generic   :: getc  => mf6_raw_get_name_char
    generic   :: geti  => mf6_raw_get_name_i4b
  end type tRawDat
  type(tRawDat) :: raw
  !
  !
  integer(i4b) :: gncol      = 0
  integer(i4b) :: gnrow      = 0
  integer(i4b) :: gnlay      = 0
  real(r8b)    :: gxmin      = DZERO
  real(r8b)    :: gymin      = DZERO
  real(r8b)    :: gcs        = DZERO
  !
  real(r4b), dimension(:,:), pointer :: r4a => null()
  !
  ! work arrays
  character(len=mxslen), dimension(:),   pointer :: cwrk1d => null()
  character(len=mxslen), dimension(:,:), pointer :: cwrk2d => null()
  integer(i1b),          dimension(:),   pointer :: i1wrk   => null()
  integer(i1b),          dimension(:),   pointer :: i1wrk2  => null()
  integer(i4b),          dimension(:),   pointer :: i4wrk1d => null()
  integer(i4b),          dimension(:,:), pointer :: i4wrk2d => null()
  real(r8b),             dimension(:),   pointer :: r8wrk   => null()
  real(r8b),             dimension(:),   pointer :: r8wrk2  => null()
  real(r8b),             dimension(:),   pointer :: r8wrk3  => null()
  !$omp threadprivate(cwrk1d, cwrk2d, i1wrk, i1wrk2, i4wrk1d, i4wrk2d, r8wrk, r8wrk2, r8wrk3)
  
  type tDisu
    integer(i4b),               pointer :: nodes => null()
    integer(i4b),               pointer :: nja   => null()
    integer(i4b), dimension(:), pointer :: iac   => null() !length nodes
    integer(i4b), dimension(:), pointer :: ja    => null() !length nja
    integer(i4b), dimension(:), pointer :: ihc   => null() !length nja
    real(r8b),    dimension(:), pointer :: cl12  => null() !length nja
    real(r8b),    dimension(:), pointer :: hwva  => null() !length nja
  end type tDisu
  
  type tReg
    type(tBb),                      pointer :: bb          => null()
    integer(i4b), dimension(:),     pointer :: layer_nodes => null()
    integer(i4b), dimension(:,:,:), pointer :: nodmap      => null()
    integer(i4b), dimension(:,:,:), pointer :: bndmap      => null()
  end type tReg
  
  ! node -> global (col,row), node order
  type tNodTab
    integer(i4b) :: n = 0
    integer(i4b), dimension(:), allocatable :: node, gic, gir
  end type tNodTab

  ! one list package of one model across the periods
  type tListPck
    integer(i4b) :: nsys = 1
    integer(i4b) :: nx = 2
    integer(i4b) :: maxbound = 0
    logical,      dimension(:), allocatable :: lact
    integer(i8b), dimension(:), allocatable :: p0, p1
  end type tListPck

  type tExchange
    logical                               :: loutput = .true.
    type(tBb),                    pointer :: bb          => null()
    integer(i4b), dimension(:),   pointer :: m1reg       => null() !region ID M1
    integer(i4b), dimension(:),   pointer :: m2reg       => null() !region ID M1
    integer(i4b),                 pointer :: m1mod       => null() !local model index for solution
    integer(i4b),                 pointer :: m2mod       => null()
    character(len=mxslen),        pointer :: m2modelname => null()
    integer(i4b),                 pointer :: nexg        => null()
    integer(i4b), dimension(:),   pointer :: cellidm1    => null()
    integer(i4b), dimension(:),   pointer :: cellidm2    => null()
    integer(i4b), dimension(:,:), pointer :: gicirilm1   => null() !help
    integer(i4b), dimension(:,:), pointer :: gicirilm2   => null() !help
  end type tExchange
    
  type tMf6_mod
    integer(i4b)                           :: imod        = -1      !model ID
    integer(i4b),                  pointer :: isol        => null() !solution ID
    type(tBb),                     pointer :: bb          => null()
    character(len=mxslen),         pointer :: modelname   => null()
    character(len=mxslen),         pointer :: rootdir     => null()
    character(len=mxslen),         pointer :: bindir      => null()
    integer(i4b),                  pointer :: nreg        => null()
    type(tReg), dimension(:),      pointer :: reg         => null()
    type(tDisu),                   pointer :: disu        => null()
    integer(i4b),                  pointer :: nxch        => null()
    type(tExchange), dimension(:), pointer :: xch         => null()
    integer(i4b), dimension(:),    pointer :: layer_nodes => null()

    character(len=mxslen),         pointer :: fbin        => null()
    integer(i4b),                  pointer :: iubin       => null()
    integer(i4b), dimension(npck)          :: pckact      = 1
    type(tNodTab), dimension(:,:), allocatable :: tab     ! (selection, layer)
    type(tListPck), dimension(npck)        :: lp
  contains
    procedure :: get_model_name => mf6_mod_get_model_name
    procedure :: set_disu       => mf6_mod_set_disu
    procedure :: get_i_raw      => mf6_mod_get_i_raw
    procedure :: get_val        => mf6_mod_get_val_r8
    procedure :: get_array      => mf6_mod_get_array_r8
    generic   :: write_array    => mf6_mod_write_array_i4, &
                                   mf6_mod_write_array_r8
    procedure :: mf6_mod_write_array_i4
    procedure :: mf6_mod_write_array_r8
    procedure :: write_records => mf6_mod_write_records
    procedure :: build_tables  => mf6_mod_build_tables
    !
    procedure :: write_static      => mf6_mod_write_static
    procedure :: write_period_list => mf6_mod_write_period_list
    procedure :: write_finish      => mf6_mod_write_finish
    procedure :: write_nam   => mf6_mod_write_nam
    procedure :: write_disu  => mf6_mod_write_disu
    procedure :: write_ic    => mf6_mod_write_ic
    procedure :: write_oc    => mf6_mod_write_oc
    procedure :: write_npf   => mf6_mod_write_npf
    procedure :: write_sto   => mf6_mod_write_sto
    procedure :: write_chd   => mf6_mod_write_chd
    !
    procedure :: write_exchanges => mf6_mod_write_exchanges
    !
    procedure :: write_post_map  => mf6_mod_write_post_map
    !
    procedure :: clean_regions  => mf6_mod_clean_regions
    !
    procedure :: count_i1a => mf6_mod_count_i1a
  end type tMf6_mod
  
  type tMf6_sol
    integer(i4b)                          :: isol = -1
    character(len=mxslen),        pointer :: solname  => null()
    logical,                      pointer :: lmm      => null()
    integer(i4b),                 pointer :: nmod     => null() !number of models
    integer(i4b), dimension(:),   pointer :: mod_id   => null() !model ids
    integer(i4b),                 pointer :: npart    => null() !number of partitions
    integer(i4b), dimension(:),   pointer :: mod_part => null() !model partition numbers
  contains
    procedure :: write           => mf6_sol_write
    procedure :: write_tdis      => mf6_sol_write_tdis
    procedure :: write_ims       => mf6_sol_write_ims
    procedure :: write_wrap      => mf6_sol_write_wrap
    procedure :: write_mfsim     => mf6_sol_write_mfsim
    procedure :: write_post_map  => mf6_sol_write_post_map
    procedure :: clean           => mf6_sol_clean
  end type tMf6_sol
  
  ! public variables
  public :: tMf6_mod
  public :: tMf6_sol
  public :: tExchange
  public :: tReg
  public :: i1b, i4b, i8b, r4b, r8b
  public :: raw
  public :: mf6_write_models
  public :: gncol, gnrow, gnlay, gxmin, gymin, gcs
  
  save
  
  contains
  
! ==============================================================================
  
  subroutine mf6_raw_init(this, f_in)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tRawDat) :: this
    character(len=*), intent(inout) :: f_in
    ! -- local
    character(len=mxslen) :: s, units, cwd
    integer(I4B) :: iu, ios, nw, n, i, y, m ,d, ymd, iper, ty, tm, td
    real(R8B) :: jd, tval
    character(len=mxslen), dimension(:), allocatable :: words
    type(tData), pointer :: dat
! ------------------------------------------------------------------------------
    call logmsg('Reading '//trim(f_in)//'...')
    call open_file(f_in, iu)
    ios = 0
    n = 0
    do while (ios == 0)
      ios = readline(iu, s)
      !write(*,*) 'Reading ',trim(s)
      if (ios == 0) then
        words = getwords(s)
        nw = size(words)
        if (nw > 1) then
          n = n + 1; this%nraw = n
          this%raw(n)%key = change_case(words(1), 'l')
          call getminmax(words(1), '_', 'L', this%raw(n)%ilay_min, this%raw(n)%ilay_max)
          call getminmax(words(1), '_', 'P', this%raw(n)%iper_min, this%raw(n)%iper_max)
          call getminmax(words(1), '_', 'S', this%raw(n)%isys_min, this%raw(n)%isys_max)
          !
          ! set data
          allocate(this%raw(n)%dat)
          dat => this%raw(n)%dat
          dat%s = words(2)
          !
          ! a raster is a whole-domain NetCDF (design.md, "Forcing interface")
          s = change_case(words(2), 'l')
          i = len_trim(s)
          if ((i > 3).and.(s(i-2:i) == '.nc')) then
            dat%lraster = .true.
          end if
          if (nw > 2) then
            s = change_case(words(3), 'u')
            if (trim(s) == 'DIST') then
              call errmsg('per-tile DIST rasters are no longer supported: '//trim(words(2)))
            end if
          end if
          !
          if (nw > 3) then
            s = change_case(words(4), 'u')
            if (trim(s) == '*') then
              call logmsg('**** Multiplication factor found **** ')
              read(words(5),*) dat%r8mult
            end if
            if (trim(s) == '+') then
              call logmsg('**** Addition factor found **** ')
              read(words(5),*) dat%r8add
            end if
            if (nw > 5) then
              s = change_case(words(6), 'u')
              if (trim(s) == '*') then
                read(words(7),*) dat%r8mult
              end if
              if (trim(s) == '+') then
                read(words(7),*) dat%r8add
              end if
            end if
          end if
          !
          ! read header; the raster may be a window of the global grid
          if (dat%lraster) then
            call raster_open(dat%r, dat%s)
            ! the models are written after a chdir; the chunk reader reopens
            ! the file by name, so keep the absolute one
            if (dat%s(1:1) /= '/') then
              call get_work_dir(cwd)
              dat%r%fname = trim(cwd)//'/'//trim(dat%s)
            end if
            if (abs(dat%r%dx - gcs) > 1.d-9*gcs) then
              call errmsg('cell size of '//trim(dat%s)//' differs from the model grid')
            end if
            dat%icoff = nint((dat%r%xmin - gxmin)/gcs)
            dat%iroff = nint(((gymin + gnrow*gcs) - dat%r%ymax)/gcs)
          end if
        end if
      end if
    end do
    close(iu)
    !
    this%nper = this%geti('nper')
    if (this%nper > 1) then
      ltransient = .true.; ctim = 'tr'
    end if
    this%sdate = this%getc('startdate')
    allocate(this%perdate(this%nper))
    !
    read(this%sdate(1:4),*) y
    read(this%sdate(5:6),*) m
    read(this%sdate(7:8),*) d
    !
    jd = get_jd(y, m, d)
    do i = 1, this%nper
      call  get_ymd_from_jd(jd, ymd, y, m, d)
      write(this%perdate(i),'(i4,i2.2)') y, m
      call jd_next_month(jd)
    end do
    !
    ! a monthly raster must hold every period its key spans, in the right month
    do n = 1, this%nraw
      dat => this%raw(n)%dat
      if (.not.dat%lraster) cycle
      if (dat%r%nt == 0) cycle
      if (this%raw(n)%iper_max == 0) then
        call errmsg(trim(dat%s)//' has a time axis but key '//trim(this%raw(n)%key)// &
          ' names no period range')
      end if
      if (this%raw(n)%iper_max > dat%r%nt) then
        call errmsg(trim(dat%s)//' has '//ta((/dat%r%nt/))//' time steps, key '// &
          trim(this%raw(n)%key)//' needs '//ta((/this%raw(n)%iper_max/)))
      end if
      do iper = max(this%raw(n)%iper_min,1), min(this%raw(n)%iper_max, this%nper)
        call raster_time(dat%r, iper, tval, units)
        i = index(units, 'since')
        if ((i == 0).or.(change_case(units(1:4),'l') /= 'days')) then
          call errmsg('time units of '//trim(dat%s)//' are not "days since <date>": '//trim(units))
        end if
        read(units(i+5:),'(1x,i4,1x,i2,1x,i2)') ty, tm, td
        jd = get_jd(ty, tm, td) + tval
        call get_ymd_from_jd(jd, ymd, y, m, d)
        write(s,'(i4,i2.2)') y, m
        if (trim(s) /= trim(this%perdate(iper))) then
          call errmsg('time step '//ta((/iper/))//' of '//trim(dat%s)//' is '//trim(s)// &
            ', period '//ta((/iper/))//' is '//trim(this%perdate(iper)))
        end if
      end do
    end do
    !
    return
  end subroutine mf6_raw_init

  subroutine mf6_raw_load(this, i, iper, ibuf)
! ******************************************************************************
! Load the whole raster of entry i: period iper into buffer ibuf; a raster
! without a time axis once, into buffer 1.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tRawDat) :: this
    integer(i4b), intent(in) :: i, iper, ibuf
    ! -- local
    type(tData), pointer :: dat
    type(tSlice), pointer :: b
    logical :: lfast
    integer(i4b) :: k
    real(r8b) :: t0
! ------------------------------------------------------------------------------
    dat => this%raw(i)%dat
    if (.not.dat%lraster) call errmsg(trim(this%raw(i)%key)//' is not a raster')
    t0 = omp_get_wtime()
    if (dat%r%nt == 0) then
      b => dat%buf(1)
      if (b%iper == 0) return
      lfast = read_slice_chunks(dat%r%fname, 'data', 0, dat%r%nodata, b%a)
      if (.not.lfast) call raster_read_block(dat%r, 1, dat%r%nrow, 1, dat%r%ncol, b%a)
      b%iper = 0
    else
      b => dat%buf(ibuf)
      if (b%iper == iper) return
      lfast = read_slice_chunks(dat%r%fname, 'data', iper, dat%r%nodata, b%a)
      if (.not.lfast) call raster_read_block(dat%r, 1, dat%r%nrow, 1, dat%r%ncol, b%a, it=iper)
      b%iper = iper
    end if
    if (iper > 1) return
    k = index(dat%s, '/', back=.true.)
    if (lfast) then
      call logmsg('  read '//trim(dat%s(k+1:))//' period '//ta((/iper/))//' by chunks: '// &
        secs(omp_get_wtime()-t0))
    else
      call logmsg('  read '//trim(dat%s(k+1:))//' period '//ta((/iper/))// &
        ' through netCDF, not chunked shuffle+deflate float32 (later periods not reported): '// &
        secs(omp_get_wtime()-t0))
    end if
    !
    return
  end subroutine mf6_raw_load

  subroutine mf6_raw_free(this, i, ibuf)
! ******************************************************************************
    ! -- dummy
    class(tRawDat) :: this
    integer(i4b), intent(in) :: i, ibuf
    ! -- local
    type(tSlice), pointer :: b
! ------------------------------------------------------------------------------
    b => this%raw(i)%dat%buf(ibuf)
    if (associated(b%a)) deallocate(b%a)
    b%a => null(); b%iper = -1
    !
    return
  end subroutine mf6_raw_free

  function mf6_raw_slice(this, i, iper, ibuf) result(b)
! ******************************************************************************
! The loaded slice of entry i for period iper (buffer 1 for a static raster).
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tRawDat) :: this
    integer(i4b), intent(in) :: i, iper, ibuf
    type(tSlice), pointer :: b
    ! -- local
    type(tData), pointer :: dat
    integer(i4b) :: jper
! ------------------------------------------------------------------------------
    dat => this%raw(i)%dat
    if (dat%r%nt == 0) then
      b => dat%buf(1); jper = 0
    else
      b => dat%buf(ibuf); jper = iper
    end if
    if (b%iper /= jper) then
      call errmsg('program error: '//trim(dat%s)//' period '//ta((/jper/))//' is not loaded')
    end if
    !
    return
  end function mf6_raw_slice
  
  
  function mf6_raw_get_index(this, key, ilay, iper, isys) result(ind)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tRawDat) :: this
    character(len=*), intent(in) :: key
    integer(I4B), intent(in) :: ilay
    integer(I4B), intent(in) :: iper
    integer(I4B), intent(in) :: isys
    integer(I4B) :: ind
    ! -- local
    integer :: i, j, il_min, il_max, ip_min, ip_max, is_min, is_max
    character(len=mxslen) :: s, lckey
    logical :: lilay, liper, lisys
! ------------------------------------------------------------------------------
    !
    lckey = change_case(key, 'l')
    !
    ind = 0
    do i = 1, this%nraw
      s = this%raw(i)%key
      ! strip the _L, _P and _S range suffixes; reference cut at the first
      ! '_l'/'_p'/'_s' anywhere, which truncated 'ss_strt_dir' to 'ss' and
      ! matched 'k' inside 'k_33' by substring
      do while (strip_range_suffix(s))
      end do
      if (trim(s) == trim(lckey)) then
        il_min = this%raw(i)%ilay_min; il_max = this%raw(i)%ilay_max
        ip_min = this%raw(i)%iper_min; ip_max = this%raw(i)%iper_max
        is_min = this%raw(i)%isys_min; is_max = this%raw(i)%isys_max
        lilay = .false.; liper = .false.; lisys = .false.
        if ((il_min == 0).and.(il_max == 0)) then
          lilay = .true.
        else
          if ((il_min <= ilay).and.(ilay <= il_max)) then
            lilay = .true.
          end if
        end if
        if ((ip_min == 0).and.(ip_max == 0)) then
          liper = .true.
        else
          if ((ip_min <= iper).and.(iper <= ip_max)) then
            liper = .true.
          end if
        end if
        if ((is_min == 0).and.(is_max == 0)) then
          lisys = .true.
        else
          if ((is_min <= isys).and.(isys <= is_max)) then
            lisys = .true.
          end if
        end if
        !
        if (lilay.and.liper.and.lisys) then
          if (ind == 0) then
            ind = i
          else
            call errmsg('Error, '//trim(key)//' found twice')
          end if
          exit
        end if
      end if
    end do
    
    !if (ind == 0) then
    !  call errmsg('Program error mf6_get_index')
    !end if
    !
    return
  end function mf6_raw_get_index

  function strip_range_suffix(s) result(lstripped)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    character(len=*), intent(inout) :: s
    logical :: lstripped
    ! -- local
    integer(i4b) :: j, k
! ------------------------------------------------------------------------------
    lstripped = .false.
    j = index(s, '_', back=.true.)
    if (j == 0) return
    if (j == len_trim(s)) return
    if (scan(s(j+1:j+1), 'lps') == 0) return
    do k = j+2, len_trim(s)
      if (scan(s(k:k), '0123456789:') == 0) return
    end do
    if (j+2 > len_trim(s)) return
    s = s(1:j-1)
    lstripped = .true.
    !
    return
  end function strip_range_suffix

  function mf6_raw_key_exists(this, key, ilay, iper, isys) result(lex)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tRawDat) :: this
    character(len=*), intent(in) :: key
    integer(I4B), optional, intent(in) :: ilay
    integer(I4B), optional, intent(in) :: iper
    integer(I4B), optional, intent(in) :: isys
    logical :: lex
    ! -- local
    integer(I4B) :: i
    integer(I4B) :: jlay, jper, jsys
! ------------------------------------------------------------------------------
    jlay = 0
    jper = 0
    jsys = 0
    if (present(ilay)) jlay = ilay
    if (present(iper)) jper = iper
    if (present(isys)) jsys = isys
    !
    i = this%mf6_raw_get_index(key, jlay, jper, jsys)
    if (i > 0) then
      lex = .true.
    else
      lex = .false.
    endif
    !
    return
  end function mf6_raw_key_exists
  
  function mf6_raw_get_name_char(this, key, ilay, iper, isys, cdef) result(cval)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tRawDat) :: this
    character(len=*), intent(in) :: key
    integer(I4B), optional, intent(in) :: ilay
    integer(I4B), optional, intent(in) :: iper
    integer(I4B), optional, intent(in) :: isys
    character(len=*), optional, intent(in) :: cdef
    character(len=mxslen) :: cval   ! fixed: threads call this
    ! -- local
    integer(I4B) :: i
    integer(I4B) :: jlay, jper, jsys
! ------------------------------------------------------------------------------
    jlay = 0
    jper = 0
    jsys = 0
    if (present(ilay)) jlay = ilay
    if (present(iper)) jper = iper
    if (present(isys)) jsys = isys
    !
    if (.not.this%exists(key, jlay, jper, jsys)) then
      if (present(cdef)) then
        cval = trim(cdef)
        return
      else
        call errmsg('Error: key '//trim(key)// 'not found.')
      end if
    end if
    i = this%mf6_raw_get_index(key, jlay, jper, jsys)
    cval = trim(this%raw(i)%dat%s)
    !
    return
  end function mf6_raw_get_name_char
  
! ==============================================================================
  function mf6_raw_get_name_i4b(this, key, ilay, iper, idef) result(ival)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tRawDat) :: this
    character(len=*), intent(in) :: key
    integer(I4B), optional, intent(in) :: ilay
    integer(I4B), optional, intent(in) :: iper
    integer(I4B) :: ival
    integer(I4B), optional, intent(in) :: idef
    ! -- local
    character(len=mxslen) :: s
    integer(I4B) :: ios
    integer(I4B) :: jlay, jper
! ------------------------------------------------------------------------------
    jlay = 0
    jper = 0
    if (present(ilay)) jlay = ilay
    if (present(iper)) jper = iper
    
    if (.not.this%exists(key, jlay, jper)) then
      if (present(idef)) then
        ival = idef
        return
      else
        call errmsg('Error: key '//trim(key)// 'not found.')
      end if
    end if
    s = this%mf6_raw_get_name_char(key, ilay, iper)
    ival = atoi(s)
    !
    return
  end function mf6_raw_get_name_i4b

! ==============================================================================


  
  pure function ndig(i) result(n)
    ! characters of i in decimal, sign included
    integer(i8b), intent(in) :: i
    integer(i4b) :: n
    integer(i8b) :: v
    n = 1; v = abs(i)
    do while (v >= 10)
      v = v/10; n = n + 1
    end do
    if (i < 0) n = n + 1
  end function ndig

  pure function ta_len(arr, m) result(n)
    ! length of ta(arr, m): the numbers zero-padded to m digits, one blank between
    integer(i8b), dimension(:), intent(in) :: arr
    integer(i4b), intent(in) :: m
    integer(i4b) :: n, k
    n = size(arr) - 1
    do k = 1, size(arr)
      n = n + max(ndig(arr(k)), m + merge(1, 0, arr(k) < 0))
    end do
  end function ta_len

  function ta_i8_pad(arr, m) result(s)
    ! the integers of arr, zero-padded to m digits (0: as they are), blank-separated
    integer(i8b), dimension(:), intent(in) :: arr
    integer(i4b), intent(in) :: m
    character(len=ta_len(arr, m)) :: s
    character(len=24) :: w
    integer(i8b) :: v
    integer(i4b) :: k, p, q, nd
    q = 0
    do k = 1, size(arr)
      v = abs(arr(k)); p = 24
      do
        w(p:p) = achar(48 + int(mod(v, 10_i8b))); v = v/10; p = p - 1
        if (v == 0) exit
      end do
      nd = 24 - p
      do while (nd < m)
        w(p:p) = '0'; p = p - 1; nd = nd + 1
      end do
      if (arr(k) < 0) then
        w(p:p) = '-'; p = p - 1; nd = nd + 1
      end if
      if (k > 1) then
        q = q + 1; s(q:q) = ' '
      end if
      s(q+1:q+nd) = w(p+1:24); q = q + nd
    end do
  end function ta_i8_pad

  function ta_i8_pure(arr) result(s)
    integer(i8b), dimension(:), intent(in) :: arr
    character(len=ta_len(arr, 0)) :: s
    s = ta_i8_pad(arr, 0)
  end function ta_i8_pure

  function ta_i4_pad(arr, m) result(s)
    integer(i4b), dimension(:), intent(in) :: arr
    integer(i4b), intent(in) :: m
    character(len=ta_len(int(arr, i8b), m)) :: s
    s = ta_i8_pad(int(arr, i8b), m)
  end function ta_i4_pad

  function ta_i4_pure(arr) result(s)
    integer(i4b), dimension(:), intent(in) :: arr
    character(len=ta_len(int(arr, i8b), 0)) :: s
    s = ta_i8_pad(int(arr, i8b), 0)
  end function ta_i4_pure

  function atoi(s) result(i)
    character(len=*), intent(in) :: s
    integer(i4b) :: i
    integer(i4b) :: k, sgn
    logical :: ldig
    i = 0; sgn = 1; ldig = .false.
    do k = 1, len_trim(s)
      select case (s(k:k))
      case (' ')
        if (ldig) exit
      case ('-')
        sgn = -1
      case ('+')
      case ('0':'9')
        i = 10*i + (iachar(s(k:k)) - 48); ldig = .true.
      case default
        call errmsg('not an integer: '//trim(s))
      end select
    end do
    if (.not.ldig) call errmsg('not an integer: '//trim(s))
    i = sgn*i
  end function atoi

  function ta_r4_serial(arr, fmt_in) result(s)
    real(r4b), dimension(:), intent(in) :: arr
    character(len=*), intent(in), optional :: fmt_in
    character(len=:), allocatable :: s
    s = ta_u(arr, fmt_in)
  end function ta_r4_serial

  function ta_r8_serial(arr, fmt_in) result(s)
    real(r8b), dimension(:), intent(in) :: arr
    character(len=*), intent(in), optional :: fmt_in
    character(len=:), allocatable :: s
    s = ta_u(arr, fmt_in)
  end function ta_r8_serial

  function secs(t) result(s)
    ! elapsed seconds with three decimals, for the log lines threads write
    real(r8b), intent(in) :: t
    character(len=ndig(nint(1000*t, i8b)/1000)+6) :: s
    integer(i8b) :: ms
    ms = nint(1000*t, i8b)
    s = ta_i8_pad((/ms/1000/), 0)//'.'//ta_i8_pad((/mod(ms,1000_i8b)/), 3)//' s'
  end function secs

  subroutine wline(iu, s)
! ******************************************************************************
! One line of a text file opened by open_file: the bytes of a formatted
! '(a)' record. Text files are written as byte streams, one write per line.
! ------------------------------------------------------------------------------
    integer(i4b), intent(in) :: iu
    character(len=*), intent(in) :: s
! ------------------------------------------------------------------------------
    write(iu) s//new_line('a')
    !
    return
  end subroutine wline

  subroutine logmsg(msg)
! ******************************************************************************
! utilsmod's logmsg, one thread at a time, so log lines do not interleave.
! ------------------------------------------------------------------------------
    character(len=*), intent(in) :: msg
! ------------------------------------------------------------------------------
    !$omp critical(logio)
    call logmsg_u(msg)
    !$omp end critical(logio)
    !
    return
  end subroutine logmsg

  subroutine open_file(f, iu, act_in, lbin_in, unit_in)
! ******************************************************************************
! utilsmod's open_file scans for a free unit, which threads cannot share.
! Units are fixed instead: unit_in for a file that stays open (the model
! binary, 10000 + model id), else one text and one binary unit per thread;
! a routine opens one file of each kind at a time. Text files are opened
! as byte streams for wline. Same log lines.
! ------------------------------------------------------------------------------
    character(len=*), intent(inout) :: f
    integer(i4b), intent(inout) :: iu
    character(len=1), optional :: act_in
    logical, intent(in), optional :: lbin_in
    integer(i4b), intent(in), optional :: unit_in
    ! -- local
    character(len=1) :: act
    logical :: lbin, lex
! ------------------------------------------------------------------------------
    act = 'r'
    if (present(act_in)) act = change_case(act_in, 'l')
    lbin = .false.
    if (present(lbin_in)) lbin = lbin_in
    if (present(unit_in)) then
      iu = unit_in
    else if (lbin) then
      iu = 30000 + omp_get_thread_num()
    else
      iu = 20000 + omp_get_thread_num()
    end if
    inquire(unit=iu, opened=lex)
    if (lex) call errmsg('program error: unit '//ta((/iu/))//' is still open, cannot open '//trim(f))
    if (act == 'r') then
      inquire(file=f, exist=lex)
      if (.not.lex) call errmsg('File '//trim(f)//' does not exist.')
    end if
    if ((act == 'r').and.(.not.lbin)) then
      call logmsg('Reading ascii file '//trim(f)//'...')
      open(unit=iu, file=f, form='formatted', access='sequential', action='read', status='old')
    else if ((act == 'w').and.(.not.lbin)) then
      call logmsg('Writing ascii file '//trim(f)//'...')
      open(unit=iu, file=f, form='unformatted', access='stream', action='write', status='replace')
    else if ((act == 'r').and.(lbin)) then
      call logmsg('Reading binary file '//trim(f)//'...')
      open(unit=iu, file=f, form='unformatted', access='stream', action='readwrite', status='old')
    else if ((act == 'w').and.(lbin)) then
      call logmsg('Writing binary file '//trim(f)//'...')
      open(unit=iu, file=f, form='unformatted', access='stream', action='write', status='replace')
    else
      call errmsg('open_file called with invalid option')
    end if
    !
    return
  end subroutine open_file

  subroutine clear_wrk()
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
! ------------------------------------------------------------------------------
    if (associated(cwrk1d)) then
      deallocate(cwrk1d)
      cwrk1d => null()
    end if
    if (associated(cwrk2d)) then
      deallocate(cwrk2d)
      cwrk2d => null()
    end if
    if (associated(i1wrk)) then
      deallocate(i1wrk)
      i1wrk => null()
    end if
    if (associated(i1wrk2)) then
      deallocate(i1wrk2)
      i1wrk2 => null()
    end if
    if (associated(i4wrk1d)) then
      deallocate(i4wrk1d)
      i4wrk1d => null()
    end if
    if (associated(i4wrk2d)) then
      deallocate(i4wrk2d)
      i4wrk2d => null()
    end if
    if (associated(r8wrk)) then
      deallocate(r8wrk)
      r8wrk => null()
    end if
    if (associated(r8wrk2)) then
      deallocate(r8wrk2)
      r8wrk2 => null()
    end if
    if (associated(r8wrk3)) then
      deallocate(r8wrk3)
      r8wrk3 => null()
    end if
    !
    return
  end subroutine clear_wrk

  subroutine write_block_begin(iu, name)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: iu
    character(len=*), intent(in) :: name
! ------------------------------------------------------------------------------
    call wline(iu, 'BEGIN '//trim(name))
    !
    return
  end subroutine write_block_begin

  subroutine write_block_end(iu, name)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: iu
    character(len=*), intent(in) :: name
! ------------------------------------------------------------------------------
    call wline(iu, 'END '//trim(name))
    !
    return
  end subroutine write_block_end

  subroutine mf6_sol_write(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
! ------------------------------------------------------------------------------
    call this%write_wrap()
    call this%write_tdis()
    call this%write_ims()
    call this%write_mfsim()
    call this%write_post_map()
    !
    return
  end subroutine mf6_sol_write
!    
  subroutine mf6_sol_clean(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
! ------------------------------------------------------------------------------
    !
    if (associated(this%solname))  deallocate(this%solname)
    if (associated(this%lmm))      deallocate(this%lmm)
    if (associated(this%nmod))     deallocate(this%nmod)
    if (associated(this%mod_id))   deallocate(this%mod_id)
    if (associated(this%npart))    deallocate(this%npart)
    if (associated(this%mod_part)) deallocate(this%mod_part)
    !
    this%solname  => null()
    this%lmm      => null()
    this%nmod     => null()
    this%mod_id   => null()
    this%npart    => null()
    this%mod_part => null()
    !
    return
  end subroutine mf6_sol_clean
  !
  subroutine mf6_sol_write_wrap(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
    integer(i4b), parameter :: iser = 1
    integer(i4b), parameter :: ipar = 2
    logical, dimension(2) :: lcpu
    character(len=4), dimension(2) :: pcpu
    data pcpu/'.ser','.par'/
    !
    character(len=mxslen) :: f, ms, s
    integer(i4b) :: iu, i, icpu, irun, irun0, irun1
! ------------------------------------------------------------------------------
    !
    if (ltransient) then
      irun0 = irun0tr
      irun1 = irun1tr
    else
      irun0 = irun0ss
      irun1 = irun1ss
    end if
    !
    lcpu = .true.
    if (this%nmod == 1) then
      lcpu(ipar) = .false.
    end if
    !
    ! models.asc
    do icpu = 1, 2
      if (.not.lcpu(icpu)) cycle
      do irun = irun0, irun1
        f = trim(this%solname)//pcpu(icpu)//'.models'//trim(pr(inam,irun))//'.asc'
        call open_file(f, iu, 'w')
        do i = 1, this%nmod
          ms =  'm'//ta((/this%mod_id(i)/), 5)
          s = 'GWF6 ../../models/run_input/'//trim(ms)// &
            '/'//trim(ms)//trim(pr(inam,irun))//'.nam '//trim(ms)
          if (icpu == ipar) then
            call wline(iu, trim(s)//' '//ta((/this%mod_part(i)/)))
          else
            call wline(iu, trim(s))
          end if
        end do
        close(iu)
      end do
    end do
    !
    ! solmodels.asc
    f = trim(this%solname)//'.solmodels.asc'
    call open_file(f, iu, 'w')
    do i = 1, this%nmod
      ms = 'm'//ta((/this%mod_id(i)/), 5); call wline(iu, trim(ms))
    end do
    close(iu)
    !
    ! cgc.solmodels.asc
    f = trim(this%solname)//'.cgc.solmodels.asc'
    call open_file(f, iu, 'w')
    do i = 1, this%nmod
      ms = 'm'//ta((/this%mod_id(i)/), 5)
      call wline(iu, trim(ms)//' '//ta((/i/)))
    end do
    close(iu)
    !
    ! solmodels.asc.wrp
    f = trim(this%solname)//'.solmodels.wrp.asc'
    call open_file(f, iu, 'w')
    call write_block_begin(iu, 'MODELS')
    s = '../run_input/'//trim(this%solname)//'.solmodels.asc'
    call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(s))
    call write_block_end(iu, 'MODELS')
    close(iu)
    !
    ! cgc.solmodels.asc.wrp
    f = trim(this%solname)//'.cgc.solmodels.wrp.asc'
    call open_file(f, iu, 'w')
    call write_block_begin(iu, 'MODELS')
    s = '../run_input/'//trim(this%solname)//'.cgc.solmodels.asc'
    call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(s))
    call write_block_end(iu, 'MODELS')
    close(iu)
    !
    return
  end subroutine mf6_sol_write_wrap
  
  subroutine mf6_sol_write_mfsim(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
    integer(i4b), parameter :: iser = 1
    integer(i4b), parameter :: ipar = 2
    logical, dimension(2) :: lcpu
    character(len=4), dimension(2) :: pcpu
    data pcpu/'.ser','.par'/
    !
    character(len=mxslen) :: d, nam, ms, s
    integer(i4b) :: iu, i, icpu, irun, irun0, irun1
! ------------------------------------------------------------------------------
    !
    d = '../run_input/'
    !
    lcpu = .true.
    if (this%nmod == 1) then
      lcpu(ipar) = .false.
    end if
    !
    if (ltransient) then
      irun0 = irun0tr
      irun1 = irun1tr
    else
      irun0 = irun0ss+1
      irun1 = irun1ss
      if (.not.this%lmm) irun0 = 3
    end if
    !
    if (.not.ltransient .and.this%lmm) then
      do i = 1, this%nmod
        ms =  'm'//ta((/this%mod_id(i)/), 5)
        nam = trim(this%solname)//pcpu(iser)//'.mfsim.'//trim(ms)//trim(pr(inam,irun0ss))//'.nam'
        call open_file(nam, iu, 'w')
        call write_block_begin(iu, 'OPTIONS')
        call wline(iu, repeat(' ',2)//'MEMORY_PRINT_OPTION SUMMARY')
        call write_block_end(iu, 'OPTIONS')
        call wline(iu, '')
        call write_block_begin(iu, 'TIMING')
        call wline(iu, repeat(' ',2)//'TDIS6 '//trim(d)//trim(this%solname)//trim(pr(itdis,irun0ss))//'.tdis')
        call write_block_end(iu, 'TIMING')
        call wline(iu, '')
        call write_block_begin(iu, 'MODELS')
        s = 'GWF6 ../../models/run_input/'//trim(ms)// &
          '/'//trim(ms)//trim(pr(inam,irun0ss))//'.nam '//trim(ms)
        call wline(iu, repeat(' ',2)//trim(s))
        call write_block_end(iu, 'MODELS')
        call wline(iu, '')
        call write_block_begin(iu, 'EXCHANGES')
        call write_block_end(iu, 'EXCHANGES')
        call wline(iu, '')
        call write_block_begin(iu, 'SOLUTIONGROUP 1')
        call wline(iu, repeat(' ',2)//'IMS6 '//trim(d)//trim(this%solname)//'.ims '//trim(ms))
        call write_block_end(iu, 'SOLUTIONGROUP')
        close(iu)
      end do
    end if
    !
    ! if parallel: also write the serial mfsim.nam
    do icpu = 1, 2
      if (.not.lcpu(icpu)) cycle
      do irun = irun0, irun1
        nam = trim(this%solname)//pcpu(icpu)//'.mfsim'//trim(pr(inam,irun))//'.nam'
        call open_file(nam, iu, 'w')
        call write_block_begin(iu, 'OPTIONS')
        call wline(iu, repeat(' ',2)//'MEMORY_PRINT_OPTION SUMMARY')
        if (icpu == ipar) call wline(iu, '  DOMAIN_DECOMPOSITION '//ta((/this%npart/)))
        call write_block_end(iu, 'OPTIONS')
        call wline(iu, '')
        call write_block_begin(iu, 'TIMING')
        call wline(iu, repeat(' ',2)//'TDIS6 '//trim(d)//trim(this%solname)//trim(pr(itdis,irun))//'.tdis')
        call write_block_end(iu, 'TIMING')
        call wline(iu, '')
        call write_block_begin(iu, 'MODELS')
        call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(d)//trim(this%solname)//pcpu(icpu)//'.models'//trim(pr(inam,irun))//'.asc')
        call write_block_end(iu, 'MODELS')
        call wline(iu, '')
        call write_block_begin(iu, 'EXCHANGES')
        if (this%lmm) then
          call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(d)//trim(this%solname)//'.exchanges.asc')
        end if
        call write_block_end(iu, 'EXCHANGES')
        call wline(iu, '')
        call write_block_begin(iu, 'SOLUTIONGROUP 1')
        if (this%lmm) then
          call wline(iu, '  # IMS6_CGC '//trim(d)//trim(this%solname)//'.ims FILEIN '//trim(d)// &
            trim(this%solname)//'.cgc.solmodels.wrp.asc')
          call wline(iu, '  IMS6 '//trim(d)//trim(this%solname)//'.ims FILEIN '//trim(d)// &
            trim(this%solname)//'.solmodels.wrp.asc')
        else
          call wline(iu, '  IMS6 '//trim(d)//trim(this%solname)//'.ims FILEIN '//trim(d)// &
            trim(this%solname)//'.solmodels.wrp.asc')
        end if
        call write_block_end(iu, 'SOLUTIONGROUP')
        close(iu)
      end do
    end do
    !
    return
  end subroutine mf6_sol_write_mfsim

  subroutine mf6_sol_write_post_map(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this 
    ! -- local
    character(len=mxslen) :: d, f
    integer(i4b) :: i, iu
! ------------------------------------------------------------------------------
    !
    d = '../post_mappings/'; call create_dir(d, .true.)
    f = trim(d)//trim(this%solname)//'.modmap.bin'
    !
    call open_file(f, iu, 'w', .true.)
    write(iu) this%nmod
    write(iu)(this%mod_id(i),i=1, this%nmod)
    close(iu)
    !
    return
  end subroutine mf6_sol_write_post_map  
! 
  subroutine mf6_sol_write_tdis(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
    character(len=mxslen) :: f
    integer(i4b) :: iu, iper, jper, nstp_fac, nd, nperspu
! ------------------------------------------------------------------------------
    !
    if (.not.ltransient) then !SS
      f = trim(this%solname)//'.tdis'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call wline(iu, repeat(' ',2)//'TIME_UNITS '//trim(raw%getc('time_units',cdef='DAYS')))
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'NPER 1')
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'PERIODDATA')
      call wline(iu, repeat(' ',2)//'1 1 1')
      call write_block_end(iu, 'PERIODDATA')
      close(iu)
    !
    else !TR
      nstp_fac = raw%geti('nstp_fac',idef=1)
      !
      nperspu = raw%geti('nmonth_spinup')
      f = trim(this%solname)//trim(pr(itdis,irun0tr))//'.tdis'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call wline(iu, repeat(' ',2)//'TIME_UNITS '//trim(raw%getc('time_units',cdef='DAYS')))
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'NPER '//ta((/nperspu/)))
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'PERIODDATA')
      do iper = 1, nperspu
        !jper = mod(iper,nperspu)
        !if (jper == 0) jper = nperspu
        jper = mod(iper,12)
        if (jper == 0) jper = 1
        nd = get_month_days_s(raw%perdate(jper))
        call wline(iu, repeat(' ',2)//ta((/nd/))//' '//ta((/nd*nstp_fac/))//' 1')
      end do
      call write_block_end(iu, 'PERIODDATA')
      close(iu)
      !
      f = trim(this%solname)//'.tdis'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call wline(iu, repeat(' ',2)//'TIME_UNITS '//trim(raw%getc('time_units',cdef='DAYS')))
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'NPER '//ta((/raw%nper/)))
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'PERIODDATA')
      do iper = 1, raw%nper
        nd = get_month_days_s(raw%perdate(iper))
        call wline(iu, repeat(' ',2)//ta((/nd/))//' '//ta((/nd*nstp_fac/))//' 1')
      end do
      call write_block_end(iu, 'PERIODDATA')
      close(iu)
    end if
    !
    return
  end subroutine mf6_sol_write_tdis
  !
  subroutine mf6_sol_write_ims(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_sol) :: this
    ! -- local
    character(len=mxslen) :: f
    integer(i4b) :: iu
    logical :: lcomplex
    !
    integer(i4b), parameter :: nnlvar = 11
    integer(i4b), parameter :: nlvar  = 10
    !
    type tCompl
      character(len=mxslen) :: name = ''
      character(mxslen), dimension(2,nnlvar) :: nlvar
      character(mxslen), dimension(2,nlvar)  :: lvar
    end type tCompl
    !
    type(tCompl), pointer :: c
    type(tCompl), dimension(:), pointer :: compl
    integer(i4b) :: ncompl, i, j
    character(mxslen) :: cname, rclose_option
! ------------------------------------------------------------------------------
    !
    ! define the complexities
    ncompl = 3
    allocate(compl(ncompl))
    !
    ! SIMPLE
    i = 1; c => compl(i); c%name = 'SIMPLE'
    j =     1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_HCLOSE', '0.001']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_MAXIMUM ', '25']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION ', 'NONE']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_THETA ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_KAPPA ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_GAMMA ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_MOMENTUM ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_NUMBER ', '0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_TOLERANCE ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_REDUCTION_FACTOR ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_RESIDUAL_LIMIT ', '0.0']
    !
    j =     1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_MAXIMUM', '50']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_HCLOSE', '0.001']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_RCLOSE', '0.1']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'LINEAR_ACCELERATION', 'CG']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'RELAXATION_FACTOR', '0.0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_LEVELS', '0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_DROP_TOLERANCE', '0.0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'NUMBER_ORTHOGONALIZATIONS', '0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'SCALING_METHOD', 'NONE']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'REORDERING_METHOD', 'NONE']
    !
    ! MODERATE
    i = 2; c => compl(i); c%name = 'MODERATE'
    j =     1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_HCLOSE', '0.01']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_MAXIMUM ', '50']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION ', 'DBD']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_THETA ', '0.9']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_KAPPA ', '0.0001']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_GAMMA ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_MOMENTUM ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_NUMBER ', '0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_TOLERANCE ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_REDUCTION_FACTOR ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_RESIDUAL_LIMIT ', '0.0']
    !
    j =     1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_MAXIMUM', '100']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_HCLOSE', '0.01']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_RCLOSE', '0.1']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'LINEAR_ACCELERATION', 'BICGSTAB']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'RELAXATION_FACTOR', '0.97']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_LEVELS', '0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_DROP_TOLERANCE', '0.0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'NUMBER_ORTHOGONALIZATIONS', '0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'SCALING_METHOD', 'NONE']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'REORDERING_METHOD', 'NONE']
    !
    ! COMPLEX
    i = 3; c => compl(i); c%name = 'COMPLEX'
    j =     1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_HCLOSE', '0.1']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'OUTER_MAXIMUM ', '100']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION ', 'DBD']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_THETA ', '0.8']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_KAPPA ', '0.0001']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_GAMMA ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'UNDER_RELAXATION_MOMENTUM ', '0.0']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_NUMBER ', '20']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_TOLERANCE ', '1.05']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_REDUCTION_FACTOR ', '0.1']
    j = j + 1; c%nlvar(:,j) = [character(len=mxslen) :: 'BACKTRACKING_RESIDUAL_LIMIT ', '0.002']
    !
    j =     1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_MAXIMUM', '500']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_HCLOSE', '0.1']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'INNER_RCLOSE', '0.1']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'LINEAR_ACCELERATION', 'BICGSTAB']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'RELAXATION_FACTOR', '0.0']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_LEVELS', '5']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'PRECONDITIONER_DROP_TOLERANCE', '0.0001']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'NUMBER_ORTHOGONALIZATIONS', '2']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'SCALING_METHOD', 'NONE']
    j = j + 1; c%lvar(:,j) = [character(len=mxslen) :: 'REORDERING_METHOD', 'NONE']
    !
    cname = raw%getc('complexity',cdef='SIMPLE')
    select case (cname)
    case('SIMPLE')
      c => compl(1)
    case('MODERATE')
      c => compl(2)
    case('COMPLEX')
      c => compl(3)
    case default
      call errmsg("Invalid complexity: "//trim(cname))
    end select
    !
    ! overwrite the defaults
    do j = 1, nnlvar
      c%nlvar(2,j) = raw%getc(trim(c%nlvar(1,j)),cdef=trim(c%nlvar(2,j)))
    end do
    do j = 1, nlvar
      c%lvar(2,j) = raw%getc(trim(c%lvar(1,j)),cdef=trim(c%lvar(2,j)))
    end do
    rclose_option = raw%getc('rclose_option',cdef='')
    if (len_trim(rclose_option) > 0) then
      c%lvar(2,3) = trim(c%lvar(2,3))//' '//trim(rclose_option)
    end if
    !
    f = trim(this%solname)//'.ims'
    call open_file(f, iu, 'w')
    !
    call write_block_begin(iu, 'OPTIONS')
    call wline(iu, repeat(' ',2)//'PRINT_OPTION '//trim(raw%getc('print_option',cdef='ALLITER')))
    call write_block_end(iu, 'OPTIONS')
    call wline(iu, '')
    call write_block_begin(iu, 'NONLINEAR')
    do j = 1, nnlvar
      call wline(iu, repeat(' ',2)//trim(c%nlvar(1,j))//' '//trim(trim(c%nlvar(2,j))))
    end do
    call write_block_end(iu, 'NONLINEAR')
    call wline(iu, '')
    call write_block_begin(iu, 'LINEAR')
    do j = 1, nlvar
      call wline(iu, repeat(' ',2)//trim(c%lvar(1,j))//' '//trim(trim(c%lvar(2,j))))
    end do
    call write_block_end(iu, 'LINEAR')
    close(iu)
    !
    deallocate(compl)
    !
    return
  end subroutine mf6_sol_write_ims

! ==============================================================================
! ==============================================================================
! ==============================================================================
! ==============================================================================
! ==============================================================================
  
  function mf6_mod_get_i_raw(this, i_dat, ilay_dat, iper_dat, isys_dat) &
    result(i_raw)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: i_dat
    integer(i4b), intent(in) :: ilay_dat
    integer(i4b), intent(in) :: iper_dat
    integer(i4b), intent(in) :: isys_dat
    integer(i4b) :: i_raw
    ! -- local
! ------------------------------------------------------------------------------
    i_raw = raw%mf6_raw_get_index(keys(i_dat), ilay_dat, iper_dat, isys_dat)
    if (i_raw <= 0) then
      call errmsg('mf6_mod_get_array_r8: program error 1')
    end if
    !
    return
  end function mf6_mod_get_i_raw
  !
  function mf6_mod_get_val_r8(this, i_raw, ireg, ic, ir) result(r8val)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: i_raw
    integer(i4b), intent(in) :: ireg
    integer(i4b), intent(in) :: ic
    integer(i4b), intent(in) :: ir
    real(r8b) :: r8val
    ! -- local
    type(tReg), pointer :: reg
    type(tData), pointer :: dat
    type(tSlice), pointer :: b
    integer(i4b) :: gir, gic, jc, jr
    real(r4b) :: r4val
! ------------------------------------------------------------------------------
    dat => raw%raw(i_raw)%dat
    b => raw%slice(i_raw, 0, 1)
    reg => this%reg(ireg)
    !
    gir = ir + reg%bb%ir0 - 1; gic = ic + reg%bb%ic0 - 1
    jc = gic - dat%icoff; jr = gir - dat%iroff
    if ((jc < 1).or.(jc > size(b%a,1)).or.(jr < 1).or.(jr > size(b%a,2))) then
      call errmsg('cell (col,row) = ('//ta((/gic, gir/))//') outside '//trim(dat%s))
    end if
    r4val = b%a(jc,jr)
    if (r4val == real(dat%r%nodata,r4b)) then
      call errmsg('nodata in '//trim(dat%s)//' at active cell (col,row) = ('// &
        ta((/gic, gir/))//')')
    end if
    r8val = real(r4val,r8b)
    !
    r8val = r8val *dat%r8mult + dat%r8add

    return
  end function mf6_mod_get_val_r8

  subroutine mf6_mod_get_array_r8(this, i_dat, ilay_dat, ilay_tgt, arrflg, arr, ib_in)
! ******************************************************************************
! Static fields only: the model's nodes of layer ilay_tgt from the loaded
! whole-raster slice. ib 0: all cells, 1: sea only, 2: all but sea,
! 3: internal M1 interface cells. Nodata drops the node.
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: i_dat
    integer(i4b), intent(in) :: ilay_dat
    integer(i4b), intent(in) :: ilay_tgt
    integer(i1b), dimension(:), pointer, intent(inout) :: arrflg
    real(r8b), dimension(:), pointer, intent(inout) :: arr
    integer(i4b), intent(in), optional :: ib_in
    ! -- local
    type(tReg), pointer :: reg
    type(tData), pointer :: dat
    type(tSlice), pointer :: b
    integer(i4b) :: n, i, ireg, ir, ic, jr, jc, gic, gir, ib
    integer(i4b) :: nodes, nact, ndrop
    real(r4b) :: r4val, r4nodata
! ------------------------------------------------------------------------------
    nact = 0; ndrop = 0
    !
    if (present(ib_in)) then
      ib = ib_in
    else
      ib = 0
    end if
    !
    i = raw%mf6_raw_get_index(keys(i_dat), ilay_dat, 0, 0)
    if (i <= 0) then
      call errmsg('mf6_mod_get_array_r8: program error 1')
    end if
    dat => raw%raw(i)%dat
    b => raw%slice(i, 0, 1)
    !
    nodes = sum(this%layer_nodes)
    if (.not.associated(arr)) then
      allocate(arr(nodes))
      do i = 1, size(arr)
        arr(i) = DZERO
      end do
    end if
    if (.not.associated(arrflg)) then
      allocate(arrflg(nodes))
      do i = 1, size(arrflg)
        arrflg(i) = 0
      end do
    end if
    !
    if (size(arrflg) /= size(arr)) then
      call errmsg('mf6_mod_get_array_r8: program error 1')
    end if
    !
    r4nodata = real(dat%r%nodata,r4b)
    !
    do ireg = 1, this%nreg
      reg => this%reg(ireg)
      do ir = 1, reg%bb%nrow
        do ic = 1, reg%bb%ncol
          select case(ib)
            case(0) ! all cells including sea cells
              n = abs(reg%nodmap(ic,ir,ilay_tgt))
            case(1) ! sea cells only
              n = reg%nodmap(ic,ir,ilay_tgt)
              if (n < 0) then
                n = abs(n)
              else
                n = 0
              end if
            case(2) ! all cells excluding sea cells
              n = reg%nodmap(ic,ir,ilay_tgt)
              if (n < 0) then
                n = 0
              end if
            case(3) ! internal M1 interface cells only (skip sea)
              n = reg%bndmap(ic,ir,ilay_tgt)
              if (n < 0) then
                n = 0
              end if
            case default
              call errmsg('mf6_mod_get_array_r8: program error 1')
          end select
          !
          if (n /= 0) then
            gic = ic + reg%bb%ic0 - 1; gir = ir + reg%bb%ir0 - 1
            jc = gic - dat%icoff; jr = gir - dat%iroff
            if ((jc < 1).or.(jc > size(b%a,1)).or.(jr < 1).or.(jr > size(b%a,2))) then
              call errmsg('cell (col,row) = ('//ta((/gic, gir/))//') outside '//trim(dat%s))
            end if
            ! nodata in a boundary field means "no boundary here": the node
            ! leaves the package list
            r4val = b%a(jc,jr)
            nact = nact + 1
            if (r4val == r4nodata) then
              n = 0; ndrop = ndrop + 1
            end if
            if (n /= 0) then
              if ((n < 1) .or. (n > nodes)) then
                call errmsg('mf6_mod_get_array_r8: program error 3 '//ta((/ib/))//' '//&
                  ta((/n/))//' '//ta((/nodes/)))
              end if
              arr(n) = real(r4val,r8b) * dat%r8mult + dat%r8add
              arrflg(n) = 1
            end if
          end if
        end do
      end do
    end do
    !
    if (ndrop > 0) then
      i = index(dat%s, '/', back=.true.)
      call logmsg(trim(this%modelname)//' '//trim(dat%s(i+1:))//': '//ta((/ndrop/))//' of '// &
        ta((/nact/))//' active cells nodata, dropped')
    end if
    !
    return
  end subroutine mf6_mod_get_array_r8

  subroutine mf6_mod_build_tables(this)
! ******************************************************************************
! Node tables per layer, in node order: (1,il) every non-sea node of layer
! il, (2,il) those that are the uppermost active cell of their column. The
! period packages gather through these; nodmap is not needed afterwards.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    type(tReg), pointer :: reg
    type(tBb), pointer :: bb
    integer(i4b) :: il, jl, ireg, ir, ic, n, nt, iact, isel
    integer(i4b), dimension(2) :: cnt
! ------------------------------------------------------------------------------
    allocate(this%tab(2, gnlay))
    do il = 1, gnlay
      do iact = 1, 2
        cnt = 0
        do ireg = 1, this%nreg
          reg => this%reg(ireg); bb => reg%bb
          do ir = 1, bb%nrow
            do ic = 1, bb%ncol
              n = reg%nodmap(ic,ir,il)
              if (n <= 0) cycle
              nt = 0
              do jl = 1, gnlay
                nt = reg%nodmap(ic,ir,jl)
                if (nt /= 0) exit
              end do
              cnt(1) = cnt(1) + 1
              if (iact == 2) call put(1, cnt(1))
              if (nt == n) then
                cnt(2) = cnt(2) + 1
                if (iact == 2) call put(2, cnt(2))
              end if
            end do
          end do
        end do
        if (iact == 1) then
          do isel = 1, 2
            this%tab(isel,il)%n = cnt(isel)
            allocate(this%tab(isel,il)%node(cnt(isel)))
            allocate(this%tab(isel,il)%gic(cnt(isel)))
            allocate(this%tab(isel,il)%gir(cnt(isel)))
          end do
        end if
      end do
    end do
    !
    return
    !
  contains
    subroutine put(isel, k)
      integer(i4b), intent(in) :: isel, k
      this%tab(isel,il)%node(k) = n
      this%tab(isel,il)%gic(k) = ic + bb%ic0 - 1
      this%tab(isel,il)%gir(k) = ir + bb%ir0 - 1
    end subroutine put
  end subroutine mf6_mod_build_tables

  subroutine mf6_mod_write_records(this, nsys, nodes, flg, val, p0, p1)
! ******************************************************************************
! Append the MODFLOW list records (node, values) of the flagged nodes to the
! model binary, system-major, node order; p0..p1 is their byte range.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: nsys
    integer(i4b), intent(in) :: nodes
    integer(i1b), dimension(:), intent(in) :: flg
    real(r8b), dimension(:,:), intent(in) :: val
    integer(i8b), intent(out) :: p0, p1
    ! -- local
    integer(i1b), dimension(:), allocatable :: buf
    integer(i1b), dimension(8) :: mold
    integer(i8b) :: p, nrec
    integer(i4b) :: nf, reclen, isys, j, m, f
! ------------------------------------------------------------------------------
    nf = size(val,1); reclen = 4 + 8*nf
    nrec = count(flg == 1)
    allocate(buf(nrec*reclen))
    p = 0
    do isys = 1, nsys
      do j = 1, nodes
        m = j + (isys-1)*nodes
        if (flg(m) /= 1) cycle
        buf(p+1:p+4) = transfer(j, mold(1:4))
        do f = 1, nf
          buf(p+5+8*(f-1):p+4+8*f) = transfer(val(f,m), mold)
        end do
        p = p + reclen
      end do
    end do
    inquire(this%iubin, pos=p0)
    if (nrec > 0) write(this%iubin) buf
    inquire(this%iubin, pos=p1)
    !
    return
  end subroutine mf6_mod_write_records
!
  subroutine mf6_mod_write_post_map(this, iwrite)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: iwrite
    ! -- local
    character(len=mxslen) :: d
    type(tReg), pointer :: reg
    type(tBb), pointer :: bb
    character(len=mxslen) :: f
    integer(i4b) :: ireg, nodes, n, iu, il, ir, ic, kr, kc, nlay, gic, gir, gil, i, j
    integer(c_int) :: ierr
    real(r8b) :: xmin, ymin
! ------------------------------------------------------------------------------
    !
    nodes = 0
    do ireg = 1, this%nreg
      reg => this%reg(ireg)
      do il = 1, size(reg%layer_nodes)
        nodes = nodes + reg%layer_nodes(il)
      end do
    end do
    !
    call clear_wrk()
    allocate(i4wrk2d(3,nodes))
    do i = 1, nodes
      do j = 1, 3
        i4wrk2d(j,i) = 0
      end do
    end do
    !
    do ireg = 1, this%nreg
      reg => this%reg(ireg)
      do il = 1, size(reg%layer_nodes)
        bb => reg%bb
        nlay = size(reg%nodmap,3)
        do ir = 1, bb%nrow
          do ic = 1, bb%ncol
            n = reg%nodmap(ic,ir,il)
            gil = il; gic = ic + bb%ic0 - 1; gir = ir + bb%ir0 - 1
            if (n < 0) then
              gil = -gil
            end if
            if (n /= 0) then
              n = abs(n)
              if (i4wrk2d(1,n) /= 0) then
                call errmsg('mf6_mod_write_post_map: program error')
              end if
              i4wrk2d(1,n) = gil; i4wrk2d(2,n) = gir; i4wrk2d(3,n) = gic
            end if
          end do
        end do
      end do
    end do
    !
    ! check
    do i = 1, nodes
      if (i4wrk2d(1,i) == 0) then
        call errmsg('mf6_mod_write_post_map: program error')
      end if
    end do
    !
    d = '../../models/post_mappings/'
    f = trim(d)//trim(this%modelname)//'.nodmap.bin'
    call open_file(f, iu, 'w', .true.)
    write(iu) this%bb%ic0, this%bb%ic1, this%bb%ir0, this%bb%ir1
    write(iu) nodes ! number of nodes
    write(iu)((i4wrk2d(j,i),j=1,3),i=1,nodes)
    close(iu)
    !
    if (iwrite == 1) then
      call clear_wrk()
      allocate(i4wrk2d(this%bb%ncol, this%bb%nrow))
      do il = 1, gnlay
        do ir = 1, this%bb%nrow
          do ic = 1, this%bb%ncol
            i4wrk2d(ic,ir) = 0
          end do
        end do
        do ireg = 1, this%nreg
          reg => this%reg(ireg)
          bb => reg%bb
          do ir = 1, bb%nrow
            do ic = 1, bb%ncol
              n = reg%nodmap(ic,ir,il)
              gic = ic + bb%ic0 - 1; gir = ir + bb%ir0 - 1
              kc = gic - this%bb%ic0 + 1
              kr = gir - this%bb%ir0 + 1
              i4wrk2d(kc,kr) = n
            end do
          end do
        end do
        f = trim(d)//trim(this%modelname)//'.nodmap.l'//ta((/il/), 2)//'.nc'
        xmin = gxmin + (this%bb%ic0-1)*gcs
        ymin = gymin + (gnrow-this%bb%ir1)*gcs
        ! netCDF is not thread-safe: it creates the file, the chunks are
        ! deflated on the team and written through HDF5
        !$omp critical(netcdf)
        ierr = h5eset_auto2(0_c_int64_t, c_null_funptr, c_null_ptr)
        call raster_create_i4(f, this%bb%ncol, this%bb%nrow, dble(xmin), dble(ymin), dble(gcs), 0)
        !$omp end critical(netcdf)
        call write_raster_chunks(f, 'data', i4wrk2d, 0)
      end do
    end if
    !
    return
  end subroutine mf6_mod_write_post_map
!
  subroutine mf6_mod_clean_regions(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    type(tReg), pointer :: reg
    integer(i4b) :: ireg
! ------------------------------------------------------------------------------
    !
    if (.not.associated(this%nreg)) return
    !
    do ireg = 1, this%nreg
      reg => this%reg(ireg)
      if (associated(reg%bb))          deallocate(reg%bb)
      if (associated(reg%layer_nodes)) deallocate(reg%layer_nodes)
      if (associated(reg%nodmap))     deallocate(reg%nodmap)
      if (associated(reg%bndmap))     deallocate(reg%bndmap)
    end do
    !
    deallocate(this%nreg); this%nreg => null()
    deallocate(this%reg);  this%reg  => null()
    !
    return
  end subroutine mf6_mod_clean_regions
    
  function mf6_mod_count_i1a(this, i1a, nsys_in) result(cnt)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i1b), dimension(:), intent(in) :: i1a
    integer(i4b), intent(in), optional :: nsys_in
    integer(i4b), dimension(gnlay) :: cnt
    ! -- local
    type(tReg), pointer :: reg
    type(tBb), pointer :: bb
    integer(i4b) :: ireg, il, ir, ic, n, m, nsys, isys, nodes
! ------------------------------------------------------------------------------
    nodes = sum(this%layer_nodes)
    if (present(nsys_in)) then
      nsys = nsys_in
    else
      nsys = 1
    end if
    !
    cnt = 0
    !
    if (.not.associated(this%nreg)) return
    !
    do isys = 1, nsys
      do ireg = 1, this%nreg
        reg => this%reg(ireg)
        bb => reg%bb
        do il = 1, gnlay
          do ir = 1, bb%nrow
            do ic = 1, bb%ncol
              n = abs(reg%nodmap(ic,ir,il))
              if (n > 0) then
                m = n + (isys-1)*nodes
                if (i1a(m) == 1) then
                  cnt(il) = cnt(il) + 1
                end if
              end if
            end do
          end do
        end do
      end do
    end do
    !
    call logmsg('#cells assigned to layers: '//ta(cnt))
    !
    return
  end function mf6_mod_count_i1a
  
  subroutine mf6_mod_get_model_name(this, i, modelname)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: i
    character(len=*), intent(out) :: modelname
    ! -- local
! ------------------------------------------------------------------------------
    write(modelname,'(a,i5.5)') 'm', i
    !
    return
  end subroutine mf6_mod_get_model_name
  !  
  subroutine mf6_mod_set_disu(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    real(r8b), parameter :: nodata = -9999.d0
    real(r8b), parameter :: thkmin = 0.1d0
    !
    integer(i4b), dimension(ns) :: ihc
    !        p t n w e s b
    data ihc/0,0,1,1,1,1,0/
    type(tBb), pointer :: bb
    real(r8b), dimension(ns) :: hwva, cl12
    type(tDisu), pointer :: disu
    type(tReg), pointer :: reg
    integer(i4b) :: ireg, n, ilay, iact, nja
    integer(i4b), dimension(ns) :: s
    integer(i4b) :: ic, ir, i, top_i_raw, bot_i_raw
    real(r8b) :: topval, botval
! ------------------------------------------------------------------------------
    !
    hwva(jp) = DZERO
    hwva(jn) = gcs
    hwva(js) = gcs
    hwva(jw) = gcs
    hwva(je) = gcs
    hwva(jt) = gcs*gcs
    hwva(jb) = gcs*gcs
    !
    allocate(this%disu)
    disu => this%disu
    !
    allocate(disu%nodes)
    disu%nodes = 0
    do ireg = 1, this%nreg
      reg => this%reg(ireg)
      disu%nodes = disu%nodes + sum(reg%layer_nodes)
    end do
    !
    ! iac
    allocate(disu%iac(disu%nodes))
    allocate(disu%nja)
    !
    do iact = 1, 2
      do n = 1, disu%nodes
        disu%iac(n) = 0
      end do
      disu%nja = 0
      s = 0; cl12 = DZERO
      !
      do ilay = 1, gnlay
        do ireg = 1, this%nreg
          reg => this%reg(ireg); bb => reg%bb
          if (ilay == 1) then
            top_i_raw = this%get_i_raw(i_top, 0, 0, 0)
            bot_i_raw = this%get_i_raw(i_bot, 1, 0, 0)
          else if (ilay == 2) then
            top_i_raw = this%get_i_raw(i_bot, 1, 0, 0)
            bot_i_raw = this%get_i_raw(i_bot, 2, 0, 0)
          end if
          !
          do ir = 1, reg%bb%nrow
            do ic = 1, reg%bb%ncol
              n = reg%nodmap(ic,ir,ilay)
              n = abs(n)
              if (n /= 0) then
                s(jp) = n !CENTER
                if (ir > 1) then !NORTH
                  s(jn) = abs(reg%nodmap(ic,ir-1,ilay))
                  if (s(jn) /= 0) then
                    cl12(jn) = gcs/2
                  end if
                end if
                if (ir < reg%bb%nrow) then !SOUTH
                  s(js) = abs(reg%nodmap(ic,ir+1,ilay))
                  if (s(js) /= 0) then
                    cl12(js) = gcs/2
                  end if
                end if
                if (ic > 1) then !WEST
                  s(jw) = abs(reg%nodmap(ic-1,ir,ilay))
                  if (s(jw) /= 0) then
                    cl12(jw) = gcs/2
                  end if
                end if
                if (ic < reg%bb%ncol) then !EAST
                  s(je) = abs(reg%nodmap(ic+1,ir,ilay))
                  if (s(je) /= 0) then
                    cl12(je) = gcs/2
                  end if
                end if
                !if (n == 7864) then
                !  write(*,*) '@@@@@'
                !end if
                if (ilay == 1) then
                  topval = this%get_val(top_i_raw, ireg, ic, ir)
                  botval = this%get_val(bot_i_raw, ireg, ic, ir)
                else if (ilay == 2) then
                  topval = this%get_val(top_i_raw, ireg, ic, ir)
                  botval = this%get_val(bot_i_raw, ireg, ic, ir)
                end if
                !
                if (ilay > 1) then !TOP
                  s(jt) = abs(reg%nodmap(ic,ir,ilay-1))
                  if ((topval == nodata).or.(botval == nodata)) then
                    call errmsg('mf6_mod_set_disu: program error (top/bot).')
                  end if
                  cl12(jt) = max(thkmin, topval-botval)
                  cl12(jt) = cl12(jt)/2
                end if
                if (ilay < gnlay) then !BOT
                  s(jb) = abs(reg%nodmap(ic,ir,ilay+1))
                  if ((topval == nodata).or.(botval == nodata)) then
                    call errmsg('mf6_mod_set_disu: program error (top/bot).')
                  end if
                  cl12(jb) = max(thkmin, topval-botval)
                  cl12(jb) = cl12(jb)/2
                end if
                if ((n < 1).or.(n > disu%nodes)) then
                 call errmsg('mf6_mod_set_disu: program error')
                end if
                do i = 1, ns
                  if (s(i) /= 0) then
                    if (s(i) < 0) then
                      call errmsg('mf6_mod_set_disu: program error')
                    end if
                    disu%iac(n) = disu%iac(n) + 1
                    disu%nja = disu%nja + 1
                    if (iact == 2) then
                      if ((disu%nja < 1).or.(disu%nja > nja)) then
                       call errmsg('mf6_mod_set_disu: program error')
                      end if
                      disu%ja(disu%nja)   = s(i)
                      disu%ihc(disu%nja)  = ihc(i)
                      disu%cl12(disu%nja) = cl12(i)
                      disu%hwva(disu%nja) = hwva(i)
                    end if
                  end if
                  s(i) = 0
                  cl12(i) = DZERO
                end do
                !
              end if
            end do
          end do
        end do !ilay
      end do !rreg
      if (iact == 1) then
        nja = disu%nja
        allocate(disu%ja(disu%nja))
        allocate(disu%ihc(disu%nja))
        allocate(disu%cl12(disu%nja))
        allocate(disu%hwva(disu%nja))
        do i = 1, disu%nja
          disu%ihc(i) = 0
        end do
      end if
    end do !iact
    !
    return
  end subroutine mf6_mod_set_disu
  
  subroutine mf6_mod_write_array_i4(this, iu, nx, f, arr, lbin, lbinpos_in)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: iu 
    integer(i4b), intent(in) :: nx
    character(len=*), intent(inout) :: f
    integer(i4b), dimension(:), intent(in) :: arr
    logical, intent(in) :: lbin
    logical, intent(in), optional :: lbinpos_in
    ! -- local
    integer(i4b), parameter :: i4dum = 1
    real(r8b), parameter :: r8dum = DZERO
    character(len=16) :: c16dum = ''
    integer(i4b) :: ju, i, narr
    integer(i8b) :: p0, p1
    character(len=mxslen) :: fmt
    logical :: lbinpos
! ------------------------------------------------------------------------------
    if (present(lbinpos_in)) then
      lbinpos = lbinpos_in
    else
      lbinpos = .false.
    end if
    !    
    if (lbin) then
      if (.not.lbinpos) then
        f = trim(f)//'.bin'
        call open_file(f, ju, 'w', .true.)
      else
        f = this%fbin
        ju = this%iubin
      end if
      narr = size(arr)
      if (lbinpos) inquire(ju,pos=p0)
      write(ju) i4dum, i4dum, r8dum, r8dum, c16dum, narr, i4dum, i4dum
      write(ju) arr
      if (lbinpos) then
        inquire(ju,pos=p1)
      else
        close(ju)
      end if
      !call get_rel_up(f, 2)
      if (.not.lbinpos) then
        call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f)//' (BINARY)')
      else
        call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f)//' (BINARY) '//ta((/p0,p1/)))
      end if
    else
      f = trim(f)//'.asc'
      call open_file(f, ju, 'w')
      do i = 1, size(arr)
        call wline(ju, ta((/arr(i)/)))
      end do
      close(ju)
      !call get_rel_up(f, 2)
      call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f))
    end if
    !
    return
  end subroutine mf6_mod_write_array_i4
  
  subroutine mf6_mod_write_array_r8(this, iu, nx, f, arr, lbin, lbinpos_in)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: iu 
    integer(i4b), intent(in) :: nx
    character(len=*), intent(inout) :: f
    real(r8b), dimension(:), intent(in) :: arr
    logical, intent(in) :: lbin
    logical, intent(in), optional :: lbinpos_in
    ! -- local
    integer(i4b), parameter :: i4dum = 1
    real(r8b), parameter :: r8dum = DZERO
    character(len=16) :: c16dum = ''
    integer(i4b) :: ju, i, narr
    integer(i8b) :: p0, p1
    character(len=mxslen) :: fmt
    logical :: lbinpos
! ------------------------------------------------------------------------------
    if (present(lbinpos_in)) then
      lbinpos = lbinpos_in
    else
      lbinpos = .false.
    end if
    !
    if (lbin) then
      if (.not.lbinpos) then
        f = trim(f)//'.bin'
        call open_file(f, ju, 'w', .true.)
      else
        f = this%fbin
        ju = this%iubin
      end if
      if (lbinpos) inquire(ju,pos=p0)
      narr = size(arr)
      write(ju) i4dum, i4dum, r8dum, r8dum, c16dum, narr, i4dum, i4dum
      write(ju) arr
      if (lbinpos) then
        inquire(ju,pos=p1)
      else
        close(ju)
      end if
      !call get_rel_up(f, 2)
      if (.not.lbinpos) then
        call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f)//' (BINARY)')
      else
        call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f)//' (BINARY) '//ta((/p0,p1/)))
      end if
    else
      f = trim(f)//'.asc'
      call open_file(f, ju, 'w')
      do i = 1, size(arr)
        call wline(ju, ta((/arr(i)/)))
      end do
      close(ju)
      !call get_rel_up(f, 2)
      call wline(iu, repeat(' ',nx)//'OPEN/CLOSE '//trim(f))
    end if
    !
    return
  end subroutine mf6_mod_write_array_r8
  
  subroutine list_pck_fields(ipack, nf, kf, isel, what, why)
! ******************************************************************************
! The fields of a list package, its node selection (1 all non-sea nodes,
! 2 uppermost active) and the words of its log lines.
! ------------------------------------------------------------------------------
    ! -- dummy
    integer(i4b), intent(in) :: ipack
    integer(i4b), intent(out) :: nf, isel
    integer(i4b), dimension(3), intent(out) :: kf
    character(len=*), intent(out) :: what, why
! ------------------------------------------------------------------------------
    kf = 0
    select case (ipack)
    case (idrn)
      nf = 2; kf(1:2) = (/i_drn_elev, i_drn_cond/); isel = 1
      what = 'drains'; why = 'conductance'
    case (iriv)
      nf = 3; kf(1:3) = (/i_riv_stage, i_riv_cond, i_riv_rbot/); isel = 2
      what = 'rivers'; why = 'conductance'
    case (ighb1)
      nf = 2; kf(1:2) = (/i_ghb1_bhead, i_ghb1_cond/); isel = 1
      what = 'general-head boundaries'; why = 'conductance'
    case (ighb2)
      nf = 2; kf(1:2) = (/i_ghb2_bhead, i_ghb2_cond/); isel = 1
      what = 'general-head boundaries'; why = 'conductance'
    case (irch)
      nf = 1; kf(1) = i_recharge; isel = 2
      what = 'recharge cells'; why = 'recharge'
    case (iwel)
      nf = 1; kf(1) = i_wel; isel = 1
      what = 'wells'; why = 'flux'
    case default
      call errmsg('list_pck_fields: not a list package')
    end select
    !
    return
  end subroutine list_pck_fields

  function list_pck_ilay(ipack, il) result(ilay_dat)
! ******************************************************************************
! The _L key layer a list package reads for target layer il: rivers take the
! L1 fields for both layers, recharge has no layer, the rest their own.
! ------------------------------------------------------------------------------
    integer(i4b), intent(in) :: ipack, il
    integer(i4b) :: ilay_dat
! ------------------------------------------------------------------------------
    select case (ipack)
    case (iriv)
      ilay_dat = 1
    case (irch)
      ilay_dat = 0
    case default
      ilay_dat = il
    end select
    !
    return
  end function list_pck_ilay

  subroutine mf6_mod_write_static(this)
! ******************************************************************************
! Open the model binary and write everything that does not depend on the
! stress period: disu, ic, oc, npf, sto, chd. The list packages follow in
! write_period_list, one stage at a time, and write_finish closes the model.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    logical, parameter :: lbin    = .true.
    logical, parameter :: lbinpos = .true.
    character(len=mxslen) :: s
    integer(i4b) :: ipack, nper
! ------------------------------------------------------------------------------
    call logmsg('***** Writing static input for model '//trim(this%modelname)//'...')
    !
    allocate(this%fbin, this%iubin)
    this%fbin = trim(this%bindir)//trim(this%modelname)//'.bin'
    call open_file(this%fbin, this%iubin, 'w', .true., unit_in=10000+this%imod)
    !
    ! set the defaults
    this%pckact = 1
    this%pckact(isto) = raw%geti('act_sto',idef=1)
    this%pckact(iriv) = raw%geti('act_riv',idef=1)
    this%pckact(iwel) = raw%geti('act_wel',idef=1)
    this%pckact(ighb1) = raw%geti('act_ghb',idef=0)
    this%pckact(ighb2) = raw%geti('act_ghb2',idef=0)
    this%pckact(ichd1) = raw%geti('act_chd',idef=1)
    this%pckact(ichd2) = raw%geti('act_chd2',idef=1)
    !
    call this%write_disu(lbin, lbinpos)
    call this%write_ic(lbin, lbinpos)
    call this%write_oc()
    call this%write_npf(lbin, lbinpos)
    call this%write_sto(lbin, lbinpos)
    call this%write_chd(lbin, lbinpos, ichd1)
    call this%write_chd(lbin, lbinpos, ichd2)
    !
    nper = raw%nper
    do ipack = idrn, npck
      allocate(this%lp(ipack)%lact(nper), this%lp(ipack)%p0(nper), this%lp(ipack)%p1(nper))
      this%lp(ipack)%lact = .false.; this%lp(ipack)%p0 = 0; this%lp(ipack)%p1 = 0
    end do
    s = raw%getc(keys(i_ndrnsys),cdef='')
    if (len_trim(s) > 0) this%lp(idrn)%nsys = atoi(s)
    s = raw%getc(keys(i_nrivsys),cdef='')
    if (len_trim(s) > 0) this%lp(iriv)%nsys = atoi(s)
    this%lp(idrn)%nx = 4; this%lp(ighb1)%nx = 4; this%lp(ighb2)%nx = 4
    !
    return
  end subroutine mf6_mod_write_static

  subroutine mf6_mod_write_period_list(this, ipack, iper, ibuf)
! ******************************************************************************
! One list package for one stress period: gather the fields through the node
! tables, apply the package's filters, append the records to the model binary.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod), target :: this
    integer(i4b), intent(in) :: ipack, iper, ibuf
    ! -- local
    type(tListPck), pointer :: lp
    type(tNodTab), pointer :: t
    type(tData), pointer :: dat
    type(tSlice), pointer :: b
    integer(i1b), dimension(:), allocatable :: flg
    real(r8b), dimension(:,:), allocatable :: val
    integer(i4b), dimension(3) :: kf
    integer(i4b), dimension(gnlay) :: cnt, ncum
    integer(i4b) :: nf, isel, nsys, jsys, nodes, isys, il, f, k, m, n, i_raw, jc, jr
    integer(i4b) :: nact, ndrop, nrem, nneg, nbound
    real(r4b) :: r4val, r4nodata
    character(len=mxslen) :: what, why
! ------------------------------------------------------------------------------
    lp => this%lp(ipack)
    call list_pck_fields(ipack, nf, kf, isel, what, why)
    nsys = lp%nsys
    nodes = sum(this%layer_nodes)
    allocate(flg(nodes*nsys), val(nf, nodes*nsys))
    flg = 0; val = DZERO
    !
    do isys = 1, nsys
      jsys = 0
      if (nsys > 1) jsys = isys
      do il = 1, gnlay
        t => this%tab(isel, il)
        do f = 1, nf
          i_raw = raw%mf6_raw_get_index(keys(kf(f)), list_pck_ilay(ipack, il), iper, jsys)
          if (i_raw <= 0) then
            call errmsg('no '//trim(keys(kf(f)))//' for layer '//ta((/il/))//', period '//ta((/iper/)))
          end if
          dat => raw%raw(i_raw)%dat
          b => raw%slice(i_raw, iper, ibuf)
          r4nodata = real(dat%r%nodata, r4b)
          nact = 0; ndrop = 0
          do k = 1, t%n
            jc = t%gic(k) - dat%icoff; jr = t%gir(k) - dat%iroff
            if ((jc < 1).or.(jc > size(b%a,1)).or.(jr < 1).or.(jr > size(b%a,2))) then
              call errmsg('cell (col,row) = ('//ta((/t%gic(k), t%gir(k)/))//') outside '//trim(dat%s))
            end if
            r4val = b%a(jc,jr)
            nact = nact + 1
            m = t%node(k) + (isys-1)*nodes
            ! nodata in a boundary field means "no boundary here": the node
            ! leaves the package list
            if (r4val == r4nodata) then
              ndrop = ndrop + 1
            else
              val(f,m) = real(r4val,r8b) * dat%r8mult + dat%r8add
              flg(m) = 1
            end if
          end do
          if ((ndrop > 0).and.(iper <= 1)) then
            k = index(dat%s, '/', back=.true.)
            call logmsg(trim(this%modelname)//' '//trim(dat%s(k+1:))//': '//ta((/ndrop/))//' of '// &
              ta((/nact/))//' active cells nodata, dropped (period 1; later periods not reported)')
          end if
        end do
      end do
    end do
    !
    ! checks and filters
    nrem = 0; nneg = 0
    select case (ipack)
    case (idrn)
      do m = 1, size(flg)
        if (val(1,m) < -1000D0) then
          call errmsg("Invalid range for drain.")
        end if
      end do
      do m = 1, size(flg)
        if (val(2,m) == DZERO) then
          if (flg(m) == 1) nrem = nrem + 1
          flg(m) = 0
        end if
        if (val(2,m) < DZERO) then
          call errmsg("Negative drain conductance.")
        end if
      end do
    case (iriv)
      do m = 1, size(flg)
        if (flg(m) == 1) then
          if (val(1,m) < val(3,m)) then
            call errmsg('Inconsistent river stage/rbot.')
          end if
          if (val(2,m) < DZERO) then
            call errmsg('Negative river conductance.')
          end if
        end if
        if (val(2,m) == DZERO) then
          if (flg(m) == 1) nrem = nrem + 1
          flg(m) = 0
        end if
      end do
    case (ighb1, ighb2)
      do m = 1, size(flg)
        if (val(2,m) == DZERO) then
          if (flg(m) == 1) nrem = nrem + 1
          flg(m) = 0
        end if
        if (val(2,m) < DZERO) then
          call errmsg("Negative general-head boundary conductance.")
        end if
      end do
    case (irch)
      do m = 1, size(flg)
        if (val(1,m) == DZERO) then
          if (flg(m) == 1) nrem = nrem + 1
          flg(m) = 0
        end if
        if (val(1,m) < DZERO) nneg = nneg + 1
      end do
      if (nneg > 0) then
        call logmsg(trim(this%modelname)//' period '//ta((/iper/))//': negative recharge in '// &
          ta((/nneg/))//' cells.')
      end if
    case (iwel)
      do m = 1, size(flg)
        if (val(1,m) == DZERO) then
          if (flg(m) == 1) nrem = nrem + 1
          flg(m) = 0
        end if
      end do
    end select
    if ((nrem > 0).and.(iper <= 1)) then
      call logmsg(trim(this%modelname)//': removed '//ta((/nrem/))//' '//trim(what)//' with zero '// &
        trim(why)//' (period 1; later periods not reported)')
    end if
    !
    ! count per layer
    ncum(1) = this%layer_nodes(1)
    do il = 2, gnlay
      ncum(il) = ncum(il-1) + this%layer_nodes(il)
    end do
    cnt = 0
    do m = 1, size(flg)
      if (flg(m) /= 1) cycle
      n = mod(m-1, nodes) + 1
      il = 1
      do while (n > ncum(il))
        il = il + 1
      end do
      cnt(il) = cnt(il) + 1
    end do
    if (iper <= 1) then
      call logmsg(trim(this%modelname)//' '//trim(what)//' per layer: '//ta(cnt))
    end if
    nbound = sum(cnt)
    lp%maxbound = max(lp%maxbound, nbound)
    if (nbound == 0) then
      lp%lact(iper) = .false.
      if (iper <= 1) call logmsg(trim(this%modelname)//': no '//trim(what)//' found.')
    else
      lp%lact(iper) = .true.
      call this%write_records(nsys, nodes, flg, val, lp%p0(iper), lp%p1(iper))
    end if
    !
    return
  end subroutine mf6_mod_write_period_list

  subroutine mf6_mod_write_finish(this)
! ******************************************************************************
! The list package files (period blocks pointing into the model binary), the
! nam files, close the binary, the done sentinel.
! ------------------------------------------------------------------------------
    ! -- dummy
    class(tMf6_mod), target :: this
    ! -- local
    integer(i4b), dimension(6), parameter :: packs = (/idrn, iriv, ighb1, ighb2, irch, iwel/)
    type(tListPck), pointer :: lp
    character(len=mxslen) :: p, f, packstr
    integer(i4b), dimension(:), allocatable :: map
    integer(i4b) :: i, ipack, iu, iper, jper, nper, nperspu
! ------------------------------------------------------------------------------
    p = trim(this%rootdir)//trim(this%modelname)
    nper = raw%nper
    allocate(map(nper))
    !
    do i = 1, size(packs)
      ipack = packs(i)
      if (this%pckact(ipack) == 0) cycle
      lp => this%lp(ipack)
      if (lp%maxbound == 0) then
        call logmsg(trim(this%modelname)//': no '//trim(pck(ipack))//' cells in any period; package dropped')
        this%pckact(ipack) = 0
        cycle
      end if
      select case (ipack)
      case (ighb1, ighb2)
        packstr = trim(pr(ipack,irun0ss))//'.ghb'
      case default
        packstr = '.'//trim(pck(ipack))
      end select
      !
      do iper = 1, nper
        map(iper) = iper
      end do
      f = trim(p)//trim(packstr)
      call write_periods(f)
      !
      ! the spin-up run cycles through the first year(s)
      if (ltransient) then
        nperspu = raw%geti('nmonth_spinup')
        do iper = 1, nper
          select case (ipack)
          case (idrn, ighb1, ighb2)
            jper = mod(iper, nperspu)
            if (jper == 0) jper = nperspu
          case default
            jper = mod(iper, 12)
            if (jper == 0) jper = 1
          end select
          map(iper) = jper
        end do
        f = trim(p)//trim(pr(ipack,irun0tr))//trim(packstr)
        call write_periods(f)
      end if
    end do
    !
    call this%write_nam()
    close(this%iubin)
    !
    f = '../../log/done_'//trim(this%modelname)
    call open_file(f, iu, 'w')
    close(iu)
    !
    return
    !
  contains
    subroutine write_periods(f)
      character(len=mxslen), intent(inout) :: f
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'MAXBOUND '//ta((/lp%maxbound/)))
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      do iper = 1, nper
        call write_block_begin(iu, 'PERIOD '//ta((/iper/)))
        jper = map(iper)
        if (lp%lact(jper)) then
          call wline(iu, repeat(' ',lp%nx)//'OPEN/CLOSE '//trim(this%fbin)//' (BINARY) '// &
            ta((/lp%p0(jper), lp%p1(jper)/)))
        end if
        call write_block_end(iu, 'PERIOD')
      end do
      close(iu)
    end subroutine write_periods
  end subroutine mf6_mod_write_finish

  subroutine mf6_write_models(smod, idx, iwrite)
! ******************************************************************************
! Write the models idx: the static input of every model in parallel, then
! every (period, list package) stage over all models in parallel while one
! task loads the next stage's rasters into the other buffer, then the package
! and nam files. A model's binary receives its static arrays and then the
! list records period by period, so its OPEN/CLOSE offsets are period-major.
! ------------------------------------------------------------------------------
    ! -- dummy
    type(tMf6_mod), dimension(:), intent(inout) :: smod
    integer(i4b), dimension(:), intent(in) :: idx
    integer(i4b), dimension(:), intent(in) :: iwrite
    ! -- local
    integer(i4b), parameter :: npk = 6
    integer(i4b), dimension(npk), parameter :: packs = (/idrn, iriv, ighb1, ighb2, irch, iwel/)
    integer(i4b), dimension(:), allocatable :: spack, sper, lst
    logical, dimension(:), allocatable :: lused
    integer(i4b) :: i, k, s, ns, ib, nper, nw, ipk
    real(r8b) :: t0, t1
    character(len=mxslen) :: d
! ------------------------------------------------------------------------------
    nw = size(idx)
    area_str = ta_u((/gcs*gcs/))
    !
    ! every static raster, once, for all models
    t0 = omp_get_wtime()
    !$omp parallel default(shared) private(i)
    !$omp single
    do i = 1, raw%nraw
      if (.not.raw%raw(i)%dat%lraster) cycle
      if (raw%raw(i)%dat%r%nt == 0) call raw%load(i, 0, 1)
    end do
    !$omp end single
    !$omp end parallel
    call logmsg('static rasters loaded: '//secs(omp_get_wtime()-t0))
    d = '../../models/post_mappings/'
    call create_dir(d, .true.)
    !
    t0 = omp_get_wtime()
    !$omp parallel do schedule(dynamic,1) default(shared) private(k, t1)
    do k = 1, nw
      t1 = omp_get_wtime()
      call smod(idx(k))%write_static()
      call smod(idx(k))%write_post_map(iwrite(k))
      call smod(idx(k))%build_tables()
      call smod(idx(k))%clean_regions()
      call logmsg(trim(smod(idx(k))%modelname)//' static: '//secs(omp_get_wtime()-t1))
    end do
    !$omp end parallel do
    call logmsg('static input of '//ta((/nw/))//' models: '//secs(omp_get_wtime()-t0))
    !
    ! the stages: every active list package of every period, in binary order
    nper = raw%nper
    allocate(spack(nper*npk), sper(nper*npk))
    ns = 0
    do i = 1, nper
      do ipk = 1, npk
        if (smod(idx(1))%pckact(packs(ipk)) == 0) cycle
        ns = ns + 1; spack(ns) = packs(ipk); sper(ns) = i
      end do
    end do
    !
    ! keep only the static rasters a stage reads; this also resolves every
    ! (field, layer, period) key before anything is written
    allocate(lused(raw%nraw)); lused = .false.
    do s = 1, ns
      call stage_rasters(s, lst)
      do i = 1, size(lst)
        lused(lst(i)) = .true.
      end do
    end do
    do i = 1, raw%nraw
      if (.not.raw%raw(i)%dat%lraster) cycle
      if ((raw%raw(i)%dat%r%nt == 0).and.(.not.lused(i))) call raw%free(i, 1)
    end do
    !
    !$omp parallel default(shared) private(s, k, ib, t1)
    !$omp single
    if (ns > 0) call load_stage(1, 1)
    do s = 1, ns
      ib = mod(s-1, 2) + 1
      t1 = omp_get_wtime()
      if (s < ns) then
        !$omp task firstprivate(s, ib)
        call load_stage(s+1, 3-ib)
        !$omp end task
      end if
      do k = 1, nw
        !$omp task firstprivate(k, s, ib)
        call smod(idx(k))%write_period_list(spack(s), sper(s), ib)
        !$omp end task
      end do
      !$omp taskwait
      call free_stage(s, ib)
      call logmsg('period '//ta((/sper(s)/))//' '//trim(pck(spack(s)))//': '// &
        secs(omp_get_wtime()-t1))
    end do
    !$omp end single
    !$omp end parallel
    !
    t0 = omp_get_wtime()
    !$omp parallel do schedule(dynamic,1) default(shared) private(k)
    do k = 1, nw
      call smod(idx(k))%write_finish()
    end do
    !$omp end parallel do
    call logmsg('package and nam files of '//ta((/nw/))//' models: '//secs(omp_get_wtime()-t0))
    !
    return
    !
  contains
    subroutine stage_rasters(s, lst)
      ! the raw entries stage s reads
      integer(i4b), intent(in) :: s
      integer(i4b), dimension(:), allocatable, intent(out) :: lst
      integer(i4b), dimension(:), allocatable :: sraw
      integer(i4b), dimension(3) :: kf
      integer(i4b) :: n, nf, isel, nsys, isys, jsys, il, f, i_raw, j
      character(len=mxslen) :: what, why
      logical :: lnew
      call list_pck_fields(spack(s), nf, kf, isel, what, why)
      nsys = smod(idx(1))%lp(spack(s))%nsys
      allocate(sraw(3*gnlay*nsys))
      n = 0
      do isys = 1, nsys
        jsys = 0
        if (nsys > 1) jsys = isys
        do il = 1, gnlay
          do f = 1, nf
            i_raw = raw%mf6_raw_get_index(keys(kf(f)), list_pck_ilay(spack(s), il), sper(s), jsys)
            if (i_raw <= 0) then
              call errmsg('no '//trim(keys(kf(f)))//' for layer '//ta((/il/))//', period '//ta((/sper(s)/)))
            end if
            lnew = .true.
            do j = 1, n
              if (sraw(j) == i_raw) lnew = .false.
            end do
            if (lnew) then
              n = n + 1; sraw(n) = i_raw
            end if
          end do
        end do
      end do
      lst = sraw(1:n)
    end subroutine stage_rasters

    subroutine load_stage(s, ib)
      integer(i4b), intent(in) :: s, ib
      integer(i4b), dimension(:), allocatable :: lst
      integer(i4b) :: i
      call stage_rasters(s, lst)
      do i = 1, size(lst)
        call raw%load(lst(i), sper(s), ib)
      end do
    end subroutine load_stage

    subroutine free_stage(s, ib)
      integer(i4b), intent(in) :: s, ib
      integer(i4b), dimension(:), allocatable :: lst
      integer(i4b) :: i
      call stage_rasters(s, lst)
      do i = 1, size(lst)
        if (raw%raw(lst(i))%dat%r%nt > 0) call raw%free(lst(i), ib)
      end do
    end subroutine free_stage
  end subroutine mf6_write_models

  subroutine mf6_mod_write_nam(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    !
    character(len=mxslen) :: f, mn
    integer(i4b) :: iu, irun, irun0, irun1, ipck, jpck
! ------------------------------------------------------------------------------
    !
    if (ltransient) then
      irun0 = irun0tr
      irun1 = irun1tr
    else
      irun0 = irun0ss
      irun1 = irun1ss
    end if
    !
    do irun = irun0, irun1
      mn = this%modelname
      f = trim(this%rootdir)//trim(mn)//trim(pr(inam,irun))//'.nam'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      f = trim(resultslstdir)//'/'//trim(this%modelname)//'.'//trim(ctim)//trim(pr(inam,irun))//'.lst'
      call wline(iu, repeat(' ',2)//'LIST '//trim(f))
      if (raw%geti('newton',idef=0) == 1) then
        call wline(iu, repeat(' ',2)//'NEWTON UNDER_RELAXATION')
      end if
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'PACKAGES')
      do ipck = 3, npck
        if (this%pckact(ipck) == 0) cycle
        if (trim(pr(ipck,irun)) == '-') cycle
        f = trim(this%rootdir)//trim(mn)//trim(pr(ipck,irun))//'.'//trim(pck(ipck))
        call wline(iu, repeat(' ',2)//trim(change_case(pck(ipck),'u'))//'6 '//trim(f))
      end do
      call write_block_end(iu, 'PACKAGES')
      close(iu)
    end do
    !
    return
  end subroutine mf6_mod_write_nam
  
  subroutine mf6_mod_write_disu(this, lbin, lbinpos)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    logical, intent(in) :: lbin
    logical, intent(in) :: lbinpos
    ! -- local
    character(len=mxslen) :: p, pb, f
    integer(i4b) :: iu, i, j, n, m
    real(r8b) :: tn, bn, tm, bm, d
    type(tDisu), pointer :: disu
! ------------------------------------------------------------------------------
    if (this%pckact(idisu) == 0) return
    !
    call clear_wrk()
    !
    ! set disu
    call this%set_disu()
    disu => this%disu
    !
    p = trim(this%rootdir)//trim(this%modelname)
    if (lbin) then
      pb =  trim(this%bindir)//trim(this%modelname)
    else
      pb = p
    end if
    !
    f = trim(p)//'.disu'
    call open_file(f, iu, 'w')
    !
    call write_block_begin(iu, 'OPTIONS')
    call wline(iu, repeat(' ',2)//'LENGTH_UNITS METERS')
    call wline(iu, repeat(' ',2)//'NOGRB')
    call write_block_end(iu, 'OPTIONS')
    call wline(iu, '')
    call write_block_begin(iu, 'DIMENSIONS')
    call wline(iu, repeat(' ',2)//'NODES '//ta((/disu%nodes/)))
    call wline(iu, repeat(' ',2)//'NJA '//ta((/disu%nja/)))
    call write_block_end(iu, 'DIMENSIONS')
    call wline(iu, '')
    call write_block_begin(iu, 'GRIDDATA')
    call this%get_array(i_top, 0, 1, i1wrk, r8wrk)
    if (gnlay == 2) call this%get_array(i_bot, 1, 2, i1wrk, r8wrk) !i_bot_l1
    call this%get_array(i_bot, 1, 1, i1wrk2, r8wrk2) !i_bot_l1
    if (gnlay == 2) call this%get_array(i_bot, 2, 2, i1wrk2, r8wrk2) !i_bot_l2
    !
    ! do a check
    allocate(i4wrk1d(disu%nodes+1)); i4wrk1d(1) = 1
    do i = 1, disu%nodes
      i4wrk1d(i+1) = i4wrk1d(i) + disu%iac(i)
    end do
    do i = 1, disu%nodes
      n = disu%ja(i4wrk1d(i))
      tn = r8wrk(n); bn = r8wrk2(n)
      !if (tn < -1000D0) then
        !call errmsg('Program error mf6_mod_write_disu: top(n) = nodata')
      !end if
      !if (bn < -1000D0) then
        !call errmsg('Program error mf6_mod_write_disu: bot(n) = nodata')
      !end if
      if (bn > tn) then
        call errmsg('Program error mf6_mod_write_disu: bot(n) > top(n)')
      end if
      d = tn - bn
      if (d <= DZERO) then
        call errmsg('Program error mf6_mod_write_disu: top(n) - bot(n) <= 0')
      end if
        
      do j = i4wrk1d(i)+1, i4wrk1d(i+1)-1
        m =  disu%ja(j)
        tm = r8wrk(m); bm = r8wrk2(m)
        if (bm > tm) then
          call errmsg('Program error mf6_mod_write_disu: bot(m) > top(m)')
        end if
        if (disu%ihc(j) == 0) then
          if (m > n) then
            if (tm > bn) then
              call errmsg('Program error mf6_mod_write_disu: top(m) > bot(n)')
            end if  
          else
            if (tn > bm) then
              call errmsg('Program error mf6_mod_write_disu: top(n) > bot(m)')
            end if
          end if
        end if
      end do
    end do
    !
    call wline(iu, repeat(' ',2)//'TOP')
    f = trim(pb)//'.disu.top'; call this%write_array(iu, 4, f, r8wrk, lbin, lbinpos)
    call wline(iu, repeat(' ',2)//'BOT')
    f = trim(pb)//'.disu.bot'; call this%write_array(iu, 4, f, r8wrk2, lbin, lbinpos)
    call clear_wrk()
    call wline(iu, repeat(' ',2)//'AREA')
    call wline(iu, repeat(' ',4)//'CONSTANT '//trim(area_str))
    call write_block_end(iu, 'GRIDDATA')
    call wline(iu, '')
    call write_block_begin(iu, 'CONNECTIONDATA')
    call wline(iu, repeat(' ',2)//'IAC')
    f = trim(pb)//'.disu.iac'; call this%write_array(iu, 4, f, disu%iac, lbin, lbinpos)
    call wline(iu, repeat(' ',2)//'JA')
    f = trim(pb)//'.disu.ja'; call this%write_array(iu, 4, f, disu%ja, lbin, lbinpos)
    call wline(iu, repeat(' ',2)//'IHC')
    f = trim(pb)//'.disu.ihc'; call this%write_array(iu, 4, f, disu%ihc, lbin, lbinpos)
    call wline(iu, repeat(' ',2)//'CL12')
    f = trim(pb)//'.disu.cl12'; call this%write_array(iu, 4, f, disu%cl12, lbin, lbinpos)
    call wline(iu, repeat(' ',2)//'HWVA')
    f = trim(pb)//'.disu.hwva'; call this%write_array(iu, 4, f, disu%hwva, lbin, lbinpos)
    call write_block_end(iu, 'CONNECTIONDATA')
    close(iu)
    !
    ! clean up memory
    deallocate(disu%iac);  disu%iac  => null()
    deallocate(disu%ja);   disu%ja   => null()
    deallocate(disu%ihc);  disu%ihc  => null()
    deallocate(disu%cl12); disu%cl12 => null()
    deallocate(disu%hwva); disu%hwva => null()
    !
    return
  end subroutine mf6_mod_write_disu

  subroutine mf6_mod_write_ic(this, lbin, lbinpos)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    logical, intent(in) :: lbin
    logical, intent(in) :: lbinpos
    ! -- local
    character(len=mxslen) :: p, pb, f, d
    integer(i4b) :: iu, irun0
! ------------------------------------------------------------------------------
    if (this%pckact(iic) == 0) return
    !
    if (ltransient) then
      irun0 = irun0tr
    else
      irun0 = irun0ss
    end if
    !
    call clear_wrk()
    !
    p = trim(this%rootdir)//trim(this%modelname)
    if (lbin) then
      pb =  trim(this%bindir)//trim(this%modelname)
    else
      pb = p
    end if
    !
    if (.not.ltransient) then !SS
      f = trim(p)//'.ic'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'GRIDDATA')
      call wline(iu, repeat(' ',2)//'STRT')
      call this%get_array(i_strt, 1, 1, i1wrk, r8wrk) !i_strt_l1
      if (gnlay == 2) call this%get_array(i_strt, 2, 2, i1wrk, r8wrk) !i_strt_l2
      f = trim(pb)//'.ic'; call this%write_array(iu, 4, f, r8wrk, lbin, lbinpos)
      call write_block_end(iu, 'GRIDDATA')
      close(iu)
      !
      f = trim(p)//trim(pr(iic,irun0+1))//'.ic'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'GRIDDATA')
      call wline(iu, repeat(' ',2)//'STRT')
      f = trim(resultsbindir)//'/'//trim(this%modelname)//'.ss'//trim(pr(iic,irun0+1))//'.hds'
      call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(f)//' (BINARY)')
      call write_block_end(iu, 'GRIDDATA')
      close(iu)
    else !TR
      f = trim(p)//trim(pr(iic,irun0))//'.ic'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'GRIDDATA')
      call wline(iu, repeat(' ',2)//'STRT')
      d = raw%getc('ss_strt_dir')
      f = trim(d)//trim(this%modelname)//'.ss.hds'
      call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(f)//' (BINARY)')
      call write_block_end(iu, 'GRIDDATA')
      close(iu)
      !
      f = trim(p)//trim(pr(iic,irun0+1))//'.ic'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'GRIDDATA')
      call wline(iu, repeat(' ',2)//'STRT')
      d = raw%getc('spu_strt_dir', cdef='./'//trim(resultsbindir)//'/')
      f = trim(d)//trim(this%modelname)//'.tr'//trim(pr(iic,irun0+1))//'.hds'
      call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(f)//' (BINARY)')
      call write_block_end(iu, 'GRIDDATA')
      close(iu)
    end if
    !
    return
  end subroutine mf6_mod_write_ic
  
  subroutine mf6_mod_write_oc(this)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    ! -- local
    character(len=mxslen) :: p, f
    integer(i4b) :: iu, iper, nperspu, irun0, irun
! ------------------------------------------------------------------------------
    if (this%pckact(ioc) == 0) return
    !
    if (ltransient) then
      irun0 = irun0tr
    else
      irun0 = irun0ss
    end if
    !
    p = trim(this%rootdir)//trim(this%modelname)
    !
    if (.not.ltransient) then !SS
      do irun = irun0, irun0 + 1
        f = trim(p)//trim(pr(ioc,irun))//'.oc'
        call open_file(f, iu, 'w')
        call write_block_begin(iu, 'OPTIONS')
        f = trim(resultsbindir)//'/'//trim(this%modelname)//'.ss'//trim(pr(ioc,irun))//'.hds'
        call wline(iu, repeat(' ',2)//'HEAD FILEOUT '//trim(f))
        call write_block_end(iu, 'OPTIONS')
        call wline(iu, '')
        call write_block_begin(iu, 'PERIOD 1')
        call wline(iu, repeat(' ',2)//'SAVE HEAD LAST')
        call write_block_end(iu, 'PERIOD')
        close(iu)
      end do
    else !TR
      f = trim(p)//trim(pr(ioc,irun0))//'.oc'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      f = trim(resultsbindir)//'/'//trim(this%modelname)//'.tr'//trim(pr(ioc,irun0))//'.hds'
      call wline(iu, repeat(' ',2)//'HEAD FILEOUT '//trim(f))
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      nperspu = raw%geti('nmonth_spinup')
      call write_block_begin(iu, 'PERIOD '//ta((/nperspu/)))
      call wline(iu, repeat(' ',2)//'SAVE HEAD LAST')
      call write_block_end(iu, 'PERIOD')
      close(iu)
      !
      f = trim(p)//'.oc'
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      f = trim(resultsbindir)//'/'//trim(this%modelname)//'.tr.hds'
      call wline(iu, repeat(' ',2)//'HEAD FILEOUT '//trim(f))
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      do iper = 1, raw%nper
        call write_block_begin(iu, 'PERIOD '//ta((/iper/)))
        call wline(iu, repeat(' ',2)//'SAVE HEAD LAST')
        call write_block_end(iu, 'PERIOD')
      end do
      close(iu)
    end if
    !
    return
  end subroutine mf6_mod_write_oc
  
  subroutine mf6_mod_write_npf(this, lbin, lbinpos)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    logical, intent(in) :: lbin
    logical, intent(in) :: lbinpos
    ! -- local
    character(len=mxslen) :: p, pb, f
    integer(i4b) :: iu, icelltype
! ------------------------------------------------------------------------------
    if (this%pckact(inpf) == 0) return
    !
    call clear_wrk()
    !
    p = trim(this%rootdir)//trim(this%modelname)
    if (lbin) then
      pb =  trim(this%bindir)//trim(this%modelname)
    else
      pb = p
    end if
    !
    f = trim(p)//'.npf'
    call open_file(f, iu, 'w')
    !
    call write_block_begin(iu, 'OPTIONS')
    call write_block_end(iu, 'OPTIONS')
    call wline(iu, '')
    call write_block_begin(iu, 'GRIDDATA')
    call wline(iu, repeat(' ',2)//'ICELLTYPE')
    icelltype = raw%geti('icelltype',idef=0)
    call wline(iu, repeat(' ',4)//'CONSTANT '//ta((/icelltype/)))
    call wline(iu, repeat(' ',2)//'K')
    call this%get_array(i_k, 1, 1, i1wrk, r8wrk) !i_k_l1
    if (gnlay == 2) call this%get_array(i_k, 2, 2, i1wrk, r8wrk) !i_k_l2
    f = trim(pb)//'.npf.k'; call this%write_array(iu, 4, f, r8wrk, lbin, lbinpos)
    call clear_wrk()
    call wline(iu, repeat(' ',2)//'K33')
    if (gnlay == 2) then
      call this%get_array(i_k33, 1, 1, i1wrk, r8wrk) !i_k33_l1
      call this%get_array(i_k33, 2, 2, i1wrk, r8wrk) !i_k33_l2
      f = trim(pb)//'.npf.k33'; call this%write_array(iu, 4, f, r8wrk, lbin, lbinpos)
    else
      call wline(iu, repeat(' ',4)//'CONSTANT 0.1')
    end if
    call clear_wrk()
    call write_block_end(iu, 'GRIDDATA')
    close(iu)
    !
    return
  end subroutine mf6_mod_write_npf
  
  subroutine mf6_mod_write_sto(this, lbin, lbinpos)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    logical, intent(in) :: lbin
    logical, intent(in) :: lbinpos
    ! -- local
    character(len=mxslen) :: p, pb, f
    integer(i4b) :: iu
! ------------------------------------------------------------------------------
    if (this%pckact(isto) == 0) return
    !
    call clear_wrk()
    !
    p = trim(this%rootdir)//trim(this%modelname)
    if (lbin) then
      pb =  trim(this%bindir)//trim(this%modelname)
    else
      pb = p
    end if
    !
    f = trim(p)//'.sto'
    call open_file(f, iu, 'w')
    !
    call write_block_begin(iu, 'OPTIONS')
    call wline(iu, repeat(' ',2)//'STORAGECOEFFICIENT')
    call write_block_end(iu, 'OPTIONS')
    call wline(iu, '')
    call write_block_begin(iu, 'GRIDDATA')
    call wline(iu, repeat(' ',2)//'ICONVERT')
    call wline(iu, repeat(' ',4)//'CONSTANT 0')
    call wline(iu, repeat(' ',2)//'SS')
    call this%get_array(i_prim_sto, 1, 1, i1wrk, r8wrk)
    call this%get_array(i_prim_sto, 2, 2, i1wrk, r8wrk)
    f = trim(pb)//'.sto.ps'; call this%write_array(iu, 4, f, r8wrk, lbin, lbinpos)
    call clear_wrk()
    call wline(iu, repeat(' ',2)//'SY')
    call wline(iu, repeat(' ',4)//'CONSTANT 0')
    call write_block_end(iu, 'GRIDDATA')
    !
    call wline(iu, '')
    call write_block_begin(iu, 'PERIOD 1')
    if (ltransient) then
      call wline(iu, repeat(' ',2)//'TRANSIENT')
    else
      call wline(iu, repeat(' ',2)//'STEADY-STATE')
    end if
    call write_block_end(iu, 'PERIOD')
    close(iu)
    !
    return
  end subroutine mf6_mod_write_sto
  
 subroutine mf6_mod_write_chd(this, lbin, lbinpos, ipack)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    logical, intent(in) :: lbin
    logical, intent(in) :: lbinpos
    integer(i4b), intent(in) :: ipack
    ! -- local
    character(len=mxslen) :: p, pb, f, chd_type, packstr
    integer(i4b) :: iu, maxbound, i, pack_ib_in
    integer(i8b) :: p0, p1
    integer(i4b), dimension(gnlay) :: nbound_lay
! ------------------------------------------------------------------------------
    if (this%pckact(ipack) == 0) return
    if (ltransient.and.(ipack == ichd2)) return
    !
    packstr = trim(pr(ipack,irun0ss))//'.chd' !.sea .intf
    if (ipack == ichd1) then
      pack_ib_in = 1
    elseif (ipack == ichd2) then
      pack_ib_in = 3
    end if
    !
    call clear_wrk()
    !
    p = trim(this%rootdir)//trim(this%modelname)
    if (lbin) then
      pb =  trim(this%bindir)//trim(this%modelname)
    else
      pb = p
    end if
    !
    call this%get_array(i_strt, 1, 1, i1wrk, r8wrk, ib_in=pack_ib_in) !i_strt_l1
    if (gnlay == 2) call this%get_array(i_strt, 2, 2, i1wrk, r8wrk, ib_in=pack_ib_in) !i_strt_l2
    nbound_lay = this%count_i1a(i1wrk); maxbound = sum(nbound_lay)
    !
    if (maxbound > 0) then
      f = trim(p)//trim(packstr)
      call open_file(f, iu, 'w')
      !
      call write_block_begin(iu, 'OPTIONS')
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'MAXBOUND '//ta((/maxbound/)))
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'PERIOD 1')
      if ((ipack == ichd1).and.(raw%geti('force_sea',idef=0) == 1)) then
        call logmsg('***** Forcing zero head sea-level! *****')
        do i = 1, size(r8wrk)
          r8wrk(i) = DZERO
        end do
      end if
      call this%write_records(1, sum(this%layer_nodes), i1wrk, reshape(r8wrk, (/1, size(r8wrk)/)), p0, p1)
      call wline(iu, '  OPEN/CLOSE '//trim(this%fbin)//' (BINARY) '//ta((/p0,p1/)))
      call write_block_end(iu, 'PERIOD')
      close(iu)
    end if
    call clear_wrk()
    !
    if (maxbound == 0) then
      call logmsg('No constant-head boundaries found: '//trim(pr(ipack,irun0ss)))
      this%pckact(ipack) = 0
      return
    end if
    !
    return
  end subroutine mf6_mod_write_chd
  
  subroutine mf6_mod_write_exchanges(this, ju)
! ******************************************************************************
! ******************************************************************************
!
!    SPECIFICATIONS:
! ------------------------------------------------------------------------------
!
    ! -- dummy
    class(tMf6_mod) :: this
    integer(i4b), intent(in) :: ju
    ! -- local
    character(len=mxslen) :: s, d, f, fexg, m1s, m2s
    integer(i4b) :: iu, ixch, iexg
    type(tExchange), pointer :: xch
! ------------------------------------------------------------------------------
    if (this%nxch == 0) return
    
    d = '../../models/run_input/exchanges/'
    call create_dir(d)
    
    do ixch = 1, this%nxch
      xch => this%xch(ixch)
      if (.not.xch%loutput) cycle !symmetric only
      !
      m1s = this%modelname
      m2s = xch%m2modelname
      !
      fexg = trim(m1s)//'-'//trim(m2s)//'.exg'
      !
      ! .exg file
      f = trim(d)//trim(fexg)
      call open_file(f, iu, 'w')
      call write_block_begin(iu, 'OPTIONS')
      if (raw%geti('exchange_newton',idef=0) == 1) then
        call wline(iu, repeat(' ',2)//'NEWTON')
      end if
      call write_block_end(iu, 'OPTIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'DIMENSIONS')
      call wline(iu, repeat(' ',2)//'NEXG '//ta((/xch%nexg/)))
      call write_block_end(iu, 'DIMENSIONS')
      call wline(iu, '')
      call write_block_begin(iu, 'EXCHANGEDATA')
      f = trim(d)//trim(fexg)//'.asc'
      call wline(iu, repeat(' ',2)//'OPEN/CLOSE '//trim(f))
      call write_block_end(iu, 'EXCHANGEDATA')
      close(iu)
      !
      ! .asc file
      f = trim(d)//trim(fexg)//'.asc'
      call open_file(f, iu, 'w')
      do iexg = 1, xch%nexg
        call wline(iu, ta((/xch%cellidm1(iexg), xch%cellidm2(iexg)/))//' 1 '//&
                        ta((/gcs/2, gcs/2, gcs/)))
      end do
      close(iu)
      !
      write(s,'(a,3(1x,a))') 'GWF6-GWF6',  trim(d)//trim(fexg), trim(m1s), trim(m2s)
      write(ju,'(a)') trim(s)
    end do
    !
    return
  end subroutine mf6_mod_write_exchanges
  
end module