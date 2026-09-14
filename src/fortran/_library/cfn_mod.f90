module cfn_mod
! cfn_unique_i and cfn_idx_get_i, moved verbatim from utl.f90 (retired; see
! design.md). Bodies unchanged except 'end' -> 'end function' and the external
! declaration of cfn_idx_get_i inside cfn_unique_i commented out (it is a
! module procedure here).
  implicit none
contains

! ******************************************************************************

      function cfn_unique_i(array,nin,mv)

! description:
! ------------------------------------------------------------------------------
! takes the unique values from an array and places them sorted in
! the first cells

! declaration section
! ------------------------------------------------------------------------------

      implicit none


! function declaration
      integer    cfn_unique_i ! return value: number of unique values
                              !               0 only with mv in array


! arguments
      integer   nin           ! (I) length array

      integer   array(nin),&  ! (I/O) in : input array
                              !       out: unique, sorted values
                mv            ! (I)   missing value


! local variables
      integer   n,nf,i,j,index

      integer   val           ! must be the same type as array()


! functions
      ! (cfn_idx_get_i is a module procedure)


! include files


! program section
! ------------------------------------------------------------------------------

! find unique values
      n=0   ! number of unique values found
      do i=1,nin
         val=array(i)
         if (val.ne.mv) then
            if (n.eq.0) then
               ! first not "missing value" found
               n=n+1
               array(n)=val
            else
               nf=cfn_idx_get_i(val,array,n,index)
               if (nf.eq.0) then
                  ! none found, index now is the position where the element
                  ! must be inserted
                  do j=n,index,-1
                     array(j+1)=array(j)
                  enddo
                  n=n+1
                  array(index)=val
               endif
            endif
         endif
      enddo


! number of found values returned as output
      cfn_unique_i=n


! end of program
      return
end function

! ******************************************************************************

      function cfn_idx_get_i(sv,sid,nid,index)

! description:
! ------------------------------------------------------------------------------
! find the index number of the value sv in array sid
! search method is binary search

! declaration section
! ------------------------------------------------------------------------------

      implicit none


! function declaration
      integer   cfn_idx_get_i   ! return value: #: number of found
                                !                  matched elements


! arguments
      integer   index,&         ! (O) return index number
                                !     the index number is the first
                                !     matched value in array sid
                                !     if no value matched index is the
                                !     position where sv can be inserted
                                !     If sv > sid(nin) then index=nin+1
                nid             ! (I) number of elements in sid array

      integer   sv,&            ! (I) value to be searched in sid
                sid(nid)        ! (I) values array


! local variables
      integer   i,ib,im,ie,ntry

      real      log2
      parameter (log2=0.6931471)

      logical   continue


! functions


! include files


! program section
! ------------------------------------------------------------------------------


! binary search

      ib=0
      ie=nid

      ntry=2+int(log(nid*1.0)/log2)

      do i=1,ntry
         im=(ie+1 + ib)/2
         if (sv.gt.sid(im)) then
            ib=im
         else
            ie=im
         endif
      enddo


! find full interval
      ie=im
      ib=im

      continue = ib.gt.1
      do while (continue)
         if (sid(ib-1).ge.sv) then
            ib=ib-1
            continue = ib.gt.1
         else
            continue = .false.
         endif
      enddo

      continue = ie.lt.nid
      do while (continue)
         if (sid(ie+1).eq.sv) then
            ie=ie+1
            continue = ie.lt.nid
         else
            continue = .false.
         endif
      enddo


! fill in results
      if (sid(ib).eq.sv) then
         index=ib
         cfn_idx_get_i=ie-ib+1
      else
         ! value not found
         index=ib
         if (sv.gt.sid(index)) index=index+1
         cfn_idx_get_i=0
      endif


! end of program
      return
end function

! ******************************************************************************

end module cfn_mod
