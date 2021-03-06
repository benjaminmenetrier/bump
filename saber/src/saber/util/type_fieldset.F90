!----------------------------------------------------------------------
! Module: tools_atlas
! Purpose: random numbers generator derived type
! Author: Benjamin Menetrier
! Licensing: this code is distributed under the CeCILL-C license
! Copyright © 2015-... UCAR, CERFACS, METEO-FRANCE and IRIT
!----------------------------------------------------------------------

module type_fieldset

use atlas_module, only: atlas_fieldset,atlas_field,atlas_functionspace,atlas_real
use tools_atlas, only: field_to_array,field_from_array
use tools_kinds, only: kind_real
use type_mpl, only: mpl_type

implicit none

type,extends(atlas_fieldset) :: fieldset_type
   character(len=1024),allocatable :: variables(:) ! Variables names
   character(len=1024) :: lev2d                    ! Level for 2D variables
   integer :: il2d                                 ! Level index for 2D variables
   logical,allocatable :: mask3d(:,:)              ! 3D mask
   real(kind_real) :: msvalr                       ! Missing value (real)
contains
   procedure :: init => fieldset_init
   procedure :: copy_fields => fieldset_copy_fields
   procedure :: pass_fields => fieldset_pass_fields
   procedure :: zero_fields => fieldset_zero_fields
   procedure :: add_fields => fieldset_add_fields
   procedure :: sub_fields => fieldset_sub_fields
   procedure :: fieldset_mult_fields_scalar
   procedure :: fieldset_mult_fields_fieldset
   generic :: mult_fields => fieldset_mult_fields_scalar,fieldset_mult_fields_fieldset
   procedure :: div_fields => fieldset_div_fields
   procedure :: square_fields => fieldset_square_fields
   procedure :: sqrt_fields => fieldset_sqrt_fields
   procedure :: fieldset_to_array_single
   procedure :: fieldset_to_array_all
   generic :: to_array => fieldset_to_array_single,fieldset_to_array_all
   procedure :: fieldset_from_array_single
   procedure :: fieldset_from_array_all
   generic :: from_array => fieldset_from_array_single,fieldset_from_array_all
end type

private
public :: fieldset_type

contains

!----------------------------------------------------------------------
! Subroutine: fieldset_init
! Purpose: initialized fieldset
!----------------------------------------------------------------------
subroutine fieldset_init(fieldset,mpl,nmga,nl,gmask,variables,lev2d,afunctionspace)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset                  ! Fieldset
type(mpl_type),intent(inout) :: mpl                             ! MPI data
integer,intent(in) :: nmga                                      ! Number of gridpoints
integer,intent(in) :: nl                                        ! Number of levels
logical,intent(in) :: gmask(nmga,nl)                            ! Geographical mask
character(len=*),intent(in) :: variables(:)                     ! Variables names
character(len=*),intent(in) :: lev2d                            ! Level for 2D variables
type(atlas_functionspace),intent(in),optional :: afunctionspace ! ATLAS function space

! Local variables
integer :: iv
character(len=1024) :: fieldname
character(len=1024),parameter :: subr = 'fieldset_init'
type(atlas_field) :: afield

! Initialization
if (fieldset%is_null()) fieldset = atlas_fieldset()

! Allocation
if (.not.allocated(fieldset%mask3d)) allocate(fieldset%mask3d(nmga,nl))
if (.not.allocated(fieldset%variables)) allocate(fieldset%variables(size(variables)))

! Copy
fieldset%mask3d = gmask
fieldset%msvalr = mpl%msv%valr
do iv=1,size(variables)
   fieldset%variables(iv) = trim(variables(iv))
end do
if (trim(lev2d)=='first') then
   fieldset%il2d = 1
elseif (trim(lev2d)=='last') then
   fieldset%il2d = nl
else
   call mpl%abort(subr,'wrong lev2d in fieldset')
end if
fieldset%lev2d = trim(lev2d)

if (present(afunctionspace)) then
   ! Create (empty) fields if necessary
   do iv=1,size(variables)
      ! Check field existence
      if (.not.fieldset%has_field(variables(iv))) then
         ! Create field
         afield = afunctionspace%create_field(name=variables(iv),kind=atlas_real(kind_real),levels=nl)

         ! Add field
         call fieldset%add(afield)

         ! Release pointer
         call afield%final()
      end if
   end do
end if

end subroutine fieldset_init

!----------------------------------------------------------------------
! Subroutine: fieldset_copy_fields
! Purpose: copy fieldset
!----------------------------------------------------------------------
subroutine fieldset_copy_fields(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv,rank_in
real(kind_real),pointer :: ptr_1_in(:),ptr_2_in(:,:),ptr_2_out(:,:)
type(atlas_field) :: afield_in,afield_out

! Loop over fields
do iv=1,size(fieldset_out%variables)
   ! Fields
   afield_in = fieldset_in%field(fieldset_out%variables(iv))
   afield_out = fieldset_out%field(fieldset_out%variables(iv))

   ! Rank of input field
   rank_in = afield_in%rank()

   ! Copy data
   if (rank_in==1) then
      call afield_in%data(ptr_1_in)
      call afield_out%data(ptr_2_out)
      ptr_2_out(fieldset_out%il2d,:) = ptr_1_in
   else
      call afield_in%data(ptr_2_in)
      call afield_out%data(ptr_2_out)
      ptr_2_out = ptr_2_in
   end if

   ! Add field
   call fieldset_out%add(afield_out)

   ! Release pointers
   call afield_in%final()
   call afield_out%final()
end do

end subroutine fieldset_copy_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_pass_fields
! Purpose: pass ATLAS fields from a fieldset to another
!----------------------------------------------------------------------
subroutine fieldset_pass_fields(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv
type(atlas_field) :: afield

do iv=1,size(fieldset_out%variables)
   ! Get input field
   afield = fieldset_in%field(fieldset_out%variables(iv))

   ! Add field to output fieldset
   call fieldset_out%add(afield)
end do

end subroutine fieldset_pass_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_zero_fields
! Purpose: set fieldset to zero
!----------------------------------------------------------------------
subroutine fieldset_zero_fields(fieldset)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset

! Local variables
integer :: iv,i,il
real(kind_real),pointer :: ptr_2(:,:)
type(atlas_field) :: afield

! Loop over fields
do iv=1,size(fieldset%variables)
   ! Field
   afield = fieldset%field(fieldset%variables(iv))

   ! Set data to zero
   call afield%data(ptr_2)
   do il=1,size(fieldset%mask3d,2)
      do i=1,size(fieldset%mask3d,1)
         if (fieldset%mask3d(i,il)) then
            ptr_2(il,i) = 0.0
         else
            ptr_2(il,i) = fieldset%msvalr
         end if
      end do
   end do

   ! Release pointer
   call afield%final()
end do

end subroutine fieldset_zero_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_add_fields
! Purpose: add fieldset
!----------------------------------------------------------------------
subroutine fieldset_add_fields(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv,rank_in,i,il
real(kind_real),pointer :: ptr_1_in(:),ptr_2_in(:,:),ptr_2_out(:,:)
type(atlas_field) :: afield_in,afield_out

! Loop over fields
do iv=1,size(fieldset_out%variables)
   ! Fields
   afield_in = fieldset_in%field(fieldset_out%variables(iv))
   afield_out = fieldset_out%field(fieldset_out%variables(iv))

   ! Rank of input field
   rank_in = afield_in%rank()

   ! Add data
   if (rank_in==1) then
      call afield_in%data(ptr_1_in)
      call afield_out%data(ptr_2_out)
      do i=1,size(fieldset_out%mask3d,1)
         if (fieldset_out%mask3d(i,fieldset_out%il2d)) ptr_2_out(fieldset_out%il2d,i) = ptr_2_out(fieldset_out%il2d,i) &
 & +ptr_1_in(i)
      end do
   else
      call afield_in%data(ptr_2_in)
      call afield_out%data(ptr_2_out)
      do il=1,size(fieldset_out%mask3d,2)
         do i=1,size(fieldset_out%mask3d,1)
            if (fieldset_out%mask3d(i,il)) ptr_2_out(il,i) = ptr_2_out(il,i)+ptr_2_in(il,i)
         end do
      end do
   end if

   ! Release pointers
   call afield_in%final()
   call afield_out%final()
end do

end subroutine fieldset_add_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_sub_fields
! Purpose: subtract fieldset
!----------------------------------------------------------------------
subroutine fieldset_sub_fields(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv,rank_in,i,il
real(kind_real),pointer :: ptr_1_in(:),ptr_2_in(:,:),ptr_2_out(:,:)
type(atlas_field) :: afield_in,afield_out

! Loop over fields
do iv=1,size(fieldset_out%variables)
   ! Fields
   afield_in = fieldset_in%field(fieldset_out%variables(iv))
   afield_out = fieldset_out%field(fieldset_out%variables(iv))

   ! Rank of input field
   rank_in = afield_in%rank()

   ! Subtract data
   if (rank_in==1) then
      call afield_in%data(ptr_1_in)
      call afield_out%data(ptr_2_out)
      do i=1,size(fieldset_out%mask3d,1)
         if (fieldset_out%mask3d(i,fieldset_out%il2d)) ptr_2_out(fieldset_out%il2d,i) = ptr_2_out(fieldset_out%il2d,i) &
 & -ptr_1_in(i)
      end do
   else
      call afield_in%data(ptr_2_in)
      call afield_out%data(ptr_2_out)
      do il=1,size(fieldset_out%mask3d,2)
         do i=1,size(fieldset_out%mask3d,1)
            if (fieldset_out%mask3d(i,il)) ptr_2_out(il,i) = ptr_2_out(il,i)-ptr_2_in(il,i)
         end do
      end do
   end if

   ! Release pointers
   call afield_in%final()
   call afield_out%final()
end do

end subroutine fieldset_sub_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_mult_fields_scalar
! Purpose: multiply fieldset with a scalar
!----------------------------------------------------------------------
subroutine fieldset_mult_fields_scalar(fieldset,factor)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset
real(kind_real),intent(in) :: factor           ! Scalar factor

! Local variables
integer :: iv,i,il
real(kind_real),pointer :: ptr_2(:,:)
type(atlas_field) :: afield

! Loop over fields
do iv=1,size(fieldset%variables)
   ! Field
   afield = fieldset%field(fieldset%variables(iv))

   ! Multiply data with a factor
   call afield%data(ptr_2)
   do il=1,size(fieldset%mask3d,2)
      do i=1,size(fieldset%mask3d,1)
         if (fieldset%mask3d(i,il)) ptr_2(il,i) = ptr_2(il,i)*factor
      end do
   end do

   ! Release pointer
   call afield%final()
end do

end subroutine fieldset_mult_fields_scalar

!----------------------------------------------------------------------
! Subroutine: fieldset_mult_fields_fieldset
! Purpose: multiply fieldset with another fieldset
!----------------------------------------------------------------------
subroutine fieldset_mult_fields_fieldset(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv,rank_in,i,il
real(kind_real),pointer :: ptr_1_in(:),ptr_2_in(:,:),ptr_2_out(:,:)
type(atlas_field) :: afield_in,afield_out

! Loop over fields
do iv=1,size(fieldset_out%variables)
   ! Fields
   afield_in = fieldset_in%field(fieldset_out%variables(iv))
   afield_out = fieldset_out%field(fieldset_out%variables(iv))

   ! Rank of input field
   rank_in = afield_in%rank()

   ! Multiply data
   if (rank_in==1) then
      call afield_in%data(ptr_1_in)
      call afield_out%data(ptr_2_out)
      do i=1,size(fieldset_out%mask3d,1)
         if (fieldset_out%mask3d(i,fieldset_out%il2d)) ptr_2_out(fieldset_out%il2d,i) = ptr_2_out(fieldset_out%il2d,i) &
 & *ptr_1_in(i)
      end do
   else
      call afield_in%data(ptr_2_in)
      call afield_out%data(ptr_2_out)
      do il=1,size(fieldset_out%mask3d,2)
         do i=1,size(fieldset_out%mask3d,1)
            if (fieldset_out%mask3d(i,il)) ptr_2_out(il,i) = ptr_2_out(il,i)*ptr_2_in(il,i)
         end do
      end do
   end if

   ! Release pointers
   call afield_in%final()
   call afield_out%final()
end do

end subroutine fieldset_mult_fields_fieldset

!----------------------------------------------------------------------
! Subroutine: fieldset_div_fields
! Purpose: divide fieldset
!----------------------------------------------------------------------
subroutine fieldset_div_fields(fieldset_out,fieldset_in)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset_out ! Output fieldset
type(fieldset_type),intent(in) :: fieldset_in      ! Input fieldset

! Local variables
integer :: iv,rank_in,i,il
real(kind_real),pointer :: ptr_1_in(:),ptr_2_in(:,:),ptr_2_out(:,:)
type(atlas_field) :: afield_in,afield_out

! Loop over fields
do iv=1,size(fieldset_out%variables)
   ! Fields
   afield_in = fieldset_in%field(fieldset_out%variables(iv))
   afield_out = fieldset_out%field(fieldset_out%variables(iv))

   ! Rank of input field
   rank_in = afield_in%rank()

   ! Divide data
   if (rank_in==1) then
      call afield_in%data(ptr_1_in)
      call afield_out%data(ptr_2_out)
      do i=1,size(fieldset_out%mask3d,1)
         if (fieldset_out%mask3d(i,fieldset_out%il2d)) ptr_2_out(fieldset_out%il2d,i) = ptr_2_out(fieldset_out%il2d,i) &
 & /ptr_1_in(i)
      end do
   else
      call afield_in%data(ptr_2_in)
      call afield_out%data(ptr_2_out)
      do il=1,size(fieldset_out%mask3d,2)
         do i=1,size(fieldset_out%mask3d,1)
            if (fieldset_out%mask3d(i,il)) ptr_2_out(il,i) = ptr_2_out(il,i)/ptr_2_in(il,i)
         end do
      end do
   end if

   ! Release pointers
   call afield_in%final()
   call afield_out%final()
end do

end subroutine fieldset_div_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_square_fields
! Purpose: square fieldset
!----------------------------------------------------------------------
subroutine fieldset_square_fields(fieldset)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset

! Local variables
integer :: iv,i,il
real(kind_real),pointer :: ptr_2(:,:)
type(atlas_field) :: afield

! Loop over fields
do iv=1,size(fieldset%variables)
   ! Field
   afield = fieldset%field(fieldset%variables(iv))

   ! Square data
   call afield%data(ptr_2)
   do il=1,size(fieldset%mask3d,2)
      do i=1,size(fieldset%mask3d,1)
         if (fieldset%mask3d(i,il)) ptr_2(il,i) = ptr_2(il,i)**2
      end do
   end do

   ! Release pointer
   call afield%final()
end do

end subroutine fieldset_square_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_sqrt_fields
! Purpose: take square-root of the fieldset
!----------------------------------------------------------------------
subroutine fieldset_sqrt_fields(fieldset)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset

! Local variables
integer :: iv,i,il
real(kind_real),pointer :: ptr_2(:,:)
type(atlas_field) :: afield

! Loop over fields
do iv=1,size(fieldset%variables)
   ! Field
   afield = fieldset%field(fieldset%variables(iv))

   ! Take square-root of data
   call afield%data(ptr_2)
   do il=1,size(fieldset%mask3d,2)
      do i=1,size(fieldset%mask3d,1)
         if (fieldset%mask3d(i,il)) ptr_2(il,i) = sqrt(ptr_2(il,i))
      end do
   end do

   ! Release pointer
   call afield%final()
end do

end subroutine fieldset_sqrt_fields

!----------------------------------------------------------------------
! Subroutine: fieldset_to_array_single
! Purpose: convert fieldset to Fortran array, single field
!----------------------------------------------------------------------
subroutine fieldset_to_array_single(fieldset,mpl,iv,fld)

implicit none

! Passed variables
class(fieldset_type),intent(in) :: fieldset ! Fieldset
type(mpl_type),intent(inout) :: mpl         ! MPI data
integer,intent(in) :: iv                    ! Variable index
real(kind_real),intent(out) :: fld(:,:)     ! Fortran array

! Local variables
character(len=1024),parameter :: subr = 'fieldset_to_array_single'
type(atlas_field) :: afield

! Check number of variables
if (size(fieldset%variables)<iv) call mpl%abort(subr,'inconsistency in number of variables')

! Get field
afield = fieldset%field(fieldset%variables(iv))

! ATLAS field to Fortran array
call field_to_array(mpl,afield,fld,fieldset%lev2d)

! Release pointer
call afield%final()

end subroutine fieldset_to_array_single

!----------------------------------------------------------------------
! Subroutine: fieldset_to_array_all
! Purpose: convert fieldset to Fortran array, all fields
!----------------------------------------------------------------------
subroutine fieldset_to_array_all(fieldset,mpl,fld)

implicit none

! Passed variables
class(fieldset_type),intent(in) :: fieldset ! Fieldset
type(mpl_type),intent(inout) :: mpl         ! MPI data
real(kind_real),intent(out) :: fld(:,:,:)   ! Fortran array

! Local variables
integer :: iv
character(len=1024),parameter :: subr = 'fieldset_to_array_all'

! Check number of variables
if (size(fieldset%variables)/=size(fld,3)) call mpl%abort(subr,'inconsistency in number of variables')

! Loop over fields
do iv=1,size(fieldset%variables)
   call fieldset%to_array(mpl,iv,fld(:,:,iv))
end do

end subroutine fieldset_to_array_all

!----------------------------------------------------------------------
! Subroutine: fieldset_from_array_single
! Purpose: convert Fortran array to fieldset, single field
!----------------------------------------------------------------------
subroutine fieldset_from_array_single(fieldset,mpl,iv,fld)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset
type(mpl_type),intent(inout) :: mpl            ! MPI data
integer,intent(in) :: iv                       ! Variable index
real(kind_real),intent(in) :: fld(:,:)         ! Fortran array

! Local variables
character(len=1024),parameter :: subr = 'fieldset_from_array_single'
type(atlas_field) :: afield

! Check number of variables
if (size(fieldset%variables)<iv) call mpl%abort(subr,'inconsistency in number of variables')

! Get field
afield = fieldset%field(fieldset%variables(iv))

! Fortran array to ATLAS field
call field_from_array(mpl,fld,afield,fieldset%lev2d)

! Release pointer
call afield%final()

end subroutine fieldset_from_array_single

!----------------------------------------------------------------------
! Subroutine: fieldset_from_array_all
! Purpose: convert Fortran array to fieldset, all fields
!----------------------------------------------------------------------
subroutine fieldset_from_array_all(fieldset,mpl,fld)

implicit none

! Passed variables
class(fieldset_type),intent(inout) :: fieldset ! Fieldset
type(mpl_type),intent(inout) :: mpl            ! MPI data
real(kind_real),intent(in) :: fld(:,:,:)       ! Fortran array

! Local variables
integer :: iv
character(len=1024),parameter :: subr = 'fieldset_from_array_all'

! Check number of variables
if (size(fieldset%variables)/=size(fld,3)) call mpl%abort(subr,'inconsistency in number of variables')

! Loop over fields
do iv=1,size(fieldset%variables)
   call fieldset%from_array(mpl,iv,fld(:,:,iv))
end do

end subroutine fieldset_from_array_all

end module type_fieldset
