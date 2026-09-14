module raster_io
! ******************************************************************************
! The single raster I/O module of the modernised GLOBGM tools (design.md,
! "Rasters are NetCDF"). Replaces iMOD IDF (idfread/readidf_block/writeidf),
! PCRaster .map (tMap) and ESRI .flt (readflt/writeflt).
!
! File layout (written by src/python/globgm_raster.py):
!   dims (lat, lon), row 1 = north; one data variable "data" of int32 /
!   float32 / float64 with _FillValue = the legacy nodata value; global
!   attributes xmin ymin xmax ymax dx dy (float64) taken verbatim from the
!   legacy header. A monthly field carries a leading (time) dimension and a
!   "time" coordinate ("<unit> since <date>"); r%nt > 0 then, and every
!   read of it must name the time index.
!
! In-memory convention: arr(ncol,nrow), arr(ic,ir), row 1 = north -- the same
! as the retired idf%x, so call sites keep their loops.
!
! Values are read in the file's native type and converted here with
! int()/real(), so truncation matches the reference exactly; a nodata cell
! holds the converted _FillValue, and callers test against r%nodata converted
! the same way. NaN is never produced.
!
! Every netCDF call is checked; any failure is a hard error naming the file
! and the call. No retry, no sleep (retires the iMOD "keeps trying to find"
! infinite loop).
! ******************************************************************************
  use, intrinsic :: iso_fortran_env, only: error_unit, &
    i4b => int32, r4b => real32, r8b => real64
  use netcdf
  implicit none
  private

  character(len=*), parameter :: data_var = 'data'

  type, public :: raster_t
    integer(i4b) :: ncid = -1
    integer(i4b) :: varid = -1
    integer(i4b) :: ncol = 0
    integer(i4b) :: nrow = 0
    real(r8b) :: xmin = 0.d0, ymin = 0.d0, xmax = 0.d0, ymax = 0.d0
    real(r8b) :: dx = 0.d0, dy = 0.d0
    real(r8b) :: nodata = 0.d0
    integer(i4b) :: nt = 0 ! 0: no time dimension
    integer(i4b) :: xtype = 0 ! NF90_INT / NF90_FLOAT / NF90_DOUBLE
    character(len=:), allocatable :: fname
  end type raster_t

  interface raster_read_block
    module procedure :: raster_read_block_i4
    module procedure :: raster_read_block_r4
  end interface raster_read_block

  interface raster_read_all
    module procedure :: raster_read_all_i4
    module procedure :: raster_read_all_r4
    module procedure :: raster_read_all_r8
  end interface raster_read_all

  interface raster_write
    module procedure :: raster_write_i4
    module procedure :: raster_write_r4
  end interface raster_write

  public :: raster_open, raster_close, raster_read_block, raster_read_all, raster_write
  public :: raster_time

contains

  ! ----------------------------------------------------------------------------
  subroutine raster_fatal(msg, fname)
    character(len=*), intent(in) :: msg
    character(len=*), intent(in), optional :: fname
    if (present(fname)) then
      write(error_unit,'(a)') 'Error (raster_io): '//trim(msg)//' ['//trim(fname)//']'
    else
      write(error_unit,'(a)') 'Error (raster_io): '//trim(msg)
    end if
    flush(error_unit)
    error stop 1
  end subroutine raster_fatal

  subroutine nc_check(status, what, fname)
    integer(i4b), intent(in) :: status
    character(len=*), intent(in) :: what
    character(len=*), intent(in) :: fname
    if (status /= NF90_NOERR) then
      call raster_fatal(trim(what)//': '//trim(nf90_strerror(status)), fname)
    end if
  end subroutine nc_check

  logical function raster_is_open(r)
    type(raster_t), intent(in) :: r
    raster_is_open = (r%ncid >= 0)
  end function raster_is_open

  ! ----------------------------------------------------------------------------
  subroutine raster_open(r, fname)
    ! Open header only. Hard error if the file is missing or malformed.
    type(raster_t), intent(inout) :: r
    character(len=*), intent(in) :: fname
    ! -- local
    logical :: lex
    integer(i4b) :: ncid, varid, ndims, xtype
    integer(i4b), dimension(3) :: dimids
    real(r8b) :: r8v
    real(r4b) :: r4v
    integer(i4b) :: i4v
    ! ----
    if (raster_is_open(r)) call raster_close(r)
    !
    inquire(file=trim(fname), exist=lex)
    if (.not.lex) call raster_fatal('file does not exist', fname)
    !
    call nc_check(nf90_open(trim(fname), NF90_NOWRITE, ncid), 'nf90_open', fname)
    r%ncid = ncid
    r%fname = trim(fname)
    !
    call nc_check(nf90_inq_varid(ncid, data_var, varid), 'inq_varid(data)', fname)
    r%varid = varid
    !
    call nc_check(nf90_inquire_variable(ncid, varid, xtype=xtype, ndims=ndims), &
      'nf90_inquire_variable', fname)
    if ((ndims /= 2).and.(ndims /= 3)) call raster_fatal('data variable is not 2-D or 3-D', fname)
    call nc_check(nf90_inquire_variable(ncid, varid, dimids=dimids(1:ndims)), &
      'nf90_inquire_variable(dimids)', fname)
    ! Fortran dimension order is the reverse of the file's (time, lat, lon):
    ! dimids(1) = lon (fastest), dimids(2) = lat, dimids(3) = time.
    call nc_check(nf90_inquire_dimension(ncid, dimids(1), len=r%ncol), &
      'nf90_inquire_dimension(lon)', fname)
    call nc_check(nf90_inquire_dimension(ncid, dimids(2), len=r%nrow), &
      'nf90_inquire_dimension(lat)', fname)
    r%nt = 0
    if (ndims == 3) then
      call nc_check(nf90_inquire_dimension(ncid, dimids(3), len=r%nt), &
        'nf90_inquire_dimension(time)', fname)
    end if
    !
    select case (xtype)
    case (NF90_INT, NF90_FLOAT, NF90_DOUBLE)
      r%xtype = xtype
    case default
      call raster_fatal('unsupported data type (expect int32/float32/float64)', fname)
    end select
    !
    ! geometry: verbatim float64 attributes, never reconstructed from centres
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'xmin', r%xmin), 'get_att(xmin)', fname)
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'ymin', r%ymin), 'get_att(ymin)', fname)
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'xmax', r%xmax), 'get_att(xmax)', fname)
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'ymax', r%ymax), 'get_att(ymax)', fname)
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'dx',   r%dx),   'get_att(dx)',   fname)
    call nc_check(nf90_get_att(ncid, NF90_GLOBAL, 'dy',   r%dy),   'get_att(dy)',   fname)
    !
    ! nodata: read in the file's own type and promote, exactly as the legacy
    ! reader stored a float32 header nodata into a real(8) field.
    select case (r%xtype)
    case (NF90_INT)
      call nc_check(nf90_get_att(ncid, varid, '_FillValue', i4v), 'get_att(_FillValue)', fname)
      r%nodata = real(i4v, r8b)
    case (NF90_FLOAT)
      call nc_check(nf90_get_att(ncid, varid, '_FillValue', r4v), 'get_att(_FillValue)', fname)
      r%nodata = real(r4v, r8b)
    case (NF90_DOUBLE)
      call nc_check(nf90_get_att(ncid, varid, '_FillValue', r8v), 'get_att(_FillValue)', fname)
      r%nodata = r8v
    end select
    !
    return
  end subroutine raster_open

  subroutine raster_close(r)
    type(raster_t), intent(inout) :: r
    if (r%ncid >= 0) then
      call nc_check(nf90_close(r%ncid), 'nf90_close', r%fname)
    end if
    r%ncid = -1; r%varid = -1
    r%ncol = 0; r%nrow = 0; r%nt = 0
    if (allocated(r%fname)) deallocate(r%fname)
    return
  end subroutine raster_close

  ! ----------------------------------------------------------------------------
  subroutine check_window(r, ir0, ir1, ic0, ic1)
    type(raster_t), intent(in) :: r
    integer(i4b), intent(in) :: ir0, ir1, ic0, ic1
    character(len=256) :: s
    if (.not.raster_is_open(r)) call raster_fatal('raster not open')
    if ((ir0 < 1).or.(ir1 > r%nrow).or.(ir0 > ir1).or. &
        (ic0 < 1).or.(ic1 > r%ncol).or.(ic0 > ic1)) then
      write(s,'(a,4(i0,a),2(i0,a))') 'window (ir0,ir1,ic0,ic1)=(', &
        ir0, ',', ir1, ',', ic0, ',', ic1, ') outside raster (', r%nrow, ' rows, ', r%ncol, ' cols)'
      call raster_fatal(trim(s), r%fname)
    end if
  end subroutine check_window

  subroutine read_native_r8(r, ir0, ir1, ic0, ic1, buf, it)
    ! One hyperslab read in the file's native type, promoted to real(8).
    type(raster_t), intent(in) :: r
    integer(i4b), intent(in) :: ir0, ir1, ic0, ic1
    real(r8b), dimension(:,:), allocatable, intent(out) :: buf
    integer(i4b), intent(in), optional :: it
    ! -- local
    integer(i4b) :: nc, nr
    integer(i4b), dimension(3) :: start, cnt
    integer(i4b), dimension(:,:), allocatable :: i4buf
    real(r4b), dimension(:,:), allocatable :: r4buf
    character(len=256) :: s
    ! ----
    call check_window(r, ir0, ir1, ic0, ic1)
    nc = ic1-ic0+1; nr = ir1-ir0+1
    start = (/ic0, ir0, 1/); cnt = (/nc, nr, 1/)
    if (present(it)) then
      if (r%nt == 0) call raster_fatal('time index given for a raster without time', r%fname)
      if ((it < 1).or.(it > r%nt)) then
        write(s,'(a,i0,a,i0,a)') 'time index ', it, ' outside 1..', r%nt
        call raster_fatal(trim(s), r%fname)
      end if
      start(3) = it
    else if (r%nt > 0) then
      call raster_fatal('raster has a time dimension; a time index is required', r%fname)
    end if
    allocate(buf(nc,nr))
    select case (r%xtype)
    case (NF90_INT)
      allocate(i4buf(nc,nr))
      call nc_check(nf90_get_var(r%ncid, r%varid, i4buf, start=start, count=cnt), &
        'nf90_get_var(int32)', r%fname)
      buf = real(i4buf, r8b)
      deallocate(i4buf)
    case (NF90_FLOAT)
      allocate(r4buf(nc,nr))
      call nc_check(nf90_get_var(r%ncid, r%varid, r4buf, start=start, count=cnt), &
        'nf90_get_var(float32)', r%fname)
      buf = real(r4buf, r8b)
      deallocate(r4buf)
    case (NF90_DOUBLE)
      call nc_check(nf90_get_var(r%ncid, r%varid, buf, start=start, count=cnt), &
        'nf90_get_var(float64)', r%fname)
    end select
    return
  end subroutine read_native_r8

  ! --- windowed reads -----------------------------------------------------------
  subroutine raster_read_block_i4(r, ir0, ir1, ic0, ic1, arr)
    type(raster_t), intent(in) :: r
    integer(i4b), intent(in) :: ir0, ir1, ic0, ic1
    integer(i4b), dimension(:,:), pointer, intent(inout) :: arr
    ! -- local
    real(r8b), dimension(:,:), allocatable :: buf
    integer(i4b) :: nc, nr, ic, ir
    ! ----
    call read_native_r8(r, ir0, ir1, ic0, ic1, buf)
    nc = size(buf,1); nr = size(buf,2)
    if (associated(arr)) deallocate(arr)
    allocate(arr(nc,nr))
    do ir = 1, nr
      do ic = 1, nc
        arr(ic,ir) = int(buf(ic,ir))
      end do
    end do
    return
  end subroutine raster_read_block_i4

  subroutine raster_read_block_r4(r, ir0, ir1, ic0, ic1, arr, it)
    type(raster_t), intent(in) :: r
    integer(i4b), intent(in) :: ir0, ir1, ic0, ic1
    real(r4b), dimension(:,:), pointer, intent(inout) :: arr
    integer(i4b), intent(in), optional :: it
    ! -- local
    real(r8b), dimension(:,:), allocatable :: buf
    integer(i4b) :: nc, nr, ic, ir
    ! ----
    call read_native_r8(r, ir0, ir1, ic0, ic1, buf, it)
    nc = size(buf,1); nr = size(buf,2)
    if (associated(arr)) deallocate(arr)
    allocate(arr(nc,nr))
    do ir = 1, nr
      do ic = 1, nc
        arr(ic,ir) = real(buf(ic,ir), r4b)
      end do
    end do
    return
  end subroutine raster_read_block_r4

  ! --- full reads ---------------------------------------------------------------
  subroutine raster_read_all_i4(r, arr)
    type(raster_t), intent(in) :: r
    integer(i4b), dimension(:,:), pointer, intent(inout) :: arr
    real(r8b), dimension(:,:), allocatable :: buf
    integer(i4b) :: ic, ir
    if (associated(arr)) deallocate(arr)
    allocate(arr(r%ncol, r%nrow))
    if (r%xtype == NF90_INT) then
      call nc_check(nf90_get_var(r%ncid, r%varid, arr), 'nf90_get_var(int32)', r%fname)
      return
    end if
    call read_native_r8(r, 1, r%nrow, 1, r%ncol, buf)
    do ir = 1, r%nrow
      do ic = 1, r%ncol
        arr(ic,ir) = int(buf(ic,ir), i4b)
      end do
    end do
    return
  end subroutine raster_read_all_i4

  subroutine raster_read_all_r4(r, arr)
    type(raster_t), intent(in) :: r
    real(r4b), dimension(:,:), pointer, intent(inout) :: arr
    real(r8b), dimension(:,:), allocatable :: buf
    integer(i4b) :: ic, ir
    if (associated(arr)) deallocate(arr)
    allocate(arr(r%ncol, r%nrow))
    if (r%xtype == NF90_FLOAT) then
      call nc_check(nf90_get_var(r%ncid, r%varid, arr), 'nf90_get_var(float32)', r%fname)
      return
    end if
    call read_native_r8(r, 1, r%nrow, 1, r%ncol, buf)
    do ir = 1, r%nrow
      do ic = 1, r%ncol
        arr(ic,ir) = real(buf(ic,ir), r4b)
      end do
    end do
    return
  end subroutine raster_read_all_r4

  subroutine raster_read_all_r8(r, arr)
    type(raster_t), intent(in) :: r
    real(r8b), dimension(:,:), pointer, intent(inout) :: arr
    real(r8b), dimension(:,:), allocatable :: buf
    call read_native_r8(r, 1, r%nrow, 1, r%ncol, buf)
    if (associated(arr)) deallocate(arr)
    allocate(arr(r%ncol, r%nrow))
    arr = buf
    return
  end subroutine raster_read_all_r8

  ! --- time axis --------------------------------------------------------------
  subroutine raster_time(r, it, tval, units)
    ! Value it of the "time" coordinate and its units attribute.
    type(raster_t), intent(in) :: r
    integer(i4b), intent(in) :: it
    real(r8b), intent(out) :: tval
    character(len=*), intent(out) :: units
    integer(i4b) :: varid
    real(r8b), dimension(1) :: v
    if (r%nt == 0) call raster_fatal('raster has no time dimension', r%fname)
    if ((it < 1).or.(it > r%nt)) call raster_fatal('time index out of range', r%fname)
    call nc_check(nf90_inq_varid(r%ncid, 'time', varid), 'inq_varid(time)', r%fname)
    call nc_check(nf90_get_var(r%ncid, varid, v, start=(/it/), count=(/1/)), &
      'nf90_get_var(time)', r%fname)
    tval = v(1)
    units = ''
    call nc_check(nf90_get_att(r%ncid, varid, 'units', units), 'get_att(time:units)', r%fname)
    return
  end subroutine raster_time

  ! --- write ------------------------------------------------------------------
  subroutine write_skeleton(fname, ncol, nrow, xll, yll, cs, xtype, ncid, varid)
    character(len=*), intent(in) :: fname
    integer(i4b), intent(in) :: ncol, nrow, xtype
    real(r8b), intent(in) :: xll, yll, cs
    integer(i4b), intent(out) :: ncid, varid
    ! -- local
    integer(i4b) :: dlat, dlon, vlat, vlon
    real(r8b) :: xmax, ymax
    ! ----
    xmax = xll + ncol*cs; ymax = yll + nrow*cs
    call nc_check(nf90_create(trim(fname), ior(NF90_CLOBBER, NF90_NETCDF4), ncid), 'nf90_create', fname)
    call nc_check(nf90_def_dim(ncid, 'lat', nrow, dlat), 'def_dim(lat)', fname)
    call nc_check(nf90_def_dim(ncid, 'lon', ncol, dlon), 'def_dim(lon)', fname)
    call nc_check(nf90_def_var(ncid, 'lat', NF90_DOUBLE, (/dlat/), vlat), 'def_var(lat)', fname)
    call nc_check(nf90_def_var(ncid, 'lon', NF90_DOUBLE, (/dlon/), vlon), 'def_var(lon)', fname)
    call nc_check(nf90_put_att(ncid, vlat, 'units', 'degrees_north'), 'put_att', fname)
    call nc_check(nf90_put_att(ncid, vlon, 'units', 'degrees_east'), 'put_att', fname)
    call nc_check(nf90_def_var(ncid, data_var, xtype, (/dlon, dlat/), varid, &
      chunksizes=(/min(256,ncol), min(256,nrow)/), deflate_level=1), 'def_var(data)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'xmin', xll),  'put_att(xmin)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'ymin', yll),  'put_att(ymin)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'xmax', xmax), 'put_att(xmax)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'ymax', ymax), 'put_att(ymax)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'dx',   cs),   'put_att(dx)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'dy',   cs),   'put_att(dy)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'nrow', nrow), 'put_att(nrow)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'ncol', ncol), 'put_att(ncol)', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'Conventions', 'CF-1.8'), 'put_att', fname)
    call nc_check(nf90_put_att(ncid, NF90_GLOBAL, 'source', 'raster_io.f90'), 'put_att', fname)
    ! (_FillValue is added by the caller before enddef; coords by write_coords)
    return
  end subroutine write_skeleton

  subroutine write_coords(ncid, fname, ncol, nrow, xll, yll, cs)
    integer(i4b), intent(in) :: ncid, ncol, nrow
    character(len=*), intent(in) :: fname
    real(r8b), intent(in) :: xll, yll, cs
    integer(i4b) :: vlat, vlon, i
    real(r8b), dimension(:), allocatable :: lat, lon
    allocate(lat(nrow), lon(ncol))
    do i = 1, ncol
      lon(i) = xll + (real(i,r8b)-0.5d0)*cs
    end do
    do i = 1, nrow
      lat(i) = (yll + nrow*cs) - (real(i,r8b)-0.5d0)*cs
    end do
    call nc_check(nf90_inq_varid(ncid, 'lat', vlat), 'inq_varid(lat)', fname)
    call nc_check(nf90_inq_varid(ncid, 'lon', vlon), 'inq_varid(lon)', fname)
    call nc_check(nf90_put_var(ncid, vlat, lat), 'put_var(lat)', fname)
    call nc_check(nf90_put_var(ncid, vlon, lon), 'put_var(lon)', fname)
    return
  end subroutine write_coords

  subroutine raster_write_i4(fname, arr, xll, yll, cs, nodata)
    character(len=*), intent(in) :: fname
    integer(i4b), dimension(:,:), intent(in) :: arr
    real(r8b), intent(in) :: xll, yll, cs
    integer(i4b), intent(in) :: nodata
    integer(i4b) :: ncid, varid, ncol, nrow
    ncol = size(arr,1); nrow = size(arr,2)
    call write_skeleton(fname, ncol, nrow, xll, yll, cs, NF90_INT, ncid, varid)
    call nc_check(nf90_put_att(ncid, varid, '_FillValue', nodata), 'put_att(_FillValue)', fname)
    call nc_check(nf90_enddef(ncid), 'nf90_enddef', fname)
    call write_coords(ncid, fname, ncol, nrow, xll, yll, cs)
    call nc_check(nf90_put_var(ncid, varid, arr), 'put_var(data)', fname)
    call nc_check(nf90_close(ncid), 'nf90_close', fname)
    return
  end subroutine raster_write_i4

  subroutine raster_write_r4(fname, arr, xll, yll, cs, nodata)
    character(len=*), intent(in) :: fname
    real(r4b), dimension(:,:), intent(in) :: arr
    real(r8b), intent(in) :: xll, yll, cs
    real(r4b), intent(in) :: nodata
    integer(i4b) :: ncid, varid, ncol, nrow
    ncol = size(arr,1); nrow = size(arr,2)
    call write_skeleton(fname, ncol, nrow, xll, yll, cs, NF90_FLOAT, ncid, varid)
    call nc_check(nf90_put_att(ncid, varid, '_FillValue', nodata), 'put_att(_FillValue)', fname)
    call nc_check(nf90_enddef(ncid), 'nf90_enddef', fname)
    call write_coords(ncid, fname, ncol, nrow, xll, yll, cs)
    call nc_check(nf90_put_var(ncid, varid, arr), 'put_var(data)', fname)
    call nc_check(nf90_close(ncid), 'nf90_close', fname)
    return
  end subroutine raster_write_r4

end module raster_io
