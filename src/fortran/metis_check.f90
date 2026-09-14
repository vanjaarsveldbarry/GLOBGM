program idxtest
  use, intrinsic :: iso_c_binding
  use, intrinsic :: iso_fortran_env, only: i8b => int64, r4b => real32
  implicit none
  interface
    function METIS_PartGraphRecursive(nvtxs, ncon, xadj, adjncy, vwgt, vsize, &
      adjwgt, nparts, tpwgts, ubvec, opts, objval, part) &
      bind(C, name='METIS_PartGraphRecursive') result(ierr)
      import :: c_ptr, c_int
      type(c_ptr), value :: nvtxs, ncon, xadj, adjncy, vwgt, vsize, adjwgt
      type(c_ptr), value :: nparts, tpwgts, ubvec, opts, objval, part
      integer(c_int) :: ierr
    end function
  end interface
  ! two triangles joined by one edge: the cut must be that single edge
  integer(i8b), target :: nvtxs = 6, ncon = 1, nparts = 2, objval = -1
  integer(i8b), target :: xadj(7)  = (/0,2,4,7,10,12,14/)
  integer(i8b), target :: adjncy(14) = (/1,2, 0,2, 0,1,3, 2,4,5, 3,5, 3,4/)
  integer(i8b), target :: vwgt(6) = 1, adjwgt(14) = 1, part(6) = -1
  integer(i8b), target :: opts(40) = -1
  integer :: ierr
  ierr = METIS_PartGraphRecursive(c_loc(nvtxs), c_loc(ncon), c_loc(xadj), &
    c_loc(adjncy), c_loc(vwgt), c_null_ptr, c_loc(adjwgt), c_loc(nparts), &
    c_null_ptr, c_null_ptr, c_loc(opts), c_loc(objval), c_loc(part))
  write(*,'(a,i0)') 'ierr   = ', ierr
  write(*,'(a,i0)') 'edgecut= ', objval
  write(*,'(a,6i2)') 'part   =', part
  if (ierr /= 1) stop 'METIS returned an error'
  if (objval /= 1) stop 'FAIL: edgecut should be 1'
  if (part(1) /= part(2) .or. part(2) /= part(3)) stop 'FAIL: triangle 1 split'
  if (part(4) /= part(5) .or. part(5) /= part(6)) stop 'FAIL: triangle 2 split'
  if (part(1) == part(4)) stop 'FAIL: triangles not separated'
  write(*,'(a)') 'PASS: int64 arguments partition correctly'
end program
