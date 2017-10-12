!----------------------------------------------------------------------
! Module: module_dualens.f90
!> Purpose: dual-ensemble routines
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-B license
!> <br>
!> Copyright © 2015 UCAR, CERFACS and METEO-FRANCE
!----------------------------------------------------------------------
module module_dualens

use module_fit, only: compute_fit
use tools_display, only: msgwarning
use tools_fit, only: ver_smooth
use tools_kinds, only: kind_real
use tools_missing, only: msr,isnotmsr,isallnotmsr
use type_avg, only: avgtype
use type_curve, only: curvetype,curve_normalization
use type_hdata, only: hdatatype
implicit none

private
public :: compute_dualens

contains

!----------------------------------------------------------------------
! Subroutine: compute_dualens
!> Purpose: compute dual-ensemble hybridization formulae
!----------------------------------------------------------------------
subroutine compute_dualens(hdata,avg,avg_lr,lfit,loc_deh,loc_deh_lr)

implicit none

! Passed variables
type(hdatatype),intent(in) :: hdata                  !< Sampling data
type(avgtype),intent(in) :: avg                      !< Averaged statistics
type(avgtype),intent(in) :: avg_lr                   !< Low-resolution averaged statistics
logical,intent(in) :: lfit
type(curvetype),intent(inout) :: loc_deh    !< Adapted high-resolution localizations
type(curvetype),intent(inout) :: loc_deh_lr !< Adapted low-resolution localizations

! Local variables
integer :: il0,jl0,ic
real(kind_real) :: num(hdata%nam%nc),num_lr(hdata%nam%nc),den(hdata%nam%nc)

! Associate
associate(nam=>hdata%nam,geom=>hdata%geom)

! Compute raw dual-ensemble hybridization
do jl0=1,geom%nl0
   do il0=1,geom%nl0
      do ic=1,nam%nc
         if (isnotmsr(avg%m11asysq(ic,il0,jl0)).and.isnotmsr(avg%m11sq(ic,il0,jl0)) &
       & .and.isnotmsr(avg_lr%m11lrm11asy(ic,il0,jl0)).and.isnotmsr(avg_lr%m11lrm11(ic,il0,jl0)) &
       & .and.isnotmsr(avg_lr%m11sq(ic,il0,jl0)).and.isnotmsr(avg_lr%m11lrm11asy(ic,il0,jl0))) then
            num(ic) = avg%m11asysq(ic,il0,jl0)*avg_lr%m11sq(ic,il0,jl0) &
                    & -avg_lr%m11lrm11asy(ic,il0,jl0)*avg_lr%m11lrm11(ic,il0,jl0)
            num_lr(ic) = avg_lr%m11lrm11asy(ic,il0,jl0)*avg%m11sq(ic,il0,jl0) &
                       & -avg%m11asysq(ic,il0,jl0)*avg_lr%m11lrm11(ic,il0,jl0)
            den(ic) = avg%m11sq(ic,il0,jl0)*avg_lr%m11sq(ic,il0,jl0)-avg_lr%m11lrm11(ic,il0,jl0)**2
            if ((num(ic)>0.0).and.(den(ic)>0.0)) then
               loc_deh%raw(ic,il0,jl0) = num(ic)/den(ic)
               loc_deh_lr%raw(ic,il0,jl0) = num_lr(ic)/den(ic)
            end if
         end if
      end do
   end do
end do

! Compute dual-ensemble hybridization fits
if (lfit) then
   ! Compute fit weight
   if (nam%fit_wgt) then
      loc_deh%fit_wgt = abs(avg%cor)
      loc_deh_lr%fit_wgt = abs(avg_lr%cor)
   end if

   ! Compute initial fit
   call compute_fit(hdata%nam,hdata%geom,loc_deh)
   call compute_fit(hdata%nam,hdata%geom,loc_deh_lr)
end if

! Normalize dual-ensemble hybridization
call curve_normalization(hdata,loc_deh)
call curve_normalization(hdata,loc_deh_lr)

! End associate
end associate

end subroutine compute_dualens

end module module_dualens
