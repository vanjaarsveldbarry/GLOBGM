! ==============================================================================
! Chunked netCDF-4 rasters compressed and decompressed on the OpenMP team.
!
! HDF5 serialises every call behind one lock, so nf90_get_var inflates a
! whole slice on one thread and nf90_put_var deflates one on one thread. Here
! the raw chunks go through H5Dread_chunk / H5Dwrite_chunk (fast, still under
! the lock) and the inflate/unshuffle and shuffle/deflate run as tasks, one
! chunk each. Only netCDF-4's own pipeline is handled, chunked and deflated
! with or without shuffle: the reader returns .false. for anything else and
! the caller falls back to nf90_get_var; the writer refuses.
! ==============================================================================
module chunk_io
  use, intrinsic :: iso_c_binding
  use, intrinsic :: iso_fortran_env, only: i4b => int32, r4b => real32, r8b => real64
  use utilsmod, only: errmsg, ta
  implicit none
  private
  public :: read_slice_chunks, write_raster_chunks

  integer(c_int64_t), parameter :: H5P_DEFAULT = 0
  integer(c_int),     parameter :: H5F_ACC_RDONLY = 0
  integer(c_int),     parameter :: H5F_ACC_RDWR = 1
  integer(c_int),     parameter :: H5D_CHUNKED = 2
  integer(c_int),     parameter :: H5T_INTEGER = 0
  integer(c_int),     parameter :: H5T_FLOAT = 1
  integer(c_int),     parameter :: H5Z_FILTER_DEFLATE = 1
  integer(c_int),     parameter :: H5Z_FILTER_SHUFFLE = 2

  ! the property-list class ids are library globals, valid after H5open; the
  ! variable must be public or gfortran gives it internal linkage and it
  ! never binds to the library's
  integer(c_int64_t), bind(C, name='H5P_CLS_FILE_ACCESS_ID_g') :: H5P_CLS_FILE_ACCESS_ID_g
  public :: H5P_CLS_FILE_ACCESS_ID_g

  interface
    function H5open() bind(C, name='H5open') result(err)
      import
      integer(c_int) :: err
    end function H5open
    function h5eset_auto2(estack, func, cdata) bind(C, name='H5Eset_auto2') result(err)
      import
      integer(c_int64_t), value :: estack
      type(c_funptr), value :: func
      type(c_ptr), value :: cdata
      integer(c_int) :: err
    end function h5eset_auto2
    function H5Pcreate(cls) bind(C, name='H5Pcreate') result(id)
      import
      integer(c_int64_t), value :: cls
      integer(c_int64_t) :: id
    end function H5Pcreate
    function H5Pset_fclose_degree(fapl, degree) bind(C, name='H5Pset_fclose_degree') result(err)
      import
      integer(c_int64_t), value :: fapl
      integer(c_int), value :: degree
      integer(c_int) :: err
    end function H5Pset_fclose_degree
    function H5Fopen(name, flags, fapl) bind(C, name='H5Fopen') result(id)
      import
      character(kind=c_char), dimension(*) :: name
      integer(c_int), value :: flags
      integer(c_int64_t), value :: fapl
      integer(c_int64_t) :: id
    end function H5Fopen
    function H5Fclose(id) bind(C, name='H5Fclose') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int) :: err
    end function H5Fclose
    function H5Dopen2(loc, name, dapl) bind(C, name='H5Dopen2') result(id)
      import
      integer(c_int64_t), value :: loc
      character(kind=c_char), dimension(*) :: name
      integer(c_int64_t), value :: dapl
      integer(c_int64_t) :: id
    end function H5Dopen2
    function H5Dclose(id) bind(C, name='H5Dclose') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int) :: err
    end function H5Dclose
    function H5Dget_create_plist(id) bind(C, name='H5Dget_create_plist') result(pid)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t) :: pid
    end function H5Dget_create_plist
    function H5Pclose(id) bind(C, name='H5Pclose') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int) :: err
    end function H5Pclose
    function H5Pget_layout(pid) bind(C, name='H5Pget_layout') result(layout)
      import
      integer(c_int64_t), value :: pid
      integer(c_int) :: layout
    end function H5Pget_layout
    function H5Pget_chunk(pid, maxdims, dims) bind(C, name='H5Pget_chunk') result(ndims)
      import
      integer(c_int64_t), value :: pid
      integer(c_int), value :: maxdims
      integer(c_int64_t), dimension(*) :: dims
      integer(c_int) :: ndims
    end function H5Pget_chunk
    function H5Pget_nfilters(pid) bind(C, name='H5Pget_nfilters') result(n)
      import
      integer(c_int64_t), value :: pid
      integer(c_int) :: n
    end function H5Pget_nfilters
    function H5Pget_filter2(pid, idx, flags, cd_nelmts, cd_values, namelen, name, config) &
      bind(C, name='H5Pget_filter2') result(fid)
      import
      integer(c_int64_t), value :: pid
      integer(c_int), value :: idx
      integer(c_int) :: flags
      integer(c_size_t) :: cd_nelmts
      integer(c_int), dimension(*) :: cd_values
      integer(c_size_t), value :: namelen
      character(kind=c_char), dimension(*) :: name
      integer(c_int) :: config
      integer(c_int) :: fid
    end function H5Pget_filter2
    function H5Dget_space(id) bind(C, name='H5Dget_space') result(sid)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t) :: sid
    end function H5Dget_space
    function H5Sclose(id) bind(C, name='H5Sclose') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int) :: err
    end function H5Sclose
    function H5Sget_simple_extent_ndims(sid) bind(C, name='H5Sget_simple_extent_ndims') result(n)
      import
      integer(c_int64_t), value :: sid
      integer(c_int) :: n
    end function H5Sget_simple_extent_ndims
    function H5Sget_simple_extent_dims(sid, dims, maxdims) bind(C, name='H5Sget_simple_extent_dims') result(n)
      import
      integer(c_int64_t), value :: sid
      integer(c_int64_t), dimension(*) :: dims
      type(c_ptr), value :: maxdims
      integer(c_int) :: n
    end function H5Sget_simple_extent_dims
    function H5Dget_type(id) bind(C, name='H5Dget_type') result(tid)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t) :: tid
    end function H5Dget_type
    function H5Tclose(id) bind(C, name='H5Tclose') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int) :: err
    end function H5Tclose
    function H5Tget_size(tid) bind(C, name='H5Tget_size') result(sz)
      import
      integer(c_int64_t), value :: tid
      integer(c_size_t) :: sz
    end function H5Tget_size
    function H5Tget_class(tid) bind(C, name='H5Tget_class') result(cls)
      import
      integer(c_int64_t), value :: tid
      integer(c_int) :: cls
    end function H5Tget_class
    function H5Dget_chunk_storage_size(id, offset, nbytes) bind(C, name='H5Dget_chunk_storage_size') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t), dimension(*) :: offset
      integer(c_int64_t) :: nbytes
      integer(c_int) :: err
    end function H5Dget_chunk_storage_size
    ! H5Dread_chunk2 (HDF5 1.14.3+, the default behind the H5Dread_chunk macro)
    function H5Dread_chunk(id, dxpl, offset, filters, buf, bufsize) bind(C, name='H5Dread_chunk2') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t), value :: dxpl
      integer(c_int64_t), dimension(*) :: offset
      integer(c_int32_t) :: filters
      integer(c_int8_t), dimension(*) :: buf
      integer(c_size_t) :: bufsize
      integer(c_int) :: err
    end function H5Dread_chunk
    function H5Dwrite_chunk(id, dxpl, filters, offset, nbytes, buf) bind(C, name='H5Dwrite_chunk') result(err)
      import
      integer(c_int64_t), value :: id
      integer(c_int64_t), value :: dxpl
      integer(c_int32_t), value :: filters
      integer(c_int64_t), dimension(*) :: offset
      integer(c_size_t), value :: nbytes
      integer(c_int8_t), dimension(*) :: buf
      integer(c_int) :: err
    end function H5Dwrite_chunk
    function uncompress(dest, destlen, source, sourcelen) bind(C, name='uncompress') result(rc)
      import
      integer(c_int8_t), dimension(*) :: dest
      integer(c_long) :: destlen
      integer(c_int8_t), dimension(*) :: source
      integer(c_long), value :: sourcelen
      integer(c_int) :: rc
    end function uncompress
    function compress2(dest, destlen, source, sourcelen, level) bind(C, name='compress2') result(rc)
      import
      integer(c_int8_t), dimension(*) :: dest
      integer(c_long) :: destlen
      integer(c_int8_t), dimension(*) :: source
      integer(c_long), value :: sourcelen
      integer(c_int), value :: level
      integer(c_int) :: rc
    end function compress2
    function compressBound(sourcelen) bind(C, name='compressBound') result(n)
      import
      integer(c_long), value :: sourcelen
      integer(c_long) :: n
    end function compressBound
  end interface

  ! what open_dataset learned about a variable
  type tLayout
    integer(c_int64_t) :: fid = -1, did = -1
    integer(c_int) :: nd = 0, tclass = -1, level = 0
    integer(c_size_t) :: tsize = 0
    integer(c_int64_t), dimension(3) :: dims = 0, cdims = 1
    logical :: lpipe = .false.     ! chunked, deflate, optionally shuffle first
    logical :: lshuffle = .false.
  end type tLayout

  type tBytes
    integer(c_int8_t), dimension(:), allocatable :: b
    integer(c_long) :: n = 0
  end type tBytes

contains

  subroutine open_dataset(fname, varname, flags, lay)
    ! Open file and variable and read the storage layout. netCDF may have the
    ! file open already; a second open must use the same close degree, which
    ! its version decides, so try them, quietly.
    character(len=*), intent(in) :: fname, varname
    integer(c_int), intent(in) :: flags
    type(tLayout), intent(out) :: lay
    ! -- local
    integer(c_int64_t) :: fapl, pid, sid, tid
    integer(c_int) :: err, degree, flg, config, fid1, fid2, nf
    integer(c_size_t) :: nelm
    integer(c_int), dimension(8) :: cdv
    character(kind=c_char), dimension(1) :: cname
! ------------------------------------------------------------------------------
    err = H5open()
    err = h5eset_auto2(0_c_int64_t, c_null_funptr, c_null_ptr)
    do degree = 1, 3
      fapl = H5Pcreate(H5P_CLS_FILE_ACCESS_ID_g)
      if (fapl < 0) call errmsg('H5Pcreate(H5P_FILE_ACCESS) failed')
      err = H5Pset_fclose_degree(fapl, degree)
      lay%fid = H5Fopen(trim(fname)//c_null_char, flags, fapl)
      err = H5Pclose(fapl)
      if (lay%fid >= 0) exit
    end do
    if (lay%fid < 0) call errmsg('HDF5 cannot open '//trim(fname))
    lay%did = H5Dopen2(lay%fid, trim(varname)//c_null_char, H5P_DEFAULT)
    if (lay%did < 0) call errmsg('HDF5 cannot open variable '//trim(varname)//' of '//trim(fname))
    !
    tid = H5Dget_type(lay%did)
    lay%tclass = H5Tget_class(tid); lay%tsize = H5Tget_size(tid)
    err = H5Tclose(tid)
    sid = H5Dget_space(lay%did)
    lay%nd = H5Sget_simple_extent_ndims(sid)
    err = H5Sget_simple_extent_dims(sid, lay%dims, c_null_ptr)
    err = H5Sclose(sid)
    pid = H5Dget_create_plist(lay%did)
    nf = H5Pget_nfilters(pid)
    if ((H5Pget_layout(pid) == H5D_CHUNKED).and.((nf == 1).or.(nf == 2))) then
      err = H5Pget_chunk(pid, 3_c_int, lay%cdims)
      nelm = 8
      fid1 = H5Pget_filter2(pid, 0_c_int, flg, nelm, cdv, 0_c_size_t, cname, config)
      if (nf == 2) then
        nelm = 8
        fid2 = H5Pget_filter2(pid, 1_c_int, flg, nelm, cdv, 0_c_size_t, cname, config)
        lay%lpipe = (fid1 == H5Z_FILTER_SHUFFLE).and.(fid2 == H5Z_FILTER_DEFLATE)
        lay%lshuffle = .true.
      else
        lay%lpipe = (fid1 == H5Z_FILTER_DEFLATE)
      end if
      lay%level = cdv(1)
    end if
    err = H5Pclose(pid)
    !
    return
  end subroutine open_dataset

  subroutine close_dataset(lay)
    type(tLayout), intent(inout) :: lay
    integer(c_int) :: err
    err = H5Dclose(lay%did); err = H5Fclose(lay%fid)
    lay%did = -1; lay%fid = -1
    return
  end subroutine close_dataset

  function read_slice_chunks(fname, varname, it, nodata, a) result(ok)
    ! Slice it (1-based; 0 for a raster without time axis) of variable varname
    ! into a(ncol,nrow), allocated here. .false. when the layout is not the
    ! chunked shuffle+deflate float32 one.
    character(len=*), intent(in) :: fname, varname
    integer(i4b), intent(in) :: it
    real(r8b), intent(in) :: nodata
    real(r4b), dimension(:,:), pointer, intent(inout) :: a
    logical :: ok
    ! -- local
    type(tLayout) :: lay
    integer(c_int64_t), dimension(3) :: off
    integer(c_int64_t) :: nbytes, tot
    integer(c_int64_t), dimension(:), allocatable :: csize, coff
    integer(c_int8_t), dimension(:), allocatable :: cbuf
    integer(c_int32_t) :: fmask
    integer(c_int) :: err
    integer(c_size_t) :: bufsize
    integer(i4b) :: nrow, ncol, nt, ct, cr, cc, t0, tt, nchr, nchc, nch, ich
    real(r4b) :: r4nodata
! ------------------------------------------------------------------------------
    call open_dataset(fname, varname, H5F_ACC_RDONLY, lay)
    ok = lay%lpipe.and.(lay%tclass == H5T_FLOAT).and.(lay%tsize == 4).and. &
      (((it == 0).and.(lay%nd == 2)).or.((it > 0).and.(lay%nd == 3)))
    if (.not.ok) then
      call close_dataset(lay); return
    end if
    if (lay%nd == 3) then
      nt = int(lay%dims(1)); nrow = int(lay%dims(2)); ncol = int(lay%dims(3))
      ct = int(lay%cdims(1)); cr = int(lay%cdims(2)); cc = int(lay%cdims(3))
    else
      nt = 0; nrow = int(lay%dims(1)); ncol = int(lay%dims(2))
      ct = 1; cr = int(lay%cdims(1)); cc = int(lay%cdims(2))
    end if
    if (it > nt) call errmsg('time index '//ta((/it/))//' outside '//trim(fname))
    !
    ! the raw chunks of this slice, serially: HDF5 holds its lock anyway
    t0 = 0; tt = 0
    if (it > 0) then
      t0 = ((it-1)/ct)*ct; tt = it - 1 - t0
    end if
    nchr = (nrow + cr - 1)/cr; nchc = (ncol + cc - 1)/cc; nch = nchr*nchc
    allocate(csize(nch), coff(nch+1))
    coff(1) = 0
    do ich = 1, nch
      call chunk_offset(ich, off)
      err = H5Dget_chunk_storage_size(lay%did, off, nbytes)
      if (err < 0) call errmsg('H5Dget_chunk_storage_size failed on '//trim(fname))
      csize(ich) = nbytes
      coff(ich+1) = coff(ich) + nbytes
    end do
    tot = coff(nch+1)
    allocate(cbuf(max(tot,1_c_int64_t)))
    do ich = 1, nch
      if (csize(ich) == 0) cycle
      call chunk_offset(ich, off)
      bufsize = int(csize(ich),c_size_t)
      err = H5Dread_chunk(lay%did, H5P_DEFAULT, off, fmask, cbuf(coff(ich)+1), bufsize)
      if (err < 0) call errmsg('H5Dread_chunk failed on '//trim(fname))
      if (fmask /= 0) call errmsg('chunk with skipped filters in '//trim(fname))
    end do
    call close_dataset(lay)
    !
    ! inflate, unshuffle and place the chunks, one task each
    if (associated(a)) deallocate(a)
    allocate(a(ncol, nrow))
    r4nodata = real(nodata, r4b)
    nbytes = int(ct,c_int64_t)*cr*cc*4
    !$omp taskloop default(shared) private(ich) grainsize(2)
    do ich = 1, nch
      call place_chunk(ich)
    end do
    !$omp end taskloop
    !
    return
    !
  contains
    subroutine chunk_offset(ich, off)
      integer(i4b), intent(in) :: ich
      integer(c_int64_t), dimension(3), intent(out) :: off
      integer(i4b) :: jr, jc
      jr = (ich-1)/nchc; jc = mod(ich-1, nchc)
      if (lay%nd == 3) then
        off(1) = t0; off(2) = int(jr,c_int64_t)*cr; off(3) = int(jc,c_int64_t)*cc
      else
        off(1) = int(jr,c_int64_t)*cr; off(2) = int(jc,c_int64_t)*cc; off(3) = 0
      end if
    end subroutine chunk_offset

    subroutine place_chunk(ich)
      integer(i4b), intent(in) :: ich
      integer(c_int8_t), dimension(:), allocatable, target :: zbuf, ubuf
      real(c_float), dimension(:), pointer :: fp
      integer(c_long) :: dlen
      integer(c_int) :: rc
      integer(i4b) :: jr, jc, r0, c0, i, j, k, n, nr, nc
      integer(c_int64_t) :: nel
      jr = (ich-1)/nchc; jc = mod(ich-1, nchc)
      r0 = jr*cr; c0 = jc*cc
      nr = min(cr, nrow - r0); nc = min(cc, ncol - c0)
      if (csize(ich) == 0) then
        a(c0+1:c0+nc, r0+1:r0+nr) = r4nodata
        return
      end if
      allocate(zbuf(nbytes), ubuf(nbytes))
      dlen = nbytes
      rc = uncompress(zbuf, dlen, cbuf(coff(ich)+1), int(csize(ich),c_long))
      if ((rc /= 0).or.(dlen /= nbytes)) then
        call errmsg('inflate failed on chunk '//ta((/ich/))//' of '//trim(fname))
      end if
      ! HDF5 shuffle: byte k of element i was stored at k*nel + i
      nel = nbytes/4
      if (lay%lshuffle) then
        do i = 0, int(nel)-1
          do k = 0, 3
            ubuf(4*i+k+1) = zbuf(k*nel+i+1)
          end do
        end do
        call c_f_pointer(c_loc(ubuf), fp, (/nel/))
      else
        call c_f_pointer(c_loc(zbuf), fp, (/nel/))
      end if
      ! chunk layout is C order (t, row, col)
      do j = 0, nr-1
        n = (tt*cr + j)*cc
        do i = 0, nc-1
          a(c0+i+1, r0+j+1) = fp(n+i+1)
        end do
      end do
    end subroutine place_chunk
  end function read_slice_chunks

  subroutine write_raster_chunks(fname, varname, a, nodata)
    ! a(ncol,nrow) into the 2-D int32 variable varname of fname, created by
    ! netCDF and closed: shuffle and deflate every chunk as a task, then write
    ! the raw chunks in row-major order. Cells beyond the extent hold nodata,
    ! the fill value netCDF gave the variable.
    character(len=*), intent(in) :: fname, varname
    integer(i4b), dimension(:,:), intent(in) :: a
    integer(i4b), intent(in) :: nodata
    ! -- local
    type(tLayout) :: lay
    type(tBytes), dimension(:), allocatable :: comp
    integer(c_int64_t), dimension(3) :: off
    integer(c_int64_t) :: nbytes
    integer(c_int) :: err
    integer(i4b) :: nrow, ncol, cr, cc, nchr, nchc, nch, ich
! ------------------------------------------------------------------------------
    ncol = size(a,1); nrow = size(a,2)
    !$omp critical(netcdf)
    call open_dataset(fname, varname, H5F_ACC_RDWR, lay)
    !$omp end critical(netcdf)
    if (.not.(lay%lpipe.and.(lay%tclass == H5T_INTEGER).and.(lay%tsize == 4).and.(lay%nd == 2))) then
      call errmsg(trim(fname)//' is not a chunked deflated int32 raster')
    end if
    if ((lay%dims(1) /= nrow).or.(lay%dims(2) /= ncol)) then
      call errmsg(trim(fname)//' has another shape than the array written to it')
    end if
    cr = int(lay%cdims(1)); cc = int(lay%cdims(2))
    nchr = (nrow + cr - 1)/cr; nchc = (ncol + cc - 1)/cc; nch = nchr*nchc
    nbytes = int(cr,c_int64_t)*cc*4
    allocate(comp(nch))
    !$omp taskloop default(shared) private(ich) grainsize(2)
    do ich = 1, nch
      call pack_chunk(ich)
    end do
    !$omp end taskloop
    !
    !$omp critical(netcdf)
    do ich = 1, nch
      off(1) = int((ich-1)/nchc,c_int64_t)*cr; off(2) = int(mod(ich-1,nchc),c_int64_t)*cc; off(3) = 0
      err = H5Dwrite_chunk(lay%did, H5P_DEFAULT, 0_c_int32_t, off, int(comp(ich)%n,c_size_t), comp(ich)%b)
      if (err < 0) call errmsg('H5Dwrite_chunk failed on '//trim(fname))
    end do
    call close_dataset(lay)
    !$omp end critical(netcdf)
    !
    return
    !
  contains
    subroutine pack_chunk(ich)
      integer(i4b), intent(in) :: ich
      integer(i4b), dimension(:), allocatable :: w
      integer(c_int8_t), dimension(:), allocatable :: rb, sb
      integer(c_long) :: dlen, bound
      integer(c_int) :: rc
      integer(i4b) :: jr, jc, r0, c0, i, j, k, nr, nc
      integer(c_int64_t) :: nel
      jr = (ich-1)/nchc; jc = mod(ich-1, nchc)
      r0 = jr*cr; c0 = jc*cc
      nr = min(cr, nrow - r0); nc = min(cc, ncol - c0)
      allocate(w(cr*cc))
      w = nodata
      do j = 0, nr-1
        do i = 0, nc-1
          w(j*cc+i+1) = a(c0+i+1, r0+j+1)
        end do
      end do
      allocate(rb(nbytes), sb(nbytes))
      rb = transfer(w, rb)
      nel = nbytes/4
      if (lay%lshuffle) then
        do i = 0, int(nel)-1
          do k = 0, 3
            sb(k*nel+i+1) = rb(4*i+k+1)
          end do
        end do
      else
        sb = rb
      end if
      bound = compressBound(int(nbytes,c_long))
      allocate(comp(ich)%b(bound))
      dlen = bound
      rc = compress2(comp(ich)%b, dlen, sb, int(nbytes,c_long), lay%level)
      if (rc /= 0) call errmsg('deflate failed on chunk '//ta((/ich/))//' of '//trim(fname))
      comp(ich)%n = dlen
    end subroutine pack_chunk
  end subroutine write_raster_chunks

end module chunk_io
