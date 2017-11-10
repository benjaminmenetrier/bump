!----------------------------------------------------------------------
! Module: module_localization.f90
!> Purpose: localization routines
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-B license
!> <br>
!> Copyright © 2015 UCAR, CERFACS and METEO-FRANCE
!----------------------------------------------------------------------
module module_localization

use module_fit, only: compute_fit
use tools_display, only: msgwarning,msgerror
use tools_fit, only: ver_smooth
use tools_kinds, only: kind_real
use tools_missing, only: msr,isnotmsr,isallnotmsr
use type_avg, only: avgtype
use type_curve, only: curvetype,curve_normalization
use type_hdata, only: hdatatype
implicit none

interface compute_localization
  module procedure compute_localization
  module procedure compute_localization_local
end interface

private
public :: compute_localization

contains

!----------------------------------------------------------------------
! Subroutine: compute_localization
!> Purpose: compute localization
!----------------------------------------------------------------------
subroutine compute_localization(hdata,ib,avg,loc)

implicit none

! Passed variables
type(hdatatype),intent(in) :: hdata           !< Sampling data
integer,intent(in) :: ib !< Block index
type(avgtype),intent(in) :: avg               !< Averaged statistics
type(curvetype),intent(inout) :: loc !< Localizations

! Local variables
integer :: il0,jl0,ic

! Associate
associate(nam=>hdata%nam,geom=>hdata%geom,bpar=>hdata%bpar)

! Compute raw localization
do jl0=1,geom%nl0
   do il0=1,bpar%nl0(ib)
      do ic=1,bpar%icmax(ib)
         if (isnotmsr(avg%m11asysq(ic,il0,jl0)).and.isnotmsr(avg%m11sq(ic,il0,jl0))) &
       & loc%raw(ic,il0,jl0) = avg%m11asysq(ic,il0,jl0)/avg%m11sq(ic,il0,jl0)
      end do
   end do
end do

! Normalize localization
call curve_normalization(hdata,ib,loc)

! Compute localization fits
if (bpar%fit_block(ib)) then
   ! Compute fit weight
   if (nam%fit_wgt) loc%fit_wgt = abs(avg%cor)

   ! Compute initial fit
   call compute_fit(hdata,loc)
end if

! End associate
end associate

end subroutine compute_localization

!----------------------------------------------------------------------
! Subroutine: compute_localization_local
!> Purpose: compute localization, local
!----------------------------------------------------------------------
subroutine compute_localization_local(hdata,ib,avg,loc)

implicit none

! Passed variables
type(hdatatype),intent(in) :: hdata           !< Sampling data
integer,intent(in) :: ib !< Block index
type(avgtype),intent(in) :: avg(hdata%nc2)               !< Averaged statistics
type(curvetype),intent(inout) :: loc(hdata%nc2) !< Localizations

! Local variables
integer :: ic2

! Loop over points
!$omp parallel do private(ic2)
do ic2=1,hdata%nc2
   call compute_localization(hdata,ib,avg(ic2),loc(ic2))
end do
!$omp end parallel do

end subroutine compute_localization_local

end module module_localization
