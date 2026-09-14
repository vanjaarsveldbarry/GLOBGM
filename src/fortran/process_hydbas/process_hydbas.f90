program process_hydbas
  ! modules
  use utilsmod, only: mxslen, i4b, r4b, r8b, logmsg, ta, errmsg, &
    fillgap, fill_with_nearest, tBb, calc_unique
  use raster_io, only: raster_t, raster_open, raster_close, raster_read_all, raster_write

  implicit none

  ! ids pass through real(r4b); float32 is exact only below 2**24
  integer(i4b), parameter :: maxid_exact = 16777216

  type(raster_t) :: r
  type(tBb), pointer :: bb => null()
  type(tBb), dimension(:), pointer :: bba => null()
  !
  character(len=mxslen) :: fmask, fo, f
  logical :: lok
  integer(i4b) :: ic, ir, jc, jr, nc, nr, n, id, id2, maxid, i, ireg, nreg
  integer(i4b) :: nregin, mv, idmax, idoff, i4v
  integer(i4b), dimension(:), allocatable :: i4wk1d
  integer(i4b), dimension(:,:), allocatable :: i4wk2d, pid, regun
  integer(i4b), dimension(:,:), pointer :: i4reg => null()
  !
  real(r4b), dimension(:,:), pointer :: p => null()
  real(r4b), dimension(:,:), allocatable :: x
  real(r4b) :: mvp, mvx, r4v
  real(r8b) :: xll, yll, cs
! ------------------------------------------------------------------------------
  !
  ! arguments: <mask> <output> <region 1> ... <region n>; rasters are <name>.nc.
  ! Region order is id order: each region's ids are offset by the running
  ! maximum, so reordering the arguments renumbers every catchment.
  nregin = command_argument_count() - 2
  if (nregin < 1) then
    call errmsg('Usage: process_hydbas <mask> <output> <region 1> ... <region n>')
  end if
  call get_command_argument(1,fmask)
  call get_command_argument(2,fo)
  !
  ! merge the regions
  idoff = 0
  do i = 1, nregin
    call get_command_argument(i+2,f)
    call logmsg('Reading '//trim(f)//'.nc...')
    call raster_open(r, trim(f)//'.nc')
    call raster_read_all(r, i4reg); mv = int(r%nodata)
    call raster_close(r)
    !
    if (i == 1) then
      nc = size(i4reg,1); nr = size(i4reg,2)
      allocate(x(nc,nr))
      do ir = 1, nr
        do ic = 1, nc
          x(ic,ir) = 0.0
        end do
      end do
    else if ((size(i4reg,1) /= nc).or.(size(i4reg,2) /= nr)) then
      call errmsg('Invalid number of rows/cols for '//trim(f)//'.')
    end if
    !
    idmax = 0
    do ir = 1, nr
      do ic = 1, nc
        i4v = i4reg(ic,ir)
        if (i4v /= mv) then
          idmax = max(idmax, i4v)
          x(ic,ir) = real(i4v + idoff, r4b)
        end if
      end do
    end do
    call logmsg('Maximum ID: '//ta((/idmax/)))
    idoff = idoff + idmax
  end do
  deallocate(i4reg); i4reg => null()
  if (idoff > maxid_exact) then
    call errmsg('Merged ID '//ta((/idoff/))//' exceeds the float32 exact range.')
  end if
  mvx = 0.0
  !
  call raster_open(r, trim(fmask)//'.nc')
  call raster_read_all(r, p); mvp = real(r%nodata, r4b)
  xll = r%xmin; yll = r%ymin; cs = r%dx
  call raster_close(r)
  !
  if ((size(p,1) /= nc).or.(size(p,2) /= nr)) then
    call errmsg('Invalid number of rows/cols.')
  end if
  !
  n = 0
  do ir = 1, nr
    do ic = 1, nc
      if (p(ic,ir) /= mvp) then ! there should be a value
        if (x(ic,ir) == mvx) then
          n = n + 1
          x(ic,ir) = -1.0
        end if
      end if
    end do
  end do
  call logmsg('# gaps: '//ta((/n/)))
  !
  call fillgap(x, mvx, -1.0)
  call fill_with_nearest(x, mvx, -1.0)
  !
  ! check if all gaps are filled
  lok = .true.
  do ir = 1, nr
    do ic = 1, nc
      if (p(ic,ir) /= mvp) then
        if (x(ic,ir) == -1.0) then
          lok = .false.
        end if
      end if
    end do
  end do
  if (.not.lok) then
    do ir = 1, nr
      do ic = 1, nc
        if (x(ic,ir) /= mvx) then
          if (x(ic,ir) /= -1.0) then
            x(ic,ir) = 0.0
          end if
        end if
      end do
    end do
    call raster_write('error.nc', x, xll, yll, cs, 0.0)
    call errmsg('Not all gaps filled')
  end if
  !
  ! determine maximum ID
  maxid = 0
  do ir = 1, nr
    do ic = 1, nc
      r4v = x(ic,ir)
      if (r4v /= mvx) then
        id = int(r4v,i4b); maxid = max(maxid, id)
      end if
    end do
  end do
  call logmsg('Maximum ID: '//ta((/maxid/)))
  !
  ! label the ids
  allocate(i4wk1d(maxid))
  do i = 1, maxid
    i4wk1d(i) = 0
  end do
  !
  do ir = 1, nr
    do ic = 1, nc
      r4v = x(ic,ir)
      if (r4v /= mvx) then
        id = int(r4v,i4b)
        i4wk1d(id) = 1
      end if
    end do
  end do
  !
  ! renumber the ids
  n = 0
  do i = 1, maxid
    if (i4wk1d(i) == 1) then
      n = n + 1
      i4wk1d(i) = n
    end if
  end do
  call logmsg('# IDs: '//ta((/n/)))
  !
  ! convert
  allocate(i4wk2d(nc,nr))
  do ir = 1, nr
    do ic = 1, nc
      if (p(ic,ir) /= mvp) then
        r4v = x(ic,ir)
        id = int(r4v,i4b)
        i4wk2d(ic,ir) = i4wk1d(id)
      else
        i4wk2d(ic,ir) = 0
      end if
    end do
  end do
  deallocate(x, i4wk1d)
  deallocate(p); p => null()
  !
  ! determine the bounding boxes
  allocate(bba(n))
  do ir = 1, nr
    do ic = 1, nc
      id = i4wk2d(ic,ir)
      if (id /= 0) then
        bb => bba(id)
        bb%ic0 = min(bb%ic0,ic); bb%ic1 = max(bb%ic1,ic)
        bb%ir0 = min(bb%ir0,ir); bb%ir1 = max(bb%ir1,ir)
      end if
    end do
  end do
  do id = 1, n
    bb => bba(id)
    bb%ncol = bb%ic1 - bb%ic0 + 1
    bb%nrow = bb%ir1 - bb%ir0 + 1
  end do
  !
  ! determine the unique regions
  id2 = 0
  do id = 1, n
    bb => bba(id)
    if ((id == 1).or.(id == n).or.mod(id,max(n/10,1))==1) then
      call logmsg('Processing '//ta((/id/),'(i10.10)')//'/'//ta((/n/),'(i10.10)')//'...')
    end if
    if (allocated(pid)) deallocate(pid)
    allocate(pid(bb%ncol,bb%nrow))
    do ir = bb%ir0, bb%ir1
      do ic = bb%ic0, bb%ic1
        jr = ir - bb%ir0 + 1; jc = ic - bb%ic0 + 1
        if (i4wk2d(ic,ir) == id) then
          pid(jc,jr) = 1
        else
          pid(jc,jr) = 0
        end if
      end do
    end do
    call calc_unique(pid, regun, nreg)
    do ireg = 1, nreg
      id2 = id2 + 1
      do ir = bb%ir0, bb%ir1
        do ic = bb%ic0, bb%ic1
          jr = ir - bb%ir0 + 1; jc = ic - bb%ic0 + 1
          if (regun(jc,jr) == ireg) then
            i4wk2d(ic,ir) = -id2
          end if
        end do
      end do
    end do
  end do
  call logmsg('# IDs final: '//ta((/id2/)))
  !
  do ir = 1, nr
    do ic = 1, nc
      i4wk2d(ic,ir) = abs(i4wk2d(ic,ir))
    end do
  end do
  !
  call raster_write(trim(fo)//'.nc', i4wk2d, xll, yll, cs, 0)
  !
end program
