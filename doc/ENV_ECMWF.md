# ENV_ECMWF

Cray compiler on cca/ccb:

    module unload cmake
    module load cmake/3.10.2 cray-netcdf ncl
    export BUMP_COMPILER=Cray
    export BUMP_BUILD=DEBUG
    export BUMP_NETCDF_INCLUDE=${NETCDF_DIR}/include
    export BUMP_NETCDF_LIBPATH=${NETCDF_DIR}/lib
    export BUMP_NETCDFF_INCLUDE=${NETCDF_DIR}/include
    export BUMP_NETCDFF_LIBPATH=${NETCDF_DIR}/lib