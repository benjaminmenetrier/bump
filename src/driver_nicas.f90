!----------------------------------------------------------------------
! Module: driver_nicas
!> Purpose: nicas driver
!> <br>
!> Author: Benjamin Menetrier
!> <br>
!> Licensing: this code is distributed under the CeCILL-C license
!> <br>
!> Copyright © 2017 METEO-FRANCE
!----------------------------------------------------------------------
module driver_nicas

use module_mpi, only: compute_mpi
use module_normalization, only: compute_normalization
use module_parameters, only: compute_parameters
use module_test, only: test_adjoints,test_pos_def,test_mpi
use tools_const, only: eigen_init,pi
use tools_display, only: msgerror
use type_bdata, only: bdatatype
use type_bpar, only: bpartype
use type_ctree, only: ctreetype,create_ctree,find_nearest_neighbors,delete_ctree
use type_geom, only: geomtype
use type_mpl, only: mpl
use type_nam, only: namtype
use type_ndata, only: ndatatype,ndataloctype,ndata_dealloc,ndata_read,ndataloc_read, &
  & ndata_write,ndataloc_write,ndata_write_mpi_summary

implicit none

private
public :: run_nicas

contains

!----------------------------------------------------------------------
! Subroutine: run_nicas
!> Purpose: NICAS
!----------------------------------------------------------------------
subroutine run_nicas(nam,geom,bpar,bdata,ndataloc)

implicit none

! Passed variables
type(namtype),target,intent(in) :: nam !< Namelist variables
type(geomtype),target,intent(inout) :: geom    !< Sampling data
type(bpartype),target,intent(in) :: bpar    !< Sampling data
type(bdatatype),intent(in) :: bdata(bpar%nb+1) !< B data
type(ndataloctype),allocatable,intent(inout) :: ndataloc(:) !< Sampling data,local

! Local variables
integer :: ib,ic0,ic0a
type(ndatatype) :: ndata

! Allocate ndataloc
allocate(ndataloc(bpar%nb+1))
do ib=1,bpar%nb+1
   if (bpar%nicas_block(ib)) then
      ! Set name
      write(ndataloc(ib)%cname,'(a,i1,a,i4.4,a,i4.4,a,a)') 'ndataloc_',nam%mpicom,'_',mpl%nproc,'-',mpl%myproc, &
    & '_',trim(bpar%blockname(ib))
   end if
end do

do ib=1,bpar%nb+1
   write(mpl%unit,'(a)') '-------------------------------------------------------------------'
   write(mpl%unit,'(a)') '--- Block: '//trim(bpar%blockname(ib))

   ! Set namelist and geometry
   ndata%nam => nam
   ndata%geom => geom
   ndata%cname = 'ndata_'//trim(bpar%blockname(ib))

   if (nam%new_param) then
      if (bpar%nicas_block(ib)) then
         ! Compute NICAS parameters
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Compute NICAS parameters'
         call compute_parameters(bdata(ib),ndata)
      
         ! Compute NICAS normalization
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Compute NICAS normalization'
         call compute_normalization(ndata)
      end if

      if (bpar%diag_block(ib)) then
         ! Copy weights
         ndata%wgt = bdata(ib)%wgt
         if (bpar%nicas_block(ib)) then
            allocate(ndata%coef_ens(geom%nc0,geom%nl0))
            ndata%coef_ens = bdata(ib)%coef_ens
         end if

         ! Write NICAS parameters
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Write NICAS parameters'
         call ndata_write(ndata,bpar%nicas_block(ib))
      end if
   elseif (nam%new_mpi.or.nam%check_adjoints.or.nam%check_pos_def.or.nam%check_mpi) then
      if (bpar%diag_block(ib)) then
         ! Read NICAS parameters
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Read NICAS parameters'
         call ndata_read(ndata,bpar%nicas_block(ib))
      end if
      call flush(mpl%unit)
   end if
      
   if (nam%new_mpi) then
      if (bpar%nicas_block(ib)) then
         ! Compute NICAS MPI distribution
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Compute NICAS MPI distribution'
         call compute_mpi(ndata,ndataloc(ib))

         if (mpl%main.and.(mpl%nproc>1)) then
            ! Write NICAS MPI summary
            write(mpl%unit,'(a)') '-------------------------------------------------------------------'
            write(mpl%unit,'(a)') '--- Write NICAS MPI summary'
            call ndata_write_mpi_summary(ndata)
         end if
      end if

      if (bpar%diag_block(ib)) then
         ! Copy weights
         ndataloc(ib)%wgt = ndata%wgt
         if (bpar%nicas_block(ib)) then
            allocate(ndataloc(ib)%coef_ens(geom%nc0a,geom%nl0))
            do ic0=1,geom%nc0
               if (geom%ic0_to_iproc(ic0)==mpl%myproc) then
                  ic0a = geom%ic0_to_ic0a(ic0)
                  ndataloc(ib)%coef_ens(ic0a,:) = ndata%coef_ens(ic0,:)
               end if
            end do
         end if

         ! Write NICAS MPI distribution
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Write NICAS MPI distribution'
         call ndataloc_write(nam,geom,ndataloc(ib),bpar%nicas_block(ib))
      end if

   else
      if (bpar%diag_block(ib)) then
         ! Read NICAS MPI distribution
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Read NICAS MPI distribution'
         call ndataloc_read(nam,geom,ndataloc(ib),bpar%nicas_block(ib))
      end if
      call flush(mpl%unit)
   end if

   if (bpar%nicas_block(ib)) then
      if (nam%check_adjoints) then
         ! Test adjoints
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Test NICAS adjoints'
         if (mpl%main) call test_adjoints(ndata)
         call flush(mpl%unit)
      end if
      
      if (nam%check_pos_def) then
         ! Test NICAS positive definiteness
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Test NICAS positive definiteness'
         if (mpl%main) call test_pos_def(ndata)
         call flush(mpl%unit)
      end if
      
      if (nam%check_mpi) then
         ! Test single/multi-procs equivalence
         write(mpl%unit,'(a)') '-------------------------------------------------------------------'
         write(mpl%unit,'(a)') '--- Test NICAS single/multi-procs equivalence'
         call test_mpi(ndata,ndataloc(ib))
         call flush(mpl%unit)
      end if
   end if

   ! Release memory
   if ((nam%new_param.or.nam%new_mpi.or.nam%check_adjoints.or.nam%check_pos_def.or.nam%check_mpi).and.bpar%diag_block(ib)) &
 & call ndata_dealloc(ndata,bpar%nicas_block(ib))
end do

end subroutine run_nicas

end module driver_nicas
