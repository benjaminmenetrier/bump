!----------------------------------------------------------------------
! Module: module_apply_bens.f90
!> Purpose: apply localized ensemble covariance
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-C license
!> <br>
!> Copyright © 2017 METEO-FRANCE
!----------------------------------------------------------------------
module module_apply_bens

use module_apply_localization, only: apply_localization,apply_localization_from_sqrt
use tools_display, only: msgerror
use tools_kinds, only: kind_real
use tools_missing, only: msr,isnotmsr
use type_bpar, only: bpartype
use type_geom, only: geomtype
use type_mpl, only: mpl
use type_nam, only: namtype
use type_ndata, only: ndataloctype

implicit none

private
public :: apply_bens

contains

!----------------------------------------------------------------------
! Subroutine: apply_bens
!> Purpose: apply localized ensemble covariance
!----------------------------------------------------------------------
subroutine apply_bens(nam,geom,bpar,ndataloc,ens1,fld)

implicit none

! Passed variables
type(namtype),target,intent(in) :: nam                                            !< Namelist
type(geomtype),target,intent(in) :: geom                                          !< Geometry
type(bpartype),target,intent(in) :: bpar                                          !< Blocal parameters
type(ndataloctype),intent(in) :: ndataloc(bpar%nb+1)                              !< NICAS data, local
real(kind_real),intent(in) :: ens1(geom%nc0a,geom%nl0,nam%nv,nam%nts,nam%ens1_ne) !< Ensemble 1
real(kind_real),intent(inout) :: fld(geom%nc0a,geom%nl0,nam%nv,nam%nts)           !< Field, local

! Local variable
integer :: ie,ib,its,iv,ic0a
real(kind_real) :: fld_copy(geom%nc0a,geom%nl0,nam%nv,nam%nts),fld_tmp(geom%nc0a,geom%nl0,nam%nv,nam%nts)
real(kind_real) :: mean(geom%nc0a,geom%nl0,nam%nv,nam%nts),pert(geom%nc0a,geom%nl0,nam%nv,nam%nts)

! Compute mean
mean = sum(ens1,dim=5)/float(nam%ens1_ne)

! Apply adjoint transform vector
do ib=1,bpar%nb
   if (bpar%diag_block(ib)) then
      its = bpar%ib_to_its(ib)
      iv = bpar%ib_to_iv(ib)
      do ic0a=1,geom%nc0a
         fld_copy(ic0a,:,its,iv) = matmul(transpose(ndataloc(ib)%trans),fld(ic0a,:,its,iv))
      end do
   end if
end do

! Apply localized ensemble covariance formula
fld = 0.0
do ie=1,nam%ens1_ne
   ! Compute perturbation
   pert = (ens1(:,:,:,:,ie)-mean)/sqrt(float(nam%ens1_ne-1))

   ! Apply inverse transform
   do ib=1,bpar%nb
      if (bpar%diag_block(ib)) then
         its = bpar%ib_to_its(ib)
         iv = bpar%ib_to_iv(ib)
         do ic0a=1,geom%nc0a
            pert(ic0a,:,its,iv) = matmul(ndataloc(ib)%transinv,pert(ic0a,:,its,iv))
         end do
      end if
   end do

   ! Schur product
   fld_tmp = pert*fld_copy

   ! Apply localization
   if (nam%lsqrt) then
      call apply_localization_from_sqrt(nam,geom,bpar,ndataloc,fld_tmp)
   else
      call apply_localization(nam,geom,bpar,ndataloc,fld_tmp)
   end if

   ! Schur product
   fld = fld+fld_tmp*pert
end do

! Apply direct transform
do ib=1,bpar%nb
   if (bpar%diag_block(ib)) then
      its = bpar%ib_to_its(ib)
      iv = bpar%ib_to_iv(ib)
      do ic0a=1,geom%nc0a
         fld(ic0a,:,its,iv) = matmul(ndataloc(ib)%trans,fld(ic0a,:,its,iv))
      end do
   end if
end do

end subroutine apply_bens

end module module_apply_bens
