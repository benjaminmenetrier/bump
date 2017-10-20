!----------------------------------------------------------------------
! Program: main
!> Purpose: initialization, drivers, finalization
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-C license
!> <br>
!> Copyright © 2017 METEO-FRANCE
!----------------------------------------------------------------------
program main

use driver_hdiag, only: run_hdiag
use driver_nicas, only: run_nicas
use driver_obsop, only: run_obsop
use driver_test, only: run_test
use model_interface, only: model_coord
use module_namelist, only: namtype,namread,namcheck
use tools_display, only: listing_setup,msgerror
use type_bdata, only: bdatatype
use type_geom, only: geomtype,compute_grid_mesh
use type_mpl, only: mpl,mpl_start,mpl_end
use type_ndata, only: ndataloctype
use type_odata, only: odataloctype
use type_randgen, only: rng,create_randgen
use type_timer, only: timertype,timer_start,timer_display

implicit none

! Local variables
type(geomtype),target :: geom
type(namtype),target :: nam
type(bdatatype),allocatable :: bdata(:)
type(ndataloctype),allocatable :: ndataloc(:)
type(odataloctype) :: odataloc
type(timertype) :: timer

!----------------------------------------------------------------------
! Initialize MPL
!----------------------------------------------------------------------

call mpl_start

!----------------------------------------------------------------------
! Initialize timer
!----------------------------------------------------------------------

call timer_start(timer)

!----------------------------------------------------------------------
! Read namelist
!----------------------------------------------------------------------

call namread(nam)

!----------------------------------------------------------------------
! Setup display
!----------------------------------------------------------------------

call listing_setup(nam%colorlog,nam%logpres)

!----------------------------------------------------------------------
! Header
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- You are running nicas -----------------------------------------'
write(mpl%unit,'(a)') '--- Author: Benjamin Menetrier ------------------------------------'
write(mpl%unit,'(a)') '--- Copyright © 2017 METEO-FRANCE------------------ ---------------'
write(mpl%unit,'(a)') '-------------------------------------------------------------------'

!----------------------------------------------------------------------
! Check namelist
!----------------------------------------------------------------------

call namcheck(nam)

!----------------------------------------------------------------------
! Parallel setup
!----------------------------------------------------------------------

write(mpl%unit,'(a,i2,a,i2,a)') '--- Parallelization with ',mpl%nproc,' MPI tasks and ',mpl%nthread,' OpenMP threads'

!----------------------------------------------------------------------
! Initialize random number generator
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Initialize random number generator'
   
rng = create_randgen(nam)

!----------------------------------------------------------------------
! Initialize coordinates
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Initialize coordinates'

call model_coord(nam,geom)

!----------------------------------------------------------------------
! Compute grid mesh
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Compute grid mesh'

! Compute grid mesh
call compute_grid_mesh(nam,geom)

!----------------------------------------------------------------------
! Call hybrid_diag driver
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Call hybrid_diag driver'

call run_hdiag(nam,geom,bdata)

!----------------------------------------------------------------------
! Call NICAS driver
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Call NICAS driver'

call run_nicas(nam,geom,bdata,ndataloc)

if (.false.) then
   !----------------------------------------------------------------------
   ! Call observation operator driver
   !----------------------------------------------------------------------

   write(mpl%unit,'(a)') '-------------------------------------------------------------------'
   write(mpl%unit,'(a,i5,a)') '--- Call observation operator driver'

   call run_obsop(nam,geom,odataloc)   
end if

!----------------------------------------------------------------------
! Call test driver
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Call run_test driver'

call run_test(nam,geom,ndataloc)

!----------------------------------------------------------------------
! Execution stats
!----------------------------------------------------------------------

write(mpl%unit,'(a)') '-------------------------------------------------------------------'
write(mpl%unit,'(a)') '--- Execution stats'

call timer_display(timer)

write(mpl%unit,'(a)') '-------------------------------------------------------------------'

!----------------------------------------------------------------------
! Close listing files
!----------------------------------------------------------------------

if ((mpl%main.and..not.nam%colorlog).or..not.mpl%main) close(unit=mpl%unit)

!----------------------------------------------------------------------
! Finalize MPL
!----------------------------------------------------------------------

call mpl_end

end program main
