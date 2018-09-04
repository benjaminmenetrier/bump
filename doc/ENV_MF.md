# ENV_MF

GNU compiler on beaufix/prolix:

    module purge
    module load cmake gcc openmpi netcdf ncl
    export BUMP_COMPILER=GNU
    export BUMP_BUILD=DEBUG
    export BUMP_NETCDF_INCLUDE=${NETCDF_INC_DIR}
    export BUMP_NETCDF_LIBPATH=${NETCDF_LIB_DIR}
    export BUMP_NETCDFF_INCLUDE=${NETCDF_INC_DIR}
    export BUMP_NETCDFF_LIBPATH=${NETCDF_LIB_DIR}

Intel compiler on beaufix/prolix:

    module purge
    module load cmake intel/17.1.132 intelmpi netcdf ncl
    export BUMP_COMPILER=Intel
    export BUMP_BUILD=DEBUG
    export BUMP_NETCDF_INCLUDE=${NETCDF_INC_DIR}
    export BUMP_NETCDF_LIBPATH=${NETCDF_LIB_DIR}
    export BUMP_NETCDFF_INCLUDE=${NETCDF_INC_DIR}
    export BUMP_NETCDFF_LIBPATH=${NETCDF_LIB_DIR}