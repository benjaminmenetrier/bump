!----------------------------------------------------------------------
! Module: type_linop
! Purpose: linear operator derived type
! Author: Benjamin Menetrier
! Licensing: this code is distributed under the CeCILL-C license
! Copyright © 2015-... UCAR, CERFACS, METEO-FRANCE and IRIT
!----------------------------------------------------------------------
module type_linop

use netcdf
!$ use omp_lib
use tools_kinds, only: kind_real,nc_kind_real,huge_real
use tools_repro, only: inf
use type_geom, only: geom_type
use type_tree, only: tree_type
use type_mesh, only: mesh_type
use type_mpl, only: mpl_type
use type_nam, only: nam_type
use type_rng, only: rng_type

implicit none

logical,parameter :: check_data = .false.             ! Activate data check for all linear operations
real(kind_real),parameter :: S_inf = 1.0e-2_kind_real ! Minimum interpolation coefficient

! Interpolation data derived type
type interp_type
   integer :: n_src_eff
   integer,allocatable :: src_eff_to_src(:)
   real(kind_real),allocatable :: lon_src_eff(:)
   real(kind_real),allocatable :: lat_src_eff(:)
   type(tree_type) :: tree
   type(mesh_type) :: mesh
contains
   procedure :: dealloc => interp_dealloc
end type

! Linear operator derived type
type linop_type
   ! Prefix and dimensions
   character(len=1024) :: prefix            ! Operator prefix (for I/O)
   integer :: n_src                         ! Source vector size
   integer :: n_dst                         ! Destination vector size
   integer :: n_s                           ! Operator size
   integer :: nvec                          ! Size of the vector of linear operators with similar row and col

   ! Data
   integer,allocatable :: row(:)            ! Output indices
   integer,allocatable :: col(:)            ! Input indices
   real(kind_real),allocatable :: S(:)      ! Coefficients
   real(kind_real),allocatable :: Svec(:,:) ! Coefficients of the vector of linear operators with similar row and col
   type(interp_type) :: interp_data         ! Interpolation data
contains
   procedure :: alloc => linop_alloc
   procedure :: dealloc => linop_dealloc
   procedure :: copy => linop_copy
   procedure :: read => linop_read
   procedure :: write => linop_write
   procedure :: buffer_size => linop_buffer_size
   procedure :: serialize => linop_serialize
   procedure :: deserialize => linop_deserialize
   procedure :: apply => linop_apply
   procedure :: apply_ad => linop_apply_ad
   procedure :: apply_sym => linop_apply_sym
   procedure :: add_op => linop_add_op
   procedure :: gather => linop_gather
   procedure :: interp => linop_interp
end type linop_type

private
public :: linop_type

contains

!----------------------------------------------------------------------
! Subroutine: interp_dealloc
! Purpose: release memory
!----------------------------------------------------------------------
subroutine interp_dealloc(interp_data)

implicit none

! Passed variables
class(interp_type),intent(inout) :: interp_data ! Interpolation data

! Release memory
if (allocated(interp_data%src_eff_to_src)) deallocate(interp_data%src_eff_to_src)
if (allocated(interp_data%lon_src_eff)) deallocate(interp_data%lon_src_eff)
if (allocated(interp_data%lat_src_eff)) deallocate(interp_data%lat_src_eff)
call interp_data%mesh%dealloc
call interp_data%tree%dealloc

end subroutine interp_dealloc

!----------------------------------------------------------------------
! Subroutine: linop_alloc
! Purpose: allocation
!----------------------------------------------------------------------
subroutine linop_alloc(linop,nvec)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop ! Linear operator
integer,intent(in),optional :: nvec      ! Size of the vector of linear operators with similar row and col

! Vector size
if (present(nvec)) then
   linop%nvec = nvec
else
   linop%nvec = 0
end if

! Allocation
allocate(linop%row(linop%n_s))
allocate(linop%col(linop%n_s))
if (linop%nvec>0) then
   allocate(linop%Svec(linop%n_s,linop%nvec))
else
   allocate(linop%S(linop%n_s))
end if

end subroutine linop_alloc

!----------------------------------------------------------------------
! Subroutine: linop_dealloc
! Purpose: release memory
!----------------------------------------------------------------------
subroutine linop_dealloc(linop)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop ! Linear operator

! Release memory
if (allocated(linop%row)) deallocate(linop%row)
if (allocated(linop%col)) deallocate(linop%col)
if (allocated(linop%S)) deallocate(linop%S)
if (allocated(linop%Svec)) deallocate(linop%Svec)
call linop%interp_data%dealloc

end subroutine linop_dealloc

!----------------------------------------------------------------------
! Subroutine: linop_copy
! Purpose: copy
!----------------------------------------------------------------------
subroutine linop_copy(linop_out,linop_in,n_s)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop_out ! Output linear operator
type(linop_type),intent(in) :: linop_in      ! Input linear operator
integer,intent(in),optional :: n_s           ! Number of operations to copy

! Release memory
call linop_out%dealloc

! Copy attributes
linop_out%prefix = linop_in%prefix
linop_out%n_src = linop_in%n_src
linop_out%n_dst = linop_in%n_dst
if (present(n_s)) then
   linop_out%n_s = n_s
else
   linop_out%n_s = linop_in%n_s
end if

! Allocation
call linop_out%alloc(linop_in%nvec)

! Copy data
if (linop_in%n_s>0) then
   linop_out%row = linop_in%row(1:linop_out%n_s)
   linop_out%col = linop_in%col(1:linop_out%n_s)
   if (linop_out%nvec>0) then
      linop_out%Svec = linop_in%Svec(1:linop_out%n_s,:)
   else
      linop_out%S = linop_in%S(1:linop_out%n_s)
   end if
end if

end subroutine linop_copy

!----------------------------------------------------------------------
! Subroutine: linop_read
! Purpose: read
!----------------------------------------------------------------------
subroutine linop_read(linop,mpl,ncid)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop ! Linear operator
type(mpl_type),intent(inout) :: mpl      ! MPI data
integer,intent(in) :: ncid               ! NetCDF file

! Local variables
integer :: nvec
integer :: grpid,row_id,col_id,S_id,Svec_id
character(len=1024),parameter :: subr = 'linop_read'

! Get group
call mpl%ncerr(subr,nf90_inq_grp_ncid(ncid,linop%prefix,grpid))

! Get dimensions
linop%n_s = mpl%nc_dim_inquire(subr,grpid,'n_s')
call mpl%ncerr(subr,nf90_get_att(grpid,nf90_global,'n_src',linop%n_src))
call mpl%ncerr(subr,nf90_get_att(grpid,nf90_global,'n_dst',linop%n_dst))
call mpl%ncerr(subr,nf90_get_att(grpid,nf90_global,'nvec',nvec))

! Allocation
call linop%alloc(nvec)

if (linop%n_s>0) then
   ! Get variables
   call mpl%ncerr(subr,nf90_inq_varid(grpid,'row',row_id))
   call mpl%ncerr(subr,nf90_inq_varid(grpid,'col',col_id))
   if (linop%nvec>0) then
      call mpl%ncerr(subr,nf90_inq_varid(grpid,'Svec',Svec_id))
   else
      call mpl%ncerr(subr,nf90_inq_varid(grpid,'S',S_id))
   end if

   ! Read variables
   call mpl%ncerr(subr,nf90_get_var(grpid,row_id,linop%row))
   call mpl%ncerr(subr,nf90_get_var(grpid,col_id,linop%col))
   if (linop%nvec>0) then
      call mpl%ncerr(subr,nf90_get_var(grpid,Svec_id,linop%Svec))
   else
      call mpl%ncerr(subr,nf90_get_var(grpid,S_id,linop%S))
   end if
end if

end subroutine linop_read

!----------------------------------------------------------------------
! Subroutine: linop_write
! Purpose: write
!----------------------------------------------------------------------
subroutine linop_write(linop,mpl,ncid)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop ! Linear operator
type(mpl_type),intent(inout) :: mpl   ! MPI data
integer,intent(in) :: ncid            ! NetCDF file

! Local variables
integer :: grpid,n_s_id,nvec_id,row_id,col_id,S_id,Svec_id
character(len=1024),parameter :: subr = 'linop_write'

! Define group
grpid = mpl%nc_group_define_or_get(subr,ncid,linop%prefix)

! Define dimensions
call mpl%ncerr(subr,nf90_put_att(grpid,nf90_global,'n_src',linop%n_src))
call mpl%ncerr(subr,nf90_put_att(grpid,nf90_global,'n_dst',linop%n_dst))
call mpl%ncerr(subr,nf90_put_att(grpid,nf90_global,'nvec',linop%nvec))

if (linop%n_s>0) then
   ! Define dimensions
   n_s_id = mpl%nc_dim_define_or_get(subr,grpid,'n_s',linop%n_s)
   if (linop%nvec>0) nvec_id = mpl%nc_dim_define_or_get(subr,grpid,'nvec',linop%nvec)

   ! Define variables
   row_id = mpl%nc_var_define_or_get(subr,grpid,'row',nf90_int,(/n_s_id/))
   col_id = mpl%nc_var_define_or_get(subr,grpid,'col',nf90_int,(/n_s_id/))
   if (linop%nvec>0) then
      Svec_id = mpl%nc_var_define_or_get(subr,grpid,'Svec',nc_kind_real,(/n_s_id,nvec_id/))
   else
      S_id = mpl%nc_var_define_or_get(subr,grpid,'S',nc_kind_real,(/n_s_id/))
   end if

   ! Write variables
   call mpl%ncerr(subr,nf90_put_var(grpid,row_id,linop%row(1:linop%n_s)))
   call mpl%ncerr(subr,nf90_put_var(grpid,col_id,linop%col(1:linop%n_s)))
   if (linop%nvec>0) then
      call mpl%ncerr(subr,nf90_put_var(grpid,Svec_id,linop%Svec(1:linop%n_s,:)))
   else
      call mpl%ncerr(subr,nf90_put_var(grpid,S_id,linop%S(1:linop%n_s)))
   end if
end if

end subroutine linop_write

!----------------------------------------------------------------------
! Subroutine: linop_buffer_size
! Purpose: buffer size
!----------------------------------------------------------------------
subroutine linop_buffer_size(linop,nbufi,nbufr)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop ! Linear operator
integer,intent(out) :: nbufi          ! Buffer size (integer)
integer,intent(out) :: nbufr          ! Buffer size (real)

! Define buffer size
nbufi = 6+2*linop%n_s
if (linop%nvec>0) then
   nbufr = linop%n_s*linop%nvec
else
   nbufr = linop%n_s
end if

end subroutine linop_buffer_size

!----------------------------------------------------------------------
! Subroutine: linop_serialize
! Purpose: serialize
!----------------------------------------------------------------------
subroutine linop_serialize(linop,mpl,nbufi,nbufr,bufi,bufr)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop      ! Linear operator
type(mpl_type),intent(inout) :: mpl        ! MPI data
integer,intent(in) :: nbufi                ! Buffer size (integer)
integer,intent(in) :: nbufr                ! Buffer size (real)
integer,intent(out) :: bufi(nbufi)         ! Buffer (integer)
real(kind_real),intent(out) :: bufr(nbufr) ! Buffer (real)

! Local variables
integer :: ibufi,ibufr
logical,allocatable :: mask_Svec(:,:)
character(len=1024),parameter :: subr = 'linop_serialize'

! Initialization
ibufi = 0
ibufr = 0

! Dimensions
bufi(ibufi+1) = nbufi
ibufi = ibufi+1
bufi(ibufi+1) = nbufr
ibufi = ibufi+1
bufi(ibufi+1) = linop%n_s
ibufi = ibufi+1
bufi(ibufi+1) = linop%n_src
ibufi = ibufi+1
bufi(ibufi+1) = linop%n_dst
ibufi = ibufi+1
bufi(ibufi+1) = linop%nvec
ibufi = ibufi+1

! Data
if (linop%n_s>0) then
   if (linop%nvec>0) then
      ! Allocation
      allocate(mask_Svec(linop%n_s,linop%nvec))

      ! Initialization
      mask_Svec = .true.
   end if

   ! Copy data
   bufi(ibufi+1:ibufi+linop%n_s) = linop%row
   ibufi = ibufi+linop%n_s
   bufi(ibufi+1:ibufi+linop%n_s) = linop%col
   ibufi = ibufi+linop%n_s
   if (linop%nvec>0) then
      bufr(ibufr+1:ibufr+linop%n_s*linop%nvec) = pack(linop%Svec,mask_Svec)
      ibufr = ibufr+linop%n_s*linop%nvec
   else
      bufr(ibufr+1:ibufr+linop%n_s) = linop%S
      ibufr = ibufr+linop%n_s
   end if

   ! Release memory
   if (linop%nvec>0) deallocate(mask_Svec)
end if

! Check
if (ibufi/=nbufi) call mpl%abort(subr,'inconsistent final offset/buffer size (integer)')
if (ibufr/=nbufr) call mpl%abort(subr,'inconsistent final offset/buffer size (real)')

end subroutine linop_serialize

!----------------------------------------------------------------------
! Subroutine: linop_deserialize
! Purpose: deserialize
!----------------------------------------------------------------------
subroutine linop_deserialize(linop,mpl,nbufi,nbufr,bufi,bufr)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop  ! Linear operator
type(mpl_type),intent(inout) :: mpl       ! MPI data
integer,intent(in) :: nbufi               ! Buffer size (integer)
integer,intent(in) :: nbufr               ! Buffer size (real)
integer,intent(in) :: bufi(nbufi)         ! Buffer (integer)
real(kind_real),intent(in) :: bufr(nbufr) ! Buffer (real)

! Local variables
integer :: ibufi,ibufr,nvec
logical,allocatable :: mask_Svec(:,:)
character(len=1024),parameter :: subr = 'linop_serialize'

! Initialization
ibufi = 0
ibufr = 0

! Check
if (bufi(ibufi+1)/=nbufi) call mpl%abort(subr,'inconsistent initial value/buffer size (integer)')
ibufi = ibufi+1
if (bufi(ibufi+1)/=nbufr) call mpl%abort(subr,'inconsistent initial value/buffer size (real)')
ibufi = ibufi+1

! Copy data
linop%n_s = bufi(ibufi+1)
ibufi = ibufi+1
linop%n_src = bufi(ibufi+1)
ibufi = ibufi+1
linop%n_dst = bufi(ibufi+1)
ibufi = ibufi+1
nvec = bufi(ibufi+1)
ibufi = ibufi+1

! Allocation
call linop%alloc(nvec)

! Data
if (linop%n_s>0) then
   if (linop%nvec>0) then
      ! Allocation
      allocate(mask_Svec(linop%n_s,linop%nvec))

      ! Initialization
      mask_Svec = .true.
   end if
   
   ! Copy data
   linop%row = bufi(ibufi+1:ibufi+linop%n_s)
   ibufi = ibufi+linop%n_s
   linop%col = bufi(ibufi+1:ibufi+linop%n_s)
   ibufi = ibufi+linop%n_s
   if (linop%nvec>0) then
      linop%Svec = mpl%msv%valr
      linop%Svec = unpack(bufr(ibufr+1:ibufr+linop%n_s*linop%nvec),mask_Svec,linop%Svec)
      ibufr = ibufr+linop%n_s*linop%nvec
   else
      linop%S = bufr(ibufr+1:ibufr+linop%n_s)
      ibufr = ibufr+linop%n_s
   end if

   ! Release memory
   if (linop%nvec>0) deallocate(mask_Svec)
end if

! Check
if (ibufi/=nbufi) call mpl%abort(subr,'inconsistent final offset/buffer size (integer)')
if (ibufr/=nbufr) call mpl%abort(subr,'inconsistent final offset/buffer size (real)')

end subroutine linop_deserialize

!----------------------------------------------------------------------
! Subroutine: linop_apply
! Purpose: apply linear operator
!----------------------------------------------------------------------
subroutine linop_apply(linop,mpl,fld_src,fld_dst,ivec,mssrc,msdst)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop               ! Linear operator
type(mpl_type),intent(inout) :: mpl                 ! MPI data
real(kind_real),intent(in) :: fld_src(linop%n_src)  ! Source vector
real(kind_real),intent(out) :: fld_dst(linop%n_dst) ! Destination vector
integer,intent(in),optional :: ivec                 ! Index of the vector of linear operators with similar row and col
logical,intent(in),optional :: mssrc                ! Check for missing source
logical,intent(in),optional :: msdst                ! Check for missing destination

! Local variables
integer :: i_s,i_dst
logical :: lmssrc,lmsdst,valid
logical,allocatable :: missing_src(:),missing_dst(:)
character(len=1024),parameter :: subr = 'linop_apply'

if (check_data) then
   ! Check linear operation
   if (minval(linop%col)<1) call mpl%abort(subr,'col<1 for linear operation '//trim(linop%prefix))
   if (maxval(linop%col)>linop%n_src) call mpl%abort(subr,'col>n_src for linear operation '//trim(linop%prefix))
   if (minval(linop%row)<1) call mpl%abort(subr,'row<1 for linear operation '//trim(linop%prefix))
   if (maxval(linop%row)>linop%n_dst) call mpl%abort(subr,'row>n_dst for linear operation '//trim(linop%prefix))
   if (present(ivec)) then
      if (any(isnan(linop%Svec))) call mpl%abort(subr,'NaN in Svec for linear operation '//trim(linop%prefix))
   else
      if (any(isnan(linop%S))) call mpl%abort(subr,'NaN in S for linear operation '//trim(linop%prefix))
   end if

   ! Check input
   if (any(fld_src>huge_real)) call mpl%abort(subr,'Overflowing number in fld_src for linear operation '//trim(linop%prefix))
   if (any(isnan(fld_src))) call mpl%abort(subr,'NaN in fld_src for linear operation '//trim(linop%prefix))
end if

! Initialization
fld_dst = 0.0
lmssrc = .false.
if (present(mssrc)) lmssrc = mssrc
lmsdst = .true.
if (present(msdst)) lmsdst = msdst
if (lmssrc) then
   allocate(missing_src(linop%n_dst))
   missing_src = .false.
end if
if (lmsdst) then
   allocate(missing_dst(linop%n_dst))
   missing_dst = .true.
end if

! Apply weights
do i_s=1,linop%n_s
   if (lmssrc) then
      ! Check for missing source (WARNING: source-dependent => no adjoint)
      valid = mpl%msv%isnot(fld_src(linop%col(i_s)))
   else
      ! Source independent
      valid = .true.
   end if

   if (valid) then
      if (present(ivec)) then
         fld_dst(linop%row(i_s)) = fld_dst(linop%row(i_s))+linop%Svec(i_s,ivec)*fld_src(linop%col(i_s))
      else
         fld_dst(linop%row(i_s)) = fld_dst(linop%row(i_s))+linop%S(i_s)*fld_src(linop%col(i_s))
      end if

      ! Check for missing destination
      if (lmsdst) missing_dst(linop%row(i_s)) = .false.
   else
      ! Missing source
      missing_src(linop%row(i_s)) = .true.
   end if
end do

if (lmssrc) then
   ! Missing source values
   do i_dst=1,linop%n_dst
      if (missing_src(i_dst)) fld_dst(i_dst) = mpl%msv%valr
   end do

   ! Release memory
   deallocate(missing_src)
end if

if (lmsdst) then
   ! Missing destination values
   do i_dst=1,linop%n_dst
      if (missing_dst(i_dst)) fld_dst(i_dst) = mpl%msv%valr
   end do

   ! Release memory
   deallocate(missing_dst)
end if

if (check_data) then
   ! Check output
   if (any(isnan(fld_dst))) call mpl%abort(subr,'NaN in fld_dst for linear operation '//trim(linop%prefix))
end if

end subroutine linop_apply

!----------------------------------------------------------------------
! Subroutine: linop_apply_ad
! Purpose: apply linear operator, adjoint
!----------------------------------------------------------------------
subroutine linop_apply_ad(linop,mpl,fld_dst,fld_src,ivec)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop               ! Linear operator
type(mpl_type),intent(inout) :: mpl                 ! MPI data
real(kind_real),intent(in) :: fld_dst(linop%n_dst)  ! Destination vector
real(kind_real),intent(out) :: fld_src(linop%n_src) ! Source vector
integer,intent(in),optional :: ivec                 ! Index of the vector of linear operators with similar row and col

! Local variables
integer :: i_s
character(len=1024),parameter :: subr = 'linop_apply_ad'

if (check_data) then
   ! Check linear operation
   if (minval(linop%col)<1) call mpl%abort(subr,'col<1 for adjoint linear operation '//trim(linop%prefix))
   if (maxval(linop%col)>linop%n_src) call mpl%abort(subr,'col>n_src for adjoint linear operation '//trim(linop%prefix))
   if (minval(linop%row)<1) call mpl%abort(subr,'row<1 for adjoint linear operation '//trim(linop%prefix))
   if (maxval(linop%row)>linop%n_dst) call mpl%abort(subr,'row>n_dst for adjoint linear operation '//trim(linop%prefix))
   if (present(ivec)) then
      if (any(isnan(linop%Svec))) call mpl%abort(subr,'NaN in Svec for adjoint linear operation '//trim(linop%prefix))
   else
      if (any(isnan(linop%S))) call mpl%abort(subr,'NaN in S for adjoint linear operation '//trim(linop%prefix))
   end if

   ! Check input
   if (any(fld_dst>huge_real)) &
 & call mpl%abort(subr,'Overflowing number in fld_dst for adjoint linear operation '//trim(linop%prefix))
   if (any(isnan(fld_dst))) call mpl%abort(subr,'NaN in fld_dst for adjoint linear operation '//trim(linop%prefix))
end if

! Initialization
fld_src = 0.0

! Apply weights
do i_s=1,linop%n_s
   if (present(ivec)) then
      fld_src(linop%col(i_s)) = fld_src(linop%col(i_s))+linop%Svec(i_s,ivec)*fld_dst(linop%row(i_s))
   else
      fld_src(linop%col(i_s)) = fld_src(linop%col(i_s))+linop%S(i_s)*fld_dst(linop%row(i_s))
   end if
end do

if (check_data) then
   ! Check output
   if (any(isnan(fld_src))) call mpl%abort(subr,'NaN in fld_src for adjoint linear operation '//trim(linop%prefix))
end if

end subroutine linop_apply_ad

!----------------------------------------------------------------------
! Subroutine: linop_apply_sym
! Purpose: apply linear operator, symmetric
!----------------------------------------------------------------------
subroutine linop_apply_sym(linop,mpl,fld,ivec)

implicit none

! Passed variables
class(linop_type),intent(in) :: linop             ! Linear operator
type(mpl_type),intent(inout) :: mpl               ! MPI data
real(kind_real),intent(inout) :: fld(linop%n_src) ! Source/destination vector
integer,intent(in),optional :: ivec               ! Index of the vector of linear operators with similar row and col

! Local variables
integer :: i_s,ithread
real(kind_real) :: fld_arr(linop%n_dst,mpl%nthread)
character(len=1024),parameter :: subr = 'linop_apply_sym'

if (check_data) then
   ! Check linear operation
   if (minval(linop%col)<1) call mpl%abort(subr,'col<1 for symmetric linear operation '//trim(linop%prefix))
   if (maxval(linop%col)>linop%n_src) call mpl%abort(subr,'col>n_src for symmetric linear operation '//trim(linop%prefix))
   if (minval(linop%row)<1) call mpl%abort(subr,'row<1 for symmetric linear operation '//trim(linop%prefix))
   if (maxval(linop%row)>linop%n_src) call mpl%abort(subr,'row>n_dst for symmetric linear operation '//trim(linop%prefix))
   if (present(ivec)) then
      if (any(isnan(linop%Svec))) call mpl%abort(subr,'NaN in Svec for symmetric linear operation '//trim(linop%prefix))
   else
      if (any(isnan(linop%S))) call mpl%abort(subr,'NaN in S for symmetric linear operation '//trim(linop%prefix))
   end if

   ! Check input
   if (any(fld>huge_real)) call mpl%abort(subr,'Overflowing number in fld for symmetric linear operation '//trim(linop%prefix))
   if (any(isnan(fld))) call mpl%abort(subr,'NaN in fld for symmetric linear operation '//trim(linop%prefix))
end if

! Apply weights
fld_arr = 0.0
!$omp parallel do schedule(static) private(i_s,ithread)
do i_s=1,linop%n_s
   ithread = 1
!$ ithread = omp_get_thread_num()+1
   if (present(ivec)) then
      fld_arr(linop%row(i_s),ithread) = fld_arr(linop%row(i_s),ithread)+linop%Svec(i_s,ivec)*fld(linop%col(i_s))
      if (linop%col(i_s)/=linop%row(i_s)) fld_arr(linop%col(i_s),ithread) = fld_arr(linop%col(i_s),ithread) &
 & +linop%Svec(i_s,ivec)*fld(linop%row(i_s))
   else
      fld_arr(linop%row(i_s),ithread) = fld_arr(linop%row(i_s),ithread)+linop%S(i_s)*fld(linop%col(i_s))
      if (linop%col(i_s)/=linop%row(i_s)) fld_arr(linop%col(i_s),ithread) = fld_arr(linop%col(i_s),ithread) &
 & +linop%S(i_s)*fld(linop%row(i_s))
   end if
end do
!$omp end parallel do

! Sum over threads
fld = 0.0
do ithread=1,mpl%nthread
   fld = fld+fld_arr(:,ithread)
end do

if (check_data) then
   ! Check output
   if (any(isnan(fld))) call mpl%abort(subr,'NaN in fld for symmetric linear operation '//trim(linop%prefix))
end if

end subroutine linop_apply_sym

!----------------------------------------------------------------------
! Subroutine: linop_add_op
! Purpose: add operation
!----------------------------------------------------------------------
subroutine linop_add_op(linop,n_s,row,col,S)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop ! Linear operators
integer,intent(inout) :: n_s             ! Number of operations
integer,intent(in) :: row                ! Row index
integer,intent(in) :: col                ! Column index
real(kind_real),intent(in) :: S          ! Value

! Local variables
type(linop_type) :: linop_tmp

! Update
n_s = n_s+1
if (n_s>linop%n_s) then
   ! Copy
   call linop_tmp%copy(linop)

   ! Reallocate larger linear operation
   call linop%dealloc
   linop%n_s = 2*linop_tmp%n_s
   call linop%alloc

   ! Copy data
   linop%row(1:linop_tmp%n_s) = linop_tmp%row
   linop%col(1:linop_tmp%n_s) = linop_tmp%col
   linop%S(1:linop_tmp%n_s) = linop_tmp%S

   ! Release memory
   call linop_tmp%dealloc
end if

! New operation
linop%row(n_s) = row
linop%col(n_s) = col
linop%S(n_s) = S

end subroutine linop_add_op

!----------------------------------------------------------------------
! Subroutine: linop_gather
! Purpose: gather data from OpenMP threads
!----------------------------------------------------------------------
subroutine linop_gather(linop,mpl,n_s_arr,linop_arr)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop              ! Linear operator
type(mpl_type),intent(inout) :: mpl                   ! MPI data
integer,intent(in) :: n_s_arr(mpl%nthread)            ! Number of operations
type(linop_type),intent(in) :: linop_arr(mpl%nthread) ! Linear operator array

! Local variables
integer :: ithread,offset

if (mpl%nthread>1) then
   ! Total number of operations
   linop%n_s = sum(n_s_arr)

   ! Allocation
   call linop%alloc

   ! Gather data
   offset = 0
   do ithread=1,mpl%nthread
      linop%row(offset+1:offset+n_s_arr(ithread)) = linop_arr(ithread)%row(1:n_s_arr(ithread))
      linop%col(offset+1:offset+n_s_arr(ithread)) = linop_arr(ithread)%col(1:n_s_arr(ithread))
      linop%S(offset+1:offset+n_s_arr(ithread)) = linop_arr(ithread)%S(1:n_s_arr(ithread))
      offset = offset+n_s_arr(ithread)
   end do
else
   ! Copy
   call linop%copy(linop_arr(1),n_s_arr(1))
end if

end subroutine linop_gather

!----------------------------------------------------------------------
! Subroutine: linop_interp
! Purpose: compute horizontal interpolation
!----------------------------------------------------------------------
subroutine linop_interp(linop,mpl,rng,nam,geom,il0,n_src,lon_src,lat_src,mask_src,n_dst,lon_dst,lat_dst,mask_dst,ifmt)

implicit none

! Passed variables
class(linop_type),intent(inout) :: linop     ! Linear operator
type(mpl_type),intent(inout) :: mpl          ! MPI data
type(rng_type),intent(inout) :: rng          ! Random number generator
type(nam_type),intent(in) :: nam             ! Namelist
type(geom_type),intent(in) :: geom           ! Geometry
integer,intent(in) :: il0                    ! Level
integer,intent(in) :: n_src                  ! Source size
real(kind_real),intent(in) :: lon_src(n_src) ! Source longitudes
real(kind_real),intent(in) :: lat_src(n_src) ! Source latitudes
logical,intent(in) :: mask_src(n_src)        ! Source mask
integer,intent(in) :: n_dst                  ! Destination size
real(kind_real),intent(in) :: lon_dst(n_dst) ! Destination longitudes
real(kind_real),intent(in) :: lat_dst(n_dst) ! Destination latitudes
logical,intent(in) :: mask_dst(n_dst)        ! Destination mask
integer,intent(in) :: ifmt                   ! Format indentation

! Local variables
integer :: n_src_eff,i_src,i_src_eff,i,i_dst,nn_index(1),n_s,ib(3),i_s
integer,allocatable :: src_eff_to_src(:),row(:),col(:)
real(kind_real) :: nn_dist(1),b(3)
real(kind_real),allocatable :: lon_src_eff(:),lat_src_eff(:),S(:)
logical :: valid,valid_arc
logical,allocatable :: missing(:)
character(len=7) :: cfmt
character(len=1024),parameter :: subr = 'linop_interp'

! Count non-missing source points
n_src_eff = count(mask_src)

! Allocation
allocate(src_eff_to_src(n_src_eff))
allocate(lon_src_eff(n_src_eff))
allocate(lat_src_eff(n_src_eff))

! Conversion
i_src_eff = 0
do i_src=1,n_src
   if (mask_src(i_src)) then
      i_src_eff = i_src_eff+1
      src_eff_to_src(i_src_eff) = i_src
   end if
end do
lon_src_eff = lon_src(src_eff_to_src)
lat_src_eff = lat_src(src_eff_to_src)

if (allocated(linop%interp_data%src_eff_to_src)) then
   ! Check that source is the same
   if (n_src_eff/=linop%interp_data%n_src_eff) call mpl%abort(subr,'wrong n_src_eff')
   if (any(src_eff_to_src/=linop%interp_data%src_eff_to_src)) call mpl%abort(subr,'wrong src_eff_to_src')
   if (any(abs(lon_src_eff-linop%interp_data%lon_src_eff)>0.0)) call mpl%abort(subr,'wrong lon_src_eff')
   if (any(abs(lat_src_eff-linop%interp_data%lat_src_eff)>0.0)) call mpl%abort(subr,'wrong lat_src_eff')

   ! Release memory
   deallocate(linop%row)
   deallocate(linop%col)
   deallocate(linop%S)
else
   ! Allocation
   allocate(linop%interp_data%src_eff_to_src(n_src_eff))
   allocate(linop%interp_data%lon_src_eff(n_src_eff))
   allocate(linop%interp_data%lat_src_eff(n_src_eff))

   ! Copy source data
   linop%interp_data%n_src_eff = n_src_eff
   linop%interp_data%src_eff_to_src = src_eff_to_src
   linop%interp_data%lon_src_eff = lon_src_eff
   linop%interp_data%lat_src_eff = lat_src_eff

   ! Allocation
   call linop%interp_data%mesh%alloc(n_src_eff)
   call linop%interp_data%tree%alloc(mpl,n_src_eff)

   ! Initialization
   call linop%interp_data%mesh%init(mpl,rng,lon_src_eff,lat_src_eff)
   call linop%interp_data%tree%init(lon_src_eff,lat_src_eff)
end if

! Allocation
allocate(row(3*n_dst))
allocate(col(3*n_dst))
allocate(S(3*n_dst))

! Compute interpolation
if (ifmt>0) then
   write(cfmt,'(a,i2.2,a)') '(a',ifmt,',a)'
   write(mpl%info,cfmt) '','Compute interpolation: '
   call mpl%flush(.false.)
   call mpl%prog_init(n_dst)
end if
n_s = 0
do i_dst=1,n_dst
   if (mask_dst(i_dst)) then
      ! Find nearest neighbor
      call linop%interp_data%tree%find_nearest_neighbors(lon_dst(i_dst),lat_dst(i_dst),1,nn_index,nn_dist)

      if (abs(nn_dist(1))>0.0) then
         ! Compute barycentric coordinates
         call linop%interp_data%mesh%barycentric(mpl,lon_dst(i_dst),lat_dst(i_dst),nn_index(1),b,ib)

         valid = all(ib>0)
         if (valid) then
            if (nam%mask_check) then
               ! Check if arc is crossing boundary arcs
               do i=1,3
                  call geom%check_arc(mpl,il0,lon_src_eff(ib(i)),lat_src_eff(ib(i)),lon_dst(i_dst),lat_dst(i_dst),valid_arc)
                  if (.not.valid_arc) valid = .false.
               end do
            end if

            if (valid) then
               ! Bilinear interpolation
               if (sum(b)>0.0) b = b/sum(b)
               do i=1,3
                  if (inf(b(i),S_inf)) b(i) = 0.0
               end do
               if (sum(b)>0.0) b = b/sum(b)
               do i=1,3
                  if (b(i)>0.0) then
                     n_s = n_s+1
                     row(n_s) = i_dst
                     col(n_s) = ib(i)
                     S(n_s) = b(i)
                  end if
               end do
            end if
         end if
      else
         ! Subsampled point
         valid = .true.
         n_s = n_s+1
         row(n_s) = i_dst
         col(n_s) = nn_index(1)
         S(n_s) = 1.0
      end if

      if (.not.valid) then
         ! Deal with missing point (nearest neighbor on source grid)
         n_s = n_s+1
         row(n_s) = i_dst
         col(n_s) = nn_index(1)
         S(n_s) = 1.0
      end if
   end if

   ! Update
   if (ifmt>0) call mpl%prog_print(i_dst)
end do
if (ifmt>0) call mpl%prog_final

! Check interpolation
allocate(missing(n_dst))
missing = .false.
do i_dst=1,n_dst
   if (mask_dst(i_dst)) missing(i_dst) = .true.
end do
do i_s=1,n_s
   missing(row(i_s)) = .false.
end do
if (any(missing)) call mpl%abort(subr,'missing destination points')

! Allocation
linop%n_s = n_s
linop%n_src = n_src
linop%n_dst = n_dst
call linop%alloc

! Copy data
linop%row = row(1:linop%n_s)
linop%col = src_eff_to_src(col(1:linop%n_s))
linop%S = S(1:linop%n_s)

! Release memory
deallocate(src_eff_to_src)
deallocate(lon_src_eff)
deallocate(lat_src_eff)
deallocate(row)
deallocate(col)
deallocate(S)
deallocate(missing)

end subroutine linop_interp

end module type_linop
