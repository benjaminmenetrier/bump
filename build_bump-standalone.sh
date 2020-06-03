#!/bin/bash

# Parameters ###############################################

# Directories
code="${HOME}/code"
build="${HOME}/build"

# Git branch
branch="feature/norcpm_interface"

# Environment variables
compiler=GNU
export OMP_NUM_THREADS=1
export SABER_TEST_TIER=1
export SABER_TEST_MPI=1
export SABER_TEST_OMP=0
export SABER_TEST_QUAD=0
export SABER_TEST_VALGRIND=0
export SABER_TEST_MODEL=1
export SABER_TEST_MODEL_DIR=${HOME}/data

############################################################

# Get compiler-related variables
export MPIEXEC=`which mpirun`
if test "${compiler}" = "GNU" ; then
   export CPCcomp=`which mpicxx`
   export CCcomp=`which mpicc`
   export F90comp=`which mpifort`
fi
if test "${compiler}" = "Intel" ; then
   export CPCcomp=`which mpiicpc`
   export CCcomp=`which mpiicc`
   export F90comp=`which mpiifort`
fi

# Build
mkdir -p ${build}/bump-standalone
cd ${build}/bump-standalone
ecbuild --build=release \
        -DCMAKE_CXX_COMPILER=${CPCcomp} \
        -DCMAKE_C_COMPILER=${CCcomp} \
        -DCMAKE_Fortran_COMPILER=${F90comp} \
        -DNETCDF_PATH=${NETCDF} \
        -DMPIEXEC=${MPIEXEC} \
        ${code}/bump-standalone
