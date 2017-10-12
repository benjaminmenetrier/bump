!----------------------------------------------------------------------
! Module: module_apply_nicas.f90
!> Purpose: apply NICAS method
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-C license
!> <br>
!> Copyright © 2017 METEO-FRANCE
!----------------------------------------------------------------------
module module_apply_nicas

use module_apply_convol, only: convol
use module_apply_interp, only: interp,interp_ad
use tools_kinds, only: kind_real
use tools_missing, only: msr
use type_com, only: com_ext,com_red
use type_mpl, only: mpl,mpl_barrier
use type_ndata, only: ndatatype,ndataloctype

implicit none

interface apply_nicas
   module procedure apply_nicas_global
   module procedure apply_nicas_local
end interface

interface apply_nicas_sqrt
   module procedure apply_nicas_sqrt_global
   module procedure apply_nicas_sqrt_local
end interface

interface apply_nicas_sqrt_ad
   module procedure apply_nicas_sqrt_ad_global
   module procedure apply_nicas_sqrt_ad_local
end interface

interface apply_nicas_from_sqrt
   module procedure apply_nicas_from_sqrt_global
   module procedure apply_nicas_from_sqrt_local
end interface

private
public :: apply_nicas,apply_nicas_sqrt,apply_nicas_sqrt_ad,apply_nicas_from_sqrt

contains

!----------------------------------------------------------------------
! Subroutine: apply_nicas_global
!> Purpose: apply NICAS method, global
!----------------------------------------------------------------------
subroutine apply_nicas_global(ndata,fld)

implicit none

! Passed variables
type(ndatatype),intent(in) :: ndata !< Sampling data
real(kind_real),intent(inout) :: fld(ndata%geom%nc0,ndata%geom%nl0)  !< Field

! Local variables
real(kind_real) :: alpha(ndata%ns)

! Adjoint interpolation
call interp_ad(ndata,fld,alpha)

! Convolution
call convol(ndata,alpha)

! Interpolation
call interp(ndata,alpha,fld)

end subroutine apply_nicas_global

!----------------------------------------------------------------------
! Subroutine: apply_nicas_local
!> Purpose: apply NICAS method, local
!----------------------------------------------------------------------
subroutine apply_nicas_local(ndataloc,fld)

implicit none

! Passed variables
type(ndataloctype),intent(in) :: ndataloc !< Sampling data
real(kind_real),intent(inout) :: fld(ndataloc%geom%nc0a,ndataloc%geom%nl0)  !< Field

! Local variables
real(kind_real),allocatable :: alpha(:),alpha_tmp(:)

! Associate
associate(nam=>ndataloc%nam)

! Allocation
allocate(alpha(ndataloc%nsb))

! Adjoint interpolation
call interp_ad(ndataloc,fld,alpha)

! Communication
if (nam%mpicom==1) then
   ! Allocation 
   allocate(alpha_tmp(ndataloc%nsb))

   ! Copy zone B
   alpha_tmp = alpha

   ! Reallocation
   deallocate(alpha)
   allocate(alpha(ndataloc%nsc))

   ! Initialize
   alpha = 0.0

   ! Copy zone B into zone C
   alpha(ndataloc%isb_to_isc) = alpha_tmp

   ! Release memory
   deallocate(alpha_tmp)
elseif (nam%mpicom==2) then
   ! Halo reduction from zone B to zone A
   call com_red(ndataloc%AB,alpha)

   ! Allocation 
   allocate(alpha_tmp(ndataloc%nsb))

   ! Copy zone A
   alpha_tmp = alpha

   ! Reallocation
   deallocate(alpha)
   allocate(alpha(ndataloc%nsc))

   ! Initialize
   alpha = 0.0

   ! Copy zone A into zone C
   alpha(ndataloc%isa_to_isc) = alpha_tmp

   ! Release memory
   deallocate(alpha_tmp)
end if

! Convolution
call convol(ndataloc,alpha)

! Halo reduction from zone C to zone A
call com_red(ndataloc%AC,alpha)

! Halo extension from zone A to zone B
call com_ext(ndataloc%AB,alpha)

! Interpolation
call interp(ndataloc,alpha,fld)

! Release memory
deallocate(alpha)

! End associate
end associate

end subroutine apply_nicas_local

!----------------------------------------------------------------------
! Subroutine: apply_nicas_sqrt_global
!> Purpose: apply NICAS method square-root, global
!----------------------------------------------------------------------
subroutine apply_nicas_sqrt_global(ndata,alpha,fld)

implicit none

! Passed variables
type(ndatatype),intent(in) :: ndata !< Sampling data
real(kind_real),intent(in) :: alpha(ndata%ns) !< Subgrid variable
real(kind_real),intent(out) :: fld(ndata%geom%nc0,ndata%geom%nl0)  !< Field

! Local variable
real(kind_real) :: alpha_tmp(ndata%ns)

! Copy
alpha_tmp = alpha

! Convolution
call convol(ndata,alpha_tmp)

! Interpolation
call interp(ndata,alpha_tmp,fld)

end subroutine apply_nicas_sqrt_global

!----------------------------------------------------------------------
! Subroutine: apply_nicas_sqrt_local
!> Purpose: apply NICAS method square-root, local
!----------------------------------------------------------------------
subroutine apply_nicas_sqrt_local(ndataloc,alpha,fld)

implicit none

! Passed variables
type(ndataloctype),intent(in) :: ndataloc !< Sampling data
real(kind_real),intent(in) :: alpha(ndataloc%nsa) !< Subgrid variable
real(kind_real),intent(out) :: fld(ndataloc%geom%nc0a,ndataloc%geom%nl0)  !< Field

! Local variable
real(kind_real),allocatable :: alpha_tmp(:)

! Allocation
allocate(alpha_tmp(ndataloc%nsa))

! Copy
alpha_tmp = alpha

! Halo extension from zone A to zone C
call com_ext(ndataloc%AC,alpha_tmp)

! Convolution
call convol(ndataloc,alpha_tmp)

! Halo reduction from zone C to zone A
call com_red(ndataloc%AC,alpha_tmp)

! Halo extension from zone A to zone B
call com_ext(ndataloc%AB,alpha_tmp)

! Interpolation
call interp(ndataloc,alpha_tmp,fld)

! Release memory
deallocate(alpha_tmp)

end subroutine apply_nicas_sqrt_local

!----------------------------------------------------------------------
! Subroutine: apply_nicas_sqrt_ad, global
!> Purpose: apply NICAS method square-root adjoint, global
!----------------------------------------------------------------------
subroutine apply_nicas_sqrt_ad_global(ndata,fld,alpha)

implicit none

! Passed variables
type(ndatatype),intent(in) :: ndata    !< Sampling data
real(kind_real),intent(in) :: fld(ndata%geom%nc0,ndata%geom%nl0)  !< Field
real(kind_real),intent(out) :: alpha(ndata%ns) !< Subgrid variable

! Adjoint interpolation
call interp_ad(ndata,fld,alpha)

! Convolution
call convol(ndata,alpha)

end subroutine apply_nicas_sqrt_ad_global

!----------------------------------------------------------------------
! Subroutine: apply_nicas_sqrt_ad_local
!> Purpose: apply NICAS method square-root adjoint, local
!----------------------------------------------------------------------
subroutine apply_nicas_sqrt_ad_local(ndataloc,fld,alpha)

implicit none

! Passed variables
type(ndataloctype),intent(in) :: ndataloc !< Sampling data
real(kind_real),intent(in) :: fld(ndataloc%geom%nc0a,ndataloc%geom%nl0)  !< Field
real(kind_real),intent(out) :: alpha(ndataloc%nsa) !< Subgrid variable

! Local variable
real(kind_real),allocatable :: alpha_tmp(:)

! Allocation
allocate(alpha_tmp(ndataloc%nsb))

! Adjoint interpolation
call interp_ad(ndataloc,fld,alpha_tmp)

! Halo reduction from zone B to zone A
call com_red(ndataloc%AB,alpha_tmp)

! Halo extension from zone A to zone C
call com_ext(ndataloc%AC,alpha_tmp)

! Convolution
call convol(ndataloc,alpha_tmp)

! Halo reduction from zone C to zone A
call com_red(ndataloc%AC,alpha_tmp)

! Copy
alpha = alpha_tmp

! Release memory
deallocate(alpha_tmp)

end subroutine apply_nicas_sqrt_ad_local
!----------------------------------------------------------------------
! Subroutine: apply_nicas_from_sqrt_global
!> Purpose: apply NICAS method from its square-root formulation, global
!----------------------------------------------------------------------
subroutine apply_nicas_from_sqrt_global(ndata,fld)

implicit none

! Passed variables
type(ndatatype),intent(in) :: ndata !< Sampling data
real(kind_real),intent(inout) :: fld(ndata%geom%nc0,ndata%geom%nl0)  !< Field

! Local variables
real(kind_real) :: alpha(ndata%ns)

! Apply square-root adjoint
call apply_nicas_sqrt_ad(ndata,fld,alpha)

! Apply square-root
call apply_nicas_sqrt(ndata,alpha,fld)

end subroutine apply_nicas_from_sqrt_global

!----------------------------------------------------------------------
! Subroutine: apply_nicas_from_sqrt_local
!> Purpose: apply NICAS method from its square-root formulation, local
!----------------------------------------------------------------------
subroutine apply_nicas_from_sqrt_local(ndataloc,fld)

implicit none

! Passed variables
type(ndataloctype),intent(in) :: ndataloc !< Sampling data
real(kind_real),intent(inout) :: fld(ndataloc%geom%nc0a,ndataloc%geom%nl0)  !< Field

! Local variables
real(kind_real) :: alpha(ndataloc%nsa)

! Apply square-root adjoint
call apply_nicas_sqrt_ad(ndataloc,fld,alpha)

! Apply square-root
call apply_nicas_sqrt(ndataloc,alpha,fld)

end subroutine apply_nicas_from_sqrt_local

end module module_apply_nicas
