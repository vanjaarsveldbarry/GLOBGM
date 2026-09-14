program mf6ggmpost
  ! -- modules
  use utilsmod, only: i4b, mxslen, open_file, logmsg, errmsg, getwords, ta
  use mf6_post_module, only: tPostSol, mf6_post_init_top, &
    gncol, gnrow, gnlay, gxmin, gymin, gcs, sdate, comment, include_sea, r8nodata
  !
  implicit none
  !
  ! -- locals
  type(tPostSol) :: postsol
  character(len=mxslen) :: f, s, top
  character(len=mxslen), dimension(:), allocatable :: sa
  integer(i4b) :: iu, i, npost
! ------------------------------------------------------------------------------
  !
  if (command_argument_count() /= 1) then
    call errmsg('Usage: mf6ggmpost <inp>')
  end if
  call get_command_argument(1, f)
  !
  call open_file(f, iu, 'r')
  read(iu,*) gncol, gnrow, gnlay, gxmin, gymin, gcs
  read(iu,*) sdate
  read(iu,'(a)') top
  read(iu,*) i
  include_sea = (i == 1)
  read(iu,*) r8nodata
  read(iu,*) npost
  !
  if (include_sea) then
    call logmsg('***** WARNING: output for sea cells enabled! *****')
  end if
  !
  call mf6_post_init_top(top)
  !
  do i = 1, npost
    call logmsg('***** Processing '//ta((/i/))//'/'//ta((/npost/))//'...')
    read(iu,'(a)') s
    if (s(1:1) == comment) then
      call logmsg('Skipping...')
      cycle
    end if
    sa = getwords(s)
    call postsol%init(sa)
    call postsol%write()
    call postsol%clean()
  end do
  close(iu)
  !
end program
