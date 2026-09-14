module utilsmod
  use, intrinsic :: iso_fortran_env , only: &
    i1b => int8, i2b => int16, i4b => int32, i8b => int64, &
    r4b => real32, r8b => real64
  use, intrinsic :: iso_c_binding, only: c_char, c_int, c_size_t, c_ptr, &
    c_null_char, c_associated
  implicit none

  ! os = 2 selects '/' separators and 'mkdir -p'. Formerly -DLINUX; Windows
  ! (os = 1) is a non-goal (design.md), so the preprocessor guard is gone.
  integer(i4b), parameter :: os = 2

  character(len=1), parameter :: win_slash = '\'
  character(len=1), parameter :: lin_slash = '/'

  integer(i4b), parameter :: mxslen = 1024
  character(len=1), parameter :: comment = '#'
  integer(i4b), parameter :: IZERO = 0
  real(r4b), parameter :: RZERO = 0.0
  real(r8b), parameter :: DZERO = 0.D0
  real(r8b), parameter :: DONE  = 1.D0

  ! POSIX chdir/getcwd through C interop: gfortran and ifx both have chdir, but
  ! as different extensions (intrinsic vs ifport).
  interface
    function c_chdir(path) bind(C, name='chdir') result(ierr)
      import :: c_char, c_int
      character(kind=c_char), dimension(*), intent(in) :: path
      integer(c_int) :: ierr
    end function c_chdir
    function c_getcwd(buf, size) bind(C, name='getcwd') result(p)
      import :: c_char, c_size_t, c_ptr
      character(kind=c_char), dimension(*), intent(inout) :: buf
      integer(c_size_t), value :: size
      type(c_ptr) :: p
    end function c_getcwd
  end interface

  interface fillgap
    module procedure :: fillgap_r4
  end interface fillgap
  private :: fillgap_r4

  interface fill_with_nearest
    module procedure :: fill_with_nearest_r4
  end interface fill_with_nearest
  private :: fill_with_nearest_r4

  interface addboundary
    module procedure :: addboundary_i
    module procedure :: addboundary_d
  end interface
  private :: addboundary_i, addboundary_d

  interface calc_unique
    module procedure :: calc_unique_i
  end interface calc_unique
  private :: calc_unique_i

  interface ta
    module procedure :: ta_i4
    module procedure :: ta_i8
    module procedure :: ta_r4
    module procedure :: ta_r8
  end interface
  private :: ta_i4, ta_i8, ta_r4, ta_r8

  type tBb
    integer(i4b) :: ic0  = huge(0)
    integer(i4b) :: ic1  = 0
    integer(i4b) :: ir0  = huge(0)
    integer(i4b) :: ir1  = 0
    integer(i4b) :: ncol = 0
    integer(i4b) :: nrow = 0
  end type tBb
  public :: tBb

  save

  contains
    
!  
  !
  function ta_i4(arr, fmt_in) result(s)
! ******************************************************************************
    ! -- arguments
    integer(i4b), dimension(:), intent(in) :: arr
    character(len=:), allocatable :: s
    character(len=*), intent(in), optional :: fmt_in
    ! -- locals
    logical :: lfmt
    integer(i4b) :: i
    character(len=mxslen) :: w, fmt
! ------------------------------------------------------------------------------
    lfmt = .false.
    if (present(fmt_in)) then
      fmt = fmt_in
      lfmt = .true.
    end if
    if (lfmt) then
      write(w,fmt) arr(1)
      s = trim(w)
    else
      write(w,*) arr(1)
      s = trim(adjustl(w))
    end if
    do i = 2, size(arr)
      if (lfmt) then
        write(w,fmt) arr(i)
        s = s//' '//trim(w)
      else
        write(w,*) arr(i)
        s = s//' '//trim(adjustl(w))
      end if
    end do
    !
    return
  end function ta_i4

  function ta_i8(arr, fmt_in) result(s)
! ******************************************************************************
    ! -- arguments
    integer(i8b), dimension(:), intent(in) :: arr
    character(len=:), allocatable :: s
    character(len=*), intent(in), optional :: fmt_in
    ! -- locals
    logical :: lfmt
    integer(i4b) :: i
    character(len=mxslen) :: w, fmt
! ------------------------------------------------------------------------------
    lfmt = .false.
    if (present(fmt_in)) then
      fmt = fmt_in
      lfmt = .true.
    end if
    if (lfmt) then
      write(w,fmt) arr(1)
      s = trim(w)
    else
      write(w,*) arr(1)
      s = trim(adjustl(w))
    end if
    do i = 2, size(arr)
      if (lfmt) then
        write(w,fmt) arr(i)
        s = s//' '//trim(w)
      else
        write(w,*) arr(i)
        s = s//' '//trim(adjustl(w))
      end if
    end do
    !
    return
  end function ta_i8
  function ta_r4(arr, fmt_in) result(s)
! ******************************************************************************
    ! -- arguments
    real(r4b), dimension(:), intent(in) :: arr
    character(len=:), allocatable :: s
    character(len=*), intent(in), optional :: fmt_in
    ! -- locals
    logical :: lfmt
    integer(i4b) :: i
    character(len=mxslen) :: w, fmt
! ------------------------------------------------------------------------------
    lfmt = .false.
    if (present(fmt_in)) then
      fmt = fmt_in
      lfmt = .true.
    end if
    if (lfmt) then
      write(w,fmt) arr(1)
      s = trim(w)
    else
      write(w,*) arr(1)
      s = trim(adjustl(w))
    end if
    do i = 2, size(arr)
      if (lfmt) then
        write(w,fmt) arr(i)
        s = s//' '//trim(w)
      else
        write(w,*) arr(i)
        s = s//' '//trim(adjustl(w))
      end if
    end do
    !
    return
  end function ta_r4
  function ta_r8(arr, fmt_in) result(s)
! ******************************************************************************
    ! -- arguments
    real(r8b), dimension(:), intent(in) :: arr
    character(len=:), allocatable :: s
    character(len=*), intent(in), optional :: fmt_in
    ! -- locals
    logical :: lfmt
    integer(i4b) :: i
    character(len=mxslen) :: w, fmt
! ------------------------------------------------------------------------------
    lfmt = .false.
    if (present(fmt_in)) then
      fmt = fmt_in
      lfmt = .true.
    end if
    if (lfmt) then
      write(w,fmt) arr(1)
      s = trim(w)
    else
      write(w,*) arr(1)
      s = trim(adjustl(w))
    end if
    do i = 2, size(arr)
      if (lfmt) then
        write(w,fmt) arr(i)
        s = s//' '//trim(w)
      else
        write(w,*) arr(i)
        s = s//' '//trim(adjustl(w))
      end if
    end do
    !
    return
  end function ta_r8

  subroutine swap_slash(s)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(inout) :: s
    ! -- locals
    character(len=1) :: src_slash, tgt_slash
    integer(i4b) :: i
! ------------------------------------------------------------------------------
    if (os == 1) then ! windows
      src_slash = lin_slash
      tgt_slash = win_slash
    else ! linux
      src_slash = win_slash
      tgt_slash = lin_slash
    end if
    !
    do i = 1, len_trim(s)
      if (s(i:i) == src_slash) then
        s(i:i) = tgt_slash
      end if
    end do
    !
    return
  end subroutine swap_slash
  !
  !
  !
  !
  !
  subroutine open_file(f, iu, act_in, lbin_in)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(inout) :: f
    integer(i4b), intent(inout) :: iu
    character(len=1), optional :: act_in
    logical, intent(in), optional :: lbin_in
    ! -- locals
    character(len=1) :: act
    logical :: lbin, lex, lop
! ------------------------------------------------------------------------------
    if (present(act_in)) then
      act = change_case(act_in, 'l')
    else
      act = 'r'
    end if
    if (present(lbin_in)) then
      lbin = lbin_in
    else
      lbin= .false.
    end if
    !
    call swap_slash(f)
    !
    inquire(file=f, exist=lex)
    if (lex) then
      inquire(file=f, opened=lop, number=iu)
      if (lop) then
        call logmsg('Warning: file '//trim(f)//' is already opened.')
        return
      end if
    end if
    !
    if (act == 'r') then
      inquire(file=f, exist=lex)
      if (.not.lex) then
        call errmsg('File '//trim(f)//' does not exist.')
      end if
    end if

    iu = getlun()
    if ((act == 'r') .and.(.not.lbin)) then
      call logmsg('Reading ascii file '//trim(f)//'...')
      open(unit=iu, file=f, form='formatted', access='sequential', action='read', status='old')
    else if ((act == 'w') .and.(.not.lbin)) then
      call logmsg('Writing ascii file '//trim(f)//'...')
      open(unit=iu, file=f, form='formatted', access='sequential', action='write', status='replace')
    else if ((act == 'r') .and.(lbin)) then
      call logmsg('Reading binary file '//trim(f)//'...')
      open(unit=iu, file=f, form='unformatted', access='stream', action='readwrite', status='old')
    else if ((act == 'w') .and.(lbin)) then
      call logmsg('Writing binary file '//trim(f)//'...')
      open(unit=iu, file=f, form='unformatted', access='stream', action='write', status='replace')
    else
      call errmsg('Subroutine open_file called with invalid option')
    end if
    !
    return
  end subroutine open_file

  function getlun() result(lun)
! ******************************************************************************
    ! -- arguments
    integer :: lun
    ! -- locals
    logical :: lex
! ------------------------------------------------------------------------------
    do lun=20, 5000
      inquire(unit=lun,opened=lex)
      if(.not.lex)exit
    end do
    !
    return
  end function getlun

  subroutine chkexist(fname)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: fname
    ! -- locals
    logical :: lex
! ------------------------------------------------------------------------------
    inquire(file=fname,exist=lex)
    if (.not.lex) then
      call errmsg('cannot find '//trim(fname))
    end if
    !
    return
  end subroutine chkexist

  subroutine errmsg(msg)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: msg
! ------------------------------------------------------------------------------
    write(*,'(a)') 'Error: '//trim(msg)
    stop 1
  end subroutine errmsg

  subroutine logmsg(msg)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: msg
! ------------------------------------------------------------------------------
    write(*,'(a)') trim(msg)
    !
    return
  end subroutine logmsg

! $Id: quicksort.f90 558 2015-03-25 13:44:47Z larsnerger $

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!    Collection of subroutines to sort and return a one-dimensional array
!!!    as well as corresponding sorted index of the array a. Original code
!!!    (distributed under GNU Free licence 1.2) was taken from
!!!    http://rosettacode.org/wiki/Quicksort#Fortran and modified to
!!!    also return sorted index of the original array a.
!!!    Copyright (C) 2015  Sanita Vetra-Carvalho
!!!
!!!    This program is distributed under the Lesser General Public License (LGPL) version 3,
!!!    for more details see <https://www.gnu.org/licenses/lgpl.html>.
!!!
!!!    Email: s.vetra-carvalho @ reading.ac.uk
!!!    Mail:  School of Mathematical and Physical Sciences,
!!!    	      University of Reading,
!!!	      Reading, UK
!!!	      RG6 6BB
!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!> subroutine to sort using the quicksort algorithm
!! @param[in,out] a, an array of doubles to be sorted
!! @param[out] idx_a, an array of sorted indecies of original array a
!! @param[in] na, dimension of the array a

recursive subroutine quicksort_d(a,idx_a,na)

! DUMMY ARGUMENTS
integer(i4b), intent(in) :: na ! nr or items to sort
real(r8b), dimension(nA), intent(inout) :: a ! vector to be sorted
integer(i4b), dimension(nA), intent(inout) :: idx_a ! sorted indecies of a

! LOCAL VARIABLES
integer(i4b) :: left, right, mid
real(r8b) :: pivot, temp
integer(i4b) :: marker, idx_temp

if (nA > 1) then
! insertion sort limit of 47 seems best for sorting 10 million
! integers on Intel i7-980X CPU.  Derived data types that use
! more memory are optimized with smaller values - around 20 for a 16
! -byte type.
  if (nA > 47) then
  ! Do quicksort for large groups
  ! Get median of 1st, mid, & last points for pivot (helps reduce
  ! long execution time on some data sets, such as already
  ! sorted data, over simple 1st point pivot)
    mid = (nA+1)/2
    if (a(mid) >= a(1)) then
      if (a(mid) <= a(nA)) then
        pivot = a(mid)
      else if (a(nA) > a(1)) then
        pivot = a(nA)
      else
        pivot = a(1)
      end if
    else if (a(1) <= a(nA)) then
      pivot = a(1)
    else if (a(nA) > a(mid)) then
      pivot = a(nA)
    else
      pivot = a(mid)
    end if

    left = 0
    right = nA + 1

    do while (left < right)
      right = right - 1
      do while (A(right) > pivot)
        right = right - 1
      end do
      left = left + 1
      do while (A(left) < pivot)
        left = left + 1
      end do
      if (left < right) then
        temp = A(left)
        idx_temp = idx_a(left)
        A(left) = A(right)
        idx_a(left) = idx_a(right)
        A(right) = temp
        idx_a(right) = idx_temp
      end if
    end do

    if (left == right) then
      marker = left + 1
    else
      marker = left
    end if

    call quicksort_d(A(:marker-1),idx_A(:marker-1),marker-1)
    call quicksort_d(A(marker:),idx_A(marker:),nA-marker+1)

  else
      call InsertionSort_d(A,idx_a,nA)    ! Insertion sort for small groups is
      !  faster than Quicksort
  end if
end if

return
end subroutine quicksort_d

!> subroutine to sort using the insertionsort algorithm and return indecies
!! @param[in,out] a, an array of doubles to be sorted
!! @param[in,out] idx_a, an array of integers of sorted indecies
!! @param[in] na, dimension of the array a
subroutine InsertionSort_d(a,idx_a,na)

  ! DUMMY ARGUMENTS
  integer(i4b),intent(in) :: na
  real(r8b), dimension(nA), intent(inout) :: a
  integer(i4b),dimension(nA), intent(inout) :: idx_a

! LOCAL VARIABLES
  real(r8b) :: temp
  integer(i4b):: i, j
  integer(i4b):: idx_tmp

  do i = 2, nA
     j = i - 1
     temp = A(i)
     idx_tmp = idx_a(i)
     do
        if (j == 0) exit
        if (a(j) <= temp) exit
        A(j+1) = A(j)
        idx_a(j+1) = idx_a(j)
        j = j - 1
     end do
     a(j+1) = temp
     idx_a(j+1) = idx_tmp
  end do
  return
end subroutine InsertionSort_d

subroutine addboundary_i(wrk, ncol, nrow)
! ******************************************************************************
  integer, intent(in) :: ncol, nrow
  integer, dimension(ncol,nrow), intent(inout) :: wrk

  integer :: icol, irow, jp

  do irow = 1, nrow
    do icol = 1, ncol
      jp = wrk(icol,irow)
      if (jp > 0) then
        ! N
        if (irow > 1) then
          if (wrk(icol,irow-1) == 0) then
            wrk(icol,irow-1) = -jp
          end if
        end if
        ! S
        if (irow < nrow) then
          if (wrk(icol,irow+1) == 0) then
            wrk(icol,irow+1) = -jp
          end if
        end if
        ! W
        if (icol > 1) then
          if (wrk(icol-1,irow) == 0) then
            wrk(icol-1,irow) = -jp
          end if
        end if
        ! E
        if (icol < ncol) then
          if (wrk(icol+1,irow) == 0) then
            wrk(icol+1,irow) = -jp
          end if
        end if
      end if
    end do
  end do

  return
end subroutine addboundary_i

subroutine addboundary_d(wrk, ncol, nrow, nodata)
! ******************************************************************************
  integer, intent(in) :: ncol, nrow
  double precision, dimension(ncol,nrow), intent(inout) :: wrk
  double precision, intent(in) :: nodata

  integer :: icol, irow, jp

  do irow = 1, nrow
    do icol = 1, ncol
      jp = int(wrk(icol,irow))
      if (jp > 0) then
        ! N
        if (irow > 1) then
          if (wrk(icol,irow-1) == nodata) then
            wrk(icol,irow-1) = -dble(jp)
          end if
        end if
        ! S
        if (irow < nrow) then
          if (wrk(icol,irow+1) == nodata) then
            wrk(icol,irow+1) = -dble(jp)
          end if
        end if
        ! W
        if (icol > 1) then
          if (wrk(icol-1,irow) == nodata) then
            wrk(icol-1,irow) = -dble(jp)
          end if
        end if
        ! E
        if (icol < ncol) then
          if (wrk(icol+1,irow) == nodata) then
            wrk(icol+1,irow) = -dble(jp)
          end if
        end if
      end if
    end do
  end do

  return
end subroutine addboundary_d

  subroutine calc_unique_i(p, pu, id)
! ******************************************************************************
    ! -- arguments
    integer, dimension(:,:), intent(in) :: p
    integer, dimension(:,:), allocatable, intent(inout) :: pu
    integer, intent(out) :: id
    ! --- local
    integer, parameter :: jp = 1, jn = 2, js = 3, jw = 4, je = 5
    integer, parameter :: jnw = 6, jne = 7, jsw = 8, jse = 9
    integer, parameter :: nst = jse
    integer, dimension(2,nst) :: s1

    integer :: ic, ir, jc, jr, ncol, nrow, n1, n2, i, j, nlst
    integer, dimension(:,:), allocatable :: lst1, lst2, wrk
    logical :: ldone
! ------------------------------------------------------------------------------
    ncol = size(p,1); nrow = size(p,2)
    if (allocated(pu)) then
      deallocate(pu)
    end if
    allocate(pu(ncol,nrow))
    
    nlst = max(nst,ncol*nrow)
    allocate(lst1(2,nlst), lst2(2,nlst), wrk(ncol,nrow))

    do ir = 1, nrow
      do ic = 1, ncol
        pu(ic,ir) = 0
        wrk(ic,ir) = 0
      end do
    end do

    id = 0
    do ir = 1, nrow
      do ic = 1, ncol
        if ((p(ic,ir) /= 0) .and. (pu(ic,ir) == 0)) then

          ! set stencil
          s1(1,jp) = ic;             s1(2,jp) = ir
          s1(1,jn) = ic;             s1(2,jn) = max(1,   ir-1)
          s1(1,js) = ic;             s1(2,js) = min(nrow,ir+1)
          s1(1,jw) = max(1,   ic-1); s1(2,jw) = ir
          s1(1,je) = min(ncol,ic+1); s1(2,je) = ir
          s1(1,jnw) = s1(1,jw); s1(2,jnw) = s1(2,jn)
          s1(1,jne) = s1(1,je); s1(2,jne) = s1(2,jn)
          s1(1,jsw) = s1(1,jw); s1(2,jsw) = s1(2,js)
          s1(1,jse) = s1(1,je); s1(2,jse) = s1(2,js)
          !
          id = id + 1

          n1 = 0
          jc = s1(1,1); jr = s1(2,1)
          pu(jc,jr) = id
          do i = 2, nst
            jc = s1(1,i); jr = s1(2,i)
            if ((abs(p(jc,jr)) > 0) .and. (pu(jc,jr) == 0)) then
              n1 = n1 + 1
              lst1(1,n1) = jc; lst1(2,n1) = jr
            end if
          end do

          ldone = .false.
          do while (.not.ldone)
            n2 = 0
            do i = 1, n1
              jc = lst1(1,i); jr = lst1(2,i)
              s1(1,jp) = jc;             s1(2,jp) = jr
              s1(1,jn) = jc;             s1(2,jn) = max(1,   jr-1)
              s1(1,js) = jc;             s1(2,js) = min(nrow,jr+1)
              s1(1,jw) = max(1,   jc-1); s1(2,jw) = jr
              s1(1,je) = min(ncol,jc+1); s1(2,je) = jr
              s1(1,jnw) = s1(1,jw); s1(2,jnw) = s1(2,jn)
              s1(1,jne) = s1(1,je); s1(2,jne) = s1(2,jn)
              s1(1,jsw) = s1(1,jw); s1(2,jsw) = s1(2,js)
              s1(1,jse) = s1(1,je); s1(2,jse) = s1(2,js)
              pu(jc,jr) = id
              do j = 2, nst
                jc = s1(1,j); jr = s1(2,j)
                if ((abs(p(jc,jr)) > 0) .and. (pu(jc,jr) == 0) .and. (wrk(jc,jr) == 0)) then
                  n2 = n2 + 1
                  lst2(1,n2) = jc; lst2(2,n2) = jr
                  wrk(jc,jr) = 1
                end if
              end do
            end do
            !
            if (n2 == 0) then
              ldone = .true.
              exit
            end if
            !
            ! set list 1
            do i = 1, n1
              jc = lst1(1,i); jr = lst1(2,i)
              pu(jc,jr) = id
            end do
            !
            ! copy list, set work
            do i = 1, n2
              jc = lst2(1,i); jr = lst2(2,i)
              lst1(1,i) = jc; lst1(2,i) = jr
              wrk(jc,jr) = 0
            end do
            n1 = n2
          end do
        end if
      end do
    end do
    !
    ! cleanup
    deallocate(lst1, lst2)
    !
    ! p < 0 marks the label negative
    do ir = 1, nrow
      do ic = 1, ncol
        if ((pu(ic,ir) /= 0).and.(p(ic,ir) < 0)) then
          pu(ic,ir) = -pu(ic,ir)
        end if
      end do
    end do
    deallocate(wrk)

    return
  end subroutine calc_unique_i

  function change_case(str, opt) result (string)
  !###====================================================================
    character(*), intent(in) :: str
    character(len=1) :: opt
    character(len(str))      :: string

    integer :: ic, i

    character(26), parameter :: cap = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    character(26), parameter :: low = 'abcdefghijklmnopqrstuvwxyz'

  !   Capitalize each letter if it is lowecase
    string = str
    if ((opt == 'U') .or. (opt == 'u')) then
      do i = 1, LEN_TRIM(str)
        ic = INDEX(low, str(i:i))
        if (ic > 0) string(i:i) = cap(ic:ic)
      end do
    end if
    if ((opt == 'L') .or. (opt == 'l')) then
      do i = 1, LEN_TRIM(str)
        ic = INDEX(cap, str(i:i))
        if (ic > 0) string(i:i) = low(ic:ic)
      end do
    end if
    !
    return
  end function change_case

  subroutine fillgap_r4(x, nodata, xtgt)
! ******************************************************************************
    ! -- arguments
    real(r4b), dimension(:,:), intent(inout) :: x
    real(r4b), intent(in) :: nodata
    real(r4b), intent(in) :: xtgt
    ! -- locals
    integer(i4b), parameter :: maxiter = 1000
    !
    integer(i4b), parameter :: nsten = 8
    ! (dcol,drow) offsets. The visit order is load-bearing: with nbr <= 2 the
    ! first neighbour found wins outright, and the mode below breaks ties by
    ! value, so E, SE, NE, W, SW, NW, S, N must not be reordered.
    integer(i4b), dimension(2,nsten), parameter :: sten = reshape( &
      (/ 1, 0,   1, 1,   1,-1,  -1, 0,  -1, 1,  -1,-1,   0, 1,   0,-1/), (/2,nsten/))
    integer(i4b), dimension(2,nsten) :: sicir
    !
    integer(i1b), dimension(:,:), allocatable :: i1wrk
    integer(i4b) :: nc, nr, ic, ir, n, m, nbr, nsn, i, j, maxcnt
    integer(i4b) :: ntgt, iter, nnodata, jc, jr
    integer(i4b) :: bbic0, bbic1, bbir0, bbir1, bbjc0, bbjc1, bbjr0, bbjr1
    integer(i4b), dimension(:,:), allocatable :: i4wrk
    integer(i4b), dimension(8) :: ucnt
    real(r4b), dimension(:), allocatable :: r4wrk
    real(r4b), dimension(8) :: r4nbr, r4ucnt
    real(r4b) :: r4huge, rval, rvalp, rval_min, rval_max
    real(r4b), parameter :: my_nodata  = -12345.
! ------------------------------------------------------------------------------
    r4huge = huge(r4huge)
    !
    nc = size(x,1); nr = size(x,2)
    allocate(i1wrk(nc,nr),i4wrk(2,nc*nr), r4wrk(nc*nr))
    bbir0 = 1; bbir1 = nr; bbic0 = 1; bbic1 = nc
    !
    iter = 0; n = 1
    do while(.true.)
      iter = iter + 1
      !
      do ir = 1, nr
        do ic = 1, nc
          i1wrk(ic,ir) = 0
        end do
      end do
      !
      if (iter == 1) then
        rvalp = xtgt
       else
        rvalp = my_nodata
      end if
      !
      n = 0
      do ir = bbir0, bbir1
        do ic = bbic0, bbic1
          if (x(ic,ir) == rvalp) then
            nbr = 0; nsn = 0
            do i = 1, nsten
              jc = ic + sten(1,i); jr = ir + sten(2,i)
              if ((jc < 1).or.(jc > nc).or.(jr < 1).or.(jr > nr)) cycle
              nsn = nsn + 1; sicir(1,nsn) = jc; sicir(2,nsn) = jr
              rval = x(jc,jr)
              if ((rval /= xtgt).and.(rval /= nodata).and.(rval /= my_nodata)) then
                nbr = nbr + 1; r4nbr(nbr) = rval
              end if
            end do
            !
            ! neighbors found
            if (nbr > 0) then
              do i = 1, nsn
                jc = sicir(1,i); jr = sicir(2,i)
                if (x(jc,jr) == xtgt) then
                  i1wrk(jc,jr) = 1
                end if
              end do
              !
              n = n + 1
              i4wrk(1,n) = ic; i4wrk(2,n) = ir
              if (nbr <= 2) then
                r4wrk(n) = r4nbr(1)
              else
                ! check if all are the same
                rval_min = r4huge; rval_max = -r4huge
                do i = 1, nbr
                  rval_min = min(rval_min,r4nbr(i))
                  rval_max = max(rval_max,r4nbr(i))
                end do
                if (rval_min == rval_max) then
                  r4wrk(n) = rval_min
                else
                  ! ascending, so the run-length pass below groups equal
                  ! values and picks the smallest of the most frequent
                  do i = 2, nbr
                    rval = r4nbr(i); j = i - 1
                    do while (j >= 1)
                      if (r4nbr(j) <= rval) exit
                      r4nbr(j+1) = r4nbr(j); j = j - 1
                    end do
                    r4nbr(j+1) = rval
                  end do
                  !
                  ucnt = 0; r4ucnt(1) = r4nbr(1); m = 1
                  do i = 1, nbr
                    if (r4nbr(i) /= r4ucnt(m)) then
                      m = m + 1
                      r4ucnt(m) = r4nbr(i)
                    end if
                    ucnt(m) = ucnt(m) + 1
                  end do
                  maxcnt = 0
                  do i = 1, m
                    maxcnt = max(maxcnt,ucnt(i))
                  end do
                  do i = 1, m
                    if (ucnt(i) == maxcnt) then
                      r4wrk(n) = r4ucnt(i)
                      exit
                    end if
                  end do
                end if
              end if
            end if
          end if
        end do
      end do
      !
      ! set the target value
      do i = 1, n
        ic = i4wrk(1,i); ir = i4wrk(2,i)
        x(ic,ir) = r4wrk(i)
        i1wrk(ic,ir) = 0
      end do
      !
      bbjr0 = nr+1; bbjr1 = 0; bbjc0 = nc+1; bbjc1 = 0
      do ir = 1, nr
        do ic = 1, nc
          if (i1wrk(ic,ir) == 1) then
            x(ic,ir) = my_nodata
            bbjr0 = min(bbjr0,ir); bbjr1 = max(bbjr1,ir)
            bbjc0 = min(bbjc0,ic); bbjc1 = max(bbjc1,ic)
          end if
        end do
      end do
      !
      ! set loop bounding box
      bbir0 = max(bbjr0-1,1); bbir1 = min(bbjr1+1,nr)
      bbic0 = max(bbjc0-1,1); bbic1 = min(bbjc1+1,nc)
      !
      ! count the remaining target values
      ntgt = 0; nnodata = 0
      do ir = 1, nr
        do ic = 1, nc
          if (x(ic,ir) == xtgt) then
            ntgt = ntgt + 1
          end if
          if (x(ic,ir) == my_nodata) then
            nnodata = nnodata + 1
          end if
        end do
      end do
      call logmsg('Iteration '//ta((/iter/))//'; # added: '//ta((/n/))//'; # remaining: '//ta((/ntgt,nnodata/)))
      ntgt = ntgt + nnodata
      !
      if (iter == maxiter) then
        call errmsg('fillgap_r4: maximum iterations of '//ta((/iter/))//' reached.')
      end if
      if (n == 0) exit
    end do
    call logmsg('Total iterations: '//ta((/iter/))//'; # not filled: '//ta((/ntgt/)))
    !
    deallocate(i1wrk,i4wrk,r4wrk)
    return
  end subroutine fillgap_r4
  
  subroutine fill_with_nearest_r4(x, nodata, xtgt)
! ******************************************************************************
    ! -- arguments
    real(r4b), dimension(:,:), intent(inout) :: x
    real(r4b), intent(in) :: nodata
    real(r4b), intent(in) :: xtgt
    ! -- locals
    logical :: lfound
    integer(i4b), dimension(:), allocatable :: cnt
    integer(i4b), dimension(:,:), allocatable :: icir
    integer(i4b), dimension(1) :: mloc
    integer(i4b) :: n, m, nc, nr, mc, mr, ic, ir, jc, jr, ic0, ic1, ir0, ir1, &
      jc0, jc1, jr0, jr1, ntgt, iact, i, j, k, nb, id0, id1, id
    real(r4b) :: r4v, r4vmin, r4vmax
    real(r4b), dimension(:), allocatable :: r4vi, r4vb
! ------------------------------------------------------------------------------
    !
    nc = size(x,1); nr = size(x,2)
    allocate(r4vb(2*nc + 2*nr))
    !
    ! store the location to intepolate
    do iact = 1, 2
      ntgt = 0
      do ir = 1, nr
        do ic = 1, nc
          r4v = x(ic,ir)
          if (r4v /= nodata) then
            if (r4v == xtgt) then
              ntgt = ntgt + 1
              if (iact == 2) then
                icir(1,ntgt) = ic
                icir(2,ntgt) = ir
              end if
            end if
          end if
        end do
      end do
      if (iact == 1) then
        if (ntgt > 0) then
          allocate(icir(2,ntgt), r4vi(ntgt))
          do i = 1, ntgt
            r4vi(i) = nodata
          end do
        end if
      end if
    end do
    !
    if (ntgt == 0) then
      return
    else
      call logmsg('# interpolation cells: '//ta((/ntgt/)))
    end if
    !
    do i = 1, ntgt
      jc = icir(1,i); jr = icir(2,i)
      !
      lfound = .false.; n = 0
      do while(.not.lfound)
        n = n + 1
        ir0 = jr - n; ir1 = jr + n; ic0 = jc - n; ic1 = jc + n
        ir0 = max(1,ir0); ir1 = min(nr,ir1); ic0 = max(1,ic0); ic1 = min(nc,ic1); 
        nb = 0; r4vmin = huge(r4vmin); r4vmax = -huge(r4vmax)
        !
        do j = 1, 4
          select case(j)
          case(1) !N
            jr0 = ir0; jr1 = ir0; jc0 = ic0; jc1 = ic1
          case(2) !S
            jr0 = ir1; jr1 = ir1; jc0 = ic0; jc1 = ic1
          case(3) !W
            jr0 = ir0 + 1; jr1 = ir1 - 1; jc0 = ic0; jc1 = ic0
          case(4) !E
            jr0 = ir0 + 1; jr1 = ir1 - 1; jc0 = ic1; jc1 = ic1
           end select
          !
          mr = ir1 - ir0 + 1; mc = ic1 - ic0 + 1
          if (.not.lfound) then
            do ir = jr0, jr0
              do ic = jc0, jc1
                r4v = x(ic,ir)
                if ((r4v /= nodata).and.(r4v /= xtgt)) then
                  lfound = .true.
                  nb = nb + 1
                  r4vb(nb) = r4v
                  r4vmin = min(r4vmin, r4v); r4vmax = max(r4vmax, r4v)
                end if
              end do
            end do
          end if
        end do
        !
        if (lfound) then
          if (nb == 1) then
            r4vi(i) = r4vb(1)
          else
            if (r4vmin == r4vmax) then
              r4vi(i) = r4vb(1)
            else
              id0 = int(r4vmin,i4b); id1 = int(r4vmax,i4b)
              m = id1 - id0 + 1
              allocate(cnt(m))
              do k = 1, m
                cnt(k) = 0
              end do
              do k = 1, nb
                id = int(r4vb(k),i4b) - id0 + 1
                cnt(id) = cnt(id) + 1
              end do
              mloc = maxloc(cnt); id = mloc(1) + id0 - 1
              r4vi(i) = real(id,r4b)
              deallocate(cnt)
            end if
          end if
        end if
      end do
    end do
    !
    do i = 1, ntgt
      jc = icir(1,i); jr = icir(2,i)
      r4v = r4vi(i)
      if (r4v == nodata) then
        call errmsg('Invalid interpolated value')
      end if
      x(jc,jr) = r4v
    end do
    !
    if (allocated(icir)) deallocate(icir)
    if (allocated(r4vi)) deallocate(r4vi)
    !
    return
  end subroutine fill_with_nearest_r4

  subroutine label_node(ia, ja, id1, i4wk1d, ireg)
! ******************************************************************************
    ! -- arguments
    integer(i4b), dimension(:), intent(in) :: ia
    integer(i4b), dimension(:), intent(in) :: ja
    integer(i4b), intent(in) :: id1
    integer(i4b), dimension(:), intent(inout) :: i4wk1d
    integer(i4b), intent(in) :: ireg
    !
    ! -- locals
    integer(i4b) :: i, id, id2, n
    integer(i4b), dimension(:), allocatable :: stack
! ------------------------------------------------------------------------------
    ! reference recursed once per node; the explicit stack is bounded by the
    ! node count instead of the process stack
    allocate(stack(size(ia)-1))
    n = 1; stack(1) = id1; i4wk1d(id1) = ireg
    do while (n > 0)
      id = stack(n); n = n - 1
      do i = ia(id)+1, ia(id+1)-1
        id2 = ja(i)
        if (i4wk1d(id2) == 0) then
          i4wk1d(id2) = ireg
          n = n + 1; stack(n) = id2
        end if
      end do
    end do
    !
    return
  end subroutine label_node

  function jdn(y, m, d) result(j)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: y, m, d
    integer(i4b) :: j
    ! -- locals
    integer(i4b) :: a, yy, mm
! ------------------------------------------------------------------------------
    a = (14 - m)/12
    yy = y + 4800 - a
    mm = m + 12*a - 3
    j = d + (153*mm + 2)/5 + 365*yy + yy/4 - yy/100 + yy/400 - 32045
    !
    return
  end function jdn

  subroutine jdn_to_ymd(j, y, m, d)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: j
    integer(i4b), intent(out) :: y, m, d
    ! -- locals
    integer(i4b) :: a, b, c, dd, e, mm
! ------------------------------------------------------------------------------
    a = j + 32044
    b = (4*a + 3)/146097
    c = a - 146097*b/4
    dd = (4*c + 3)/1461
    e = c - 1461*dd/4
    mm = (5*e + 2)/153
    d = e - (153*mm + 2)/5 + 1
    m = mm + 3 - 12*(mm/10)
    y = 100*b + dd - 4800 + mm/10
    !
    return
  end subroutine jdn_to_ymd

  function get_jd(y, m, d) result(jd)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: y
    integer(i4b), intent(in) :: m
    integer(i4b), intent(in) :: d
    real(r8b) :: jd
! ------------------------------------------------------------------------------
    jd = real(jdn(y, m, d), r8b)
    !
    return
  end function get_jd

  subroutine get_ymd_from_jd(jd, date, y, m, d)
! ******************************************************************************
    ! -- arguments
    real(r8b), intent(in) :: jd
    integer(i4b), intent(out) :: date
    integer(i4b), intent(out) :: y
    integer(i4b), intent(out) :: m
    integer(i4b), intent(out) :: d
! ------------------------------------------------------------------------------
    call jdn_to_ymd(nint(jd), y, m, d)
    date = y*10000 + m*100 + d
    !
    return
  end subroutine get_ymd_from_jd

  subroutine jd_next_month(jd)
! ******************************************************************************
    ! -- arguments
    real(r8b), intent(inout) :: jd
    ! -- locals
    integer(i4b) :: date, y, m, d
! ------------------------------------------------------------------------------
    call get_ymd_from_jd(jd, date, y, m, d)

    if (m == 12) then
      y = y + 1
      m = 1
    else
      m = m + 1
    end if
    jd = get_jd(y, m, d)
    !
    return
  end subroutine jd_next_month

  function get_month_days_s(date) result(nd)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: date
    integer(i4b) :: nd
    ! -- locals
    integer(i4b) :: y, m, y2, m2
! ------------------------------------------------------------------------------
    read(date(1:4),*) y
    read(date(5:6),*) m
    y2 = y; m2 = m + 1
    if (m == 12) then
      y2 = y + 1; m2 = 1
    end if
    nd = jdn(y2, m2, 1) - jdn(y, m, 1)
    !
    return
  end function get_month_days_s

  subroutine create_dir(d, lverb_in)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(inout) :: d
    logical, intent(in), optional :: lverb_in
    ! -- locals
    logical :: ldirexist, lverb
    integer(i4b) :: ios
! ------------------------------------------------------------------------------
    if (present(lverb_in)) then
      lverb = lverb_in
    else
      lverb = .false.
    end if
    !
    call swap_slash(d)
    inquire(file=d, exist=ldirexist, iostat=ios)
    if (ios.ne.0) ldirexist=.false.
    if (ldirexist) then
      if (.not.lverb) then
        call logmsg('Directory '//trim(d)//' already already exists.')
      end if
      return
    end if
    !
    if (.not.lverb) then
      call logmsg('Creating directory '//trim(d)//'.')
    end if
    call execute_command_line('mkdir -p '//trim(d), exitstat=ios)
    if (ios /= 0) then
      call errmsg('Could not create directory '//trim(d)//'.')
    end if
    !
    return
  end subroutine create_dir
  !
  subroutine change_work_dir(d, lverb_in)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(inout) :: d
    logical, intent(in), optional :: lverb_in
    ! -- locals
    character(len=mxslen) :: cd
    logical :: lverb, ldirexist
    integer(i4b) :: ios
! ------------------------------------------------------------------------------
    if (present(lverb_in)) then
      lverb = lverb_in
    else
      lverb = .false.
    end if
    !
    call swap_slash(d)
    inquire(file=d, exist=ldirexist, iostat=ios)
    if (ios.ne.0) ldirexist=.false.
    if (.not.ldirexist) then
      call errmsg('Directory '//trim(d)//' does not exist.')
    end if
    !
    if (.not.lverb) then
      call get_work_dir(cd)
      call logmsg('Changing working directory '//trim(cd)//' -> '//trim(d)//'.')
    end if
    if (c_chdir(trim(d)//c_null_char) /= 0) then
      call errmsg('Could not change to directory '//trim(d)//'.')
    end if
    !
    return
  end subroutine change_work_dir
  !
  subroutine get_work_dir(d)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(inout) :: d
    ! -- locals
    character(kind=c_char, len=mxslen) :: buf
    integer(i4b) :: i
! ------------------------------------------------------------------------------
    if (.not.c_associated(c_getcwd(buf, int(mxslen, c_size_t)))) then
      call errmsg('getcwd failed.')
    end if
    i = index(buf, c_null_char)
    d = buf(1:i-1)
    !
    return
  end subroutine get_work_dir

  function readline(iu, so) result(ios)
! ******************************************************************************
    ! -- arguments
    integer(i4b), intent(in) :: iu
    character(len=*), intent(out), optional :: so
    integer(I4B) :: ios
    ! -- locals
    character(len=mxslen) :: s
    integer(i4b) :: i
! ------------------------------------------------------------------------------
    do while(.true.)
      read(unit=iu, iostat=ios, fmt='(a)') s
      if (ios /= 0) exit
      so = trim(adjustl(s))
      if ((so(1:1) /= comment) .and. (len_trim(so) > 0)) then
        i = index(so, comment, back=.true.)
        if (i > 0) then
          so = so(1:i-1)
        end if
        exit
      end if
    end do
    !
    return
  end function readline

  subroutine getminmax(key, sep, token, imin, imax)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: key
    character(len=1), intent(in) :: sep
    character(len=*), intent(in) :: token
    integer(I4B), intent(out) :: imin
    integer(I4B), intent(out) :: imax
    ! -- locals
    character(len=mxslen) :: s
    integer(I4B) :: i, j, n, ios1, ios2, ival1, ival2
    character(len=mxslen), dimension(:), allocatable :: words
! ------------------------------------------------------------------------------
    words = getwords(key, sep)
    n = size(words)
    if (n == 0) return
    !
    imin = 0
    imax = 0
    do i = 1, n
      s = words(i)
      if (s(1:1) == token) then
        j = index(s,':')
        if (j == 0) then
          read(s(2:),*,iostat=ios1) ival1
          if (ios1 == 0) then
            imin = ival1
            imax = imin
          end if
        else
          read(s(2:j-1),*,iostat=ios1) ival1
          read(s(j+1:),*,iostat=ios2) ival2
          if ((ios1 == 0).and.(ios2 == 0)) then
            imin = ival1
            imax = ival2
          else
            call errmsg("Could not read "//trim(s))
          end if
        end if
      end if
    end do
    !
    return
  end subroutine getminmax

  function getwords(s_in, token) result(words)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: s_in
    character(len=mxslen), dimension(:), allocatable :: words
    character(len=1), optional, intent(in) :: token
    ! -- locals
    integer(i4b) :: i, j, n, i0, i1
    character(len=1) :: tokenLocal
    character(len=1), parameter :: quote = '"'
    character(len=mxslen) :: s, s1, s2
    integer(I4B), parameter :: maxwords = 100
    integer(I4B), dimension(maxwords) :: ind
    logical :: lquote
! ------------------------------------------------------------------------------
    !
    s = s_in
    !
    tokenLocal = ' '
    if (present(token)) then
      tokenLocal = token
    endif
    !
    ! first check for quotes
    lquote = .false.
    i0 = index(s_in,quote)
    if (i0 > 0) then
      i1 = index(s,quote,back=.true.)
      if ((i1 > 0).and.(i0 /= i1)) lquote = .true.
    end if
    if (lquote) then
      do i = i0, i1
        if (s(i:i) == tokenLocal) s(i:i) = quote
      end do
    end if
    !
    i = index(s_in,comment)
    if (i > 0) then
      s1 = trim(s(1:i))
    else
      s1 = trim(s)
    endif
    s1 = adjustl(s1)
    if (len_trim(s1) == 1) then
      allocate(words(1))
      words(1) = s1
      return
    endif
    !
    ! count
    ind(1) = 1
    n = 1
    do i = 2, len_trim(s1)
      if ((s1(i:i) == tokenLocal).and. (s1(i-1:i-1) /= tokenLocal)) then
        n = n + 1
        ind(n) = i
      end if
    end do
    ind(n+1) = len_trim(s1)+1
    allocate(words(n))
    do i = 1, n
      read(s1(ind(i):ind(i+1)-1),'(a)') s2
      j = index(trim(s2), tokenLocal, back=.true.)+1
      s2 = s2(j:)
      if (lquote) then
        do j = 1, len_trim(s2)
          if (s2(j:j) == quote) s2(j:j) = ' '
          s2 = adjustl(s2)
        end do
      end if
      words(i) = s2
    end do
    !
    return
  end function getwords

  function fileexist(fname) result(lex)
! ******************************************************************************
    ! -- arguments
    character(len=*), intent(in) :: fname
    logical :: lex
! ------------------------------------------------------------------------------
    inquire(file=fname,exist=lex)
    !
    return
  end function fileexist

end module utilsmod
