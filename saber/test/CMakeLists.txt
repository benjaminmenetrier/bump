# (C) Copyright 2017-2019 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

# Default SABER_TEST_TIER
set( SABER_TEST_TIER 1 )

# Override SABER_TEST_TIER using environment variable
if( DEFINED ENV{SABER_TEST_TIER} )
    set( SABER_TEST_TIER "$ENV{SABER_TEST_TIER}" )
endif()

# Default test selection variables (TIER-dependent)
if( SABER_TEST_TIER MATCHES 1 )
    set( SABER_TEST_MPI 1 )
    set( SABER_TEST_OMP 0 )
    set( SABER_TEST_MULTI 0 )
elseif( SABER_TEST_TIER MATCHES 2 )
    set( SABER_TEST_MPI 1 )
    set( SABER_TEST_OMP 1 )
    set( SABER_TEST_MULTI 0 )
elseif( SABER_TEST_TIER MATCHES 3)
    set( SABER_TEST_MPI 1 )
    set( SABER_TEST_OMP 1 )
    set( SABER_TEST_MULTI 1 )
else()
    message( FATAL_ERROR "SABER_TEST_TIER should be 1, 2 or 3, not ${SABER_TEST_TIER}" )
endif()

# Default test selection variables (TIER-independent)
set( SABER_TEST_PLOT 0 )
set( SABER_TEST_VALGRIND 0 )
set( SABER_TEST_MODEL 0 )
set( SABER_TEST_MODEL_DIR "" )
set( SABER_TEST_OOPS 0 )
set( SABER_TEST_INTERPOLATION 0 )
if ( oops_qg_FOUND )
    set( SABER_TEST_OOPS 1 )
    set( SABER_TEST_INTERPOLATION 1 )
endif()

# Override test selection variables using environment variables
if( DEFINED ENV{SABER_TEST_MPI} )
    set( SABER_TEST_MPI "$ENV{SABER_TEST_MPI}" )
endif()
if( DEFINED ENV{SABER_TEST_OMP} )
    set( SABER_TEST_OMP "$ENV{SABER_TEST_OMP}" )
endif()
if( DEFINED ENV{SABER_TEST_MULTI} )
    set( SABER_TEST_MULTI "$ENV{SABER_TEST_MULTI}" )
endif()
if( DEFINED ENV{SABER_TEST_PLOT} )
    set( SABER_TEST_PLOT "$ENV{SABER_TEST_PLOT}" )
endif()
if( DEFINED ENV{SABER_TEST_VALGRIND} )
    set( SABER_TEST_VALGRIND "$ENV{SABER_TEST_VALGRIND}" )
endif()
if( DEFINED ENV{SABER_TEST_MODEL} )
    set( SABER_TEST_MODEL "$ENV{SABER_TEST_MODEL}" )
endif()
if( DEFINED ENV{SABER_TEST_MODEL_DIR} )
    set( SABER_TEST_MODEL_DIR "$ENV{SABER_TEST_MODEL_DIR}" )
endif()
if ( oops_qg_FOUND )
    if( DEFINED ENV{SABER_TEST_OOPS} )
        set( SABER_TEST_OOPS "$ENV{SABER_TEST_OOPS}" )
    endif()
    if( DEFINED ENV{SABER_TEST_INTERPOLATION} )
        set( SABER_TEST_INTERPOLATION "$ENV{SABER_TEST_INTERPOLATION}" )
    endif()
endif()

# Summary
message( STATUS "SABER_TEST_TIER:          ${SABER_TEST_TIER}" )
message( STATUS "SABER_TEST_MPI:           ${SABER_TEST_MPI}" )
message( STATUS "SABER_TEST_OMP:           ${SABER_TEST_OMP}" )
message( STATUS "SABER_TEST_MULTI:         ${SABER_TEST_MULTI}" )
message( STATUS "SABER_TEST_PLOT:          ${SABER_TEST_PLOT}" )
message( STATUS "SABER_TEST_VALGRIND:      ${SABER_TEST_VALGRIND}" )
message( STATUS "SABER_TEST_MODEL:         ${SABER_TEST_MODEL}" )
if( SABER_TEST_MODEL )
    message( STATUS "SABER_TEST_MODEL_DIR:     ${SABER_TEST_MODEL_DIR}" )
endif()
message( STATUS "SABER_TEST_OOPS:          ${SABER_TEST_OOPS}" )
message( STATUS "SABER_TEST_INTERPOLATION: ${SABER_TEST_INTERPOLATION}" )

# TIER 1
file( STRINGS testlist/saber_test_1.txt saber_test_tmp )
list( APPEND saber_test ${saber_test_tmp} )
file( STRINGS testlist/saber_data.txt saber_data_tmp )
list( APPEND saber_data ${saber_data_tmp} )
list( APPEND saber_data_tar saber_data.tar.gz )
file( STRINGS testlist/saber_ref_1.txt saber_ref_tmp )
list( APPEND saber_ref ${saber_ref_tmp} )
list( APPEND saber_ref_tar saber_ref_1.tar.gz)
if( SABER_TEST_MPI )
    file( STRINGS testlist/saber_data_mpi.txt saber_data_tmp )
    list( APPEND saber_data ${saber_data_tmp} )
    list( APPEND saber_data_tar saber_data_mpi.tar.gz )
    file( STRINGS testlist/saber_ref_mpi_1.txt saber_ref_tmp )
    list( APPEND saber_ref ${saber_ref_tmp} )
    list( APPEND saber_ref_tar saber_ref_mpi_1.tar.gz )
endif()
if( SABER_TEST_OMP )
    file( STRINGS testlist/saber_data_omp.txt saber_data_tmp )
    list( APPEND saber_data ${saber_data_tmp} )
    list( APPEND saber_data_tar saber_data_omp.tar.gz )
endif()

# TIER > 1
if( SABER_TEST_TIER GREATER 1 )
    file( STRINGS testlist/saber_test_2.txt saber_test_tmp )
    list( APPEND saber_test ${saber_test_tmp} )
    file( STRINGS testlist/saber_ref_2.txt saber_ref_tmp )
    list( APPEND saber_ref ${saber_ref_tmp} )
    list( APPEND saber_ref_tar saber_ref_2.tar.gz )
    if( SABER_TEST_MPI )
        file( STRINGS testlist/saber_ref_mpi_2.txt saber_ref_tmp )
        list( APPEND saber_ref ${saber_ref_tmp} )
        list( APPEND saber_ref_tar saber_ref_mpi_2.tar.gz )
    endif()
endif()

# TIER > 2
if( SABER_TEST_TIER GREATER 2 )
    file( STRINGS testlist/saber_test_3.txt saber_test_tmp )
    list( APPEND saber_test ${saber_test_tmp} )
    file( STRINGS testlist/saber_ref_3.txt saber_ref_tmp )
    list( APPEND saber_ref ${saber_ref_tmp} )
    list( APPEND saber_ref_tar saber_ref_3.tar.gz )
#    if( SABER_TEST_MPI )
#        file( STRINGS testlist/saber_ref_mpi_3.txt saber_ref_tmp )
#        list( APPEND saber_ref ${saber_ref_tmp} )
#        list( APPEND saber_ref_tar saber_ref_mpi_3.tar.gz )
#    endif()
endif()

# Multi-core tests (more than two)
if( SABER_TEST_MULTI )
    file( STRINGS testlist/saber_test_multi.txt saber_test_multi_tmp )
    list( APPEND saber_test_multi ${saber_test_multi_tmp} )
    file( STRINGS testlist/saber_ref_multi.txt saber_ref_tmp )
    list( APPEND saber_ref ${saber_ref_tmp} )
    list( APPEND saber_ref_tar saber_ref_multi.tar.gz )
endif()

# Model tests
if( SABER_TEST_MODEL )
    file( STRINGS testlist/saber_test_model.txt saber_test_model_tmp )
    list( APPEND saber_test_model ${saber_test_model_tmp} )
endif()

# OOPS tests
if( SABER_TEST_OOPS )
    file( STRINGS testlist/saber_test_oops.txt saber_test_oops_tmp )
    list( APPEND saber_test_oops ${saber_test_oops_tmp} )
    file( STRINGS testlist/saber_data_oops.txt saber_data_tmp )
    list( APPEND saber_data ${saber_data_tmp} )
    list( APPEND saber_data_tar saber_data_oops.tar.gz )
    file( STRINGS testlist/saber_ref_oops.txt saber_ref_tmp )
    list( APPEND saber_ref ${saber_ref_tmp} )
    list( APPEND saber_ref_tar saber_ref_oops.tar.gz )
endif()

# Set download URL
set( ECBUILD_DOWNLOAD_BASE_URL https://jedi-test-files.s3.amazonaws.com/saber )

# Define local path for test files
if( DEFINED ENV{LOCAL_PATH_TESTFILES_SABER} )
    set( LOCAL_PATH_TESTFILES_SABER "$ENV{LOCAL_PATH_TESTFILES_SABER}" )
endif()

# If local path to testfiles is defined don't download
if( NOT DEFINED LOCAL_PATH_TESTFILES_SABER )
    # Get the current git branch
    execute_process(
        COMMAND git rev-parse --abbrev-ref HEAD
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Set TESTFILE_DIR_SABER
    set( TESTFILE_DIR_SABER ${CMAKE_BINARY_DIR}/test_data/saber/${GIT_BRANCH} )
    message( STATUS "Files downloaded into: " ${TESTFILE_DIR_SABER} )
else()
    set( TESTFILE_DIR_SABER ${LOCAL_PATH_TESTFILES_SABER} )
    if( NOT EXISTS ${TESTFILE_DIR_SABER}/testdata )
        message( FATAL_ERROR "Directory ${TESTFILE_DIR_SABER}/testdata is missing" )
    endif()
    if( NOT EXISTS ${TESTFILE_DIR_SABER}/testref )
        message( FATAL_ERROR "Directory ${TESTFILE_DIR_SABER}/testref is missing" )
    endif()
    message( STATUS "Files loaded from: " ${TESTFILE_DIR_SABER} )
endif()

# Setup SABER directories and links
message( STATUS "Setup SABER directories and links" )
file(WRITE ${CMAKE_BINARY_DIR}/bin/saber_testdir)
foreach( test ${saber_test} ${saber_test_model} ${saber_test_oops})
    file(APPEND ${CMAKE_BINARY_DIR}/bin/saber_testdir ${test}\n)
endforeach()
file(WRITE ${CMAKE_BINARY_DIR}/bin/saber_testdata)
foreach( file ${saber_data} )
    file(APPEND ${CMAKE_BINARY_DIR}/bin/saber_testdata ${file}\n)
endforeach()
file(WRITE ${CMAKE_BINARY_DIR}/bin/saber_testref)
foreach( file ${saber_ref} )
    file(APPEND ${CMAKE_BINARY_DIR}/bin/saber_testref ${file}\n)
endforeach()
execute_process( COMMAND bash ${CMAKE_BINARY_DIR}/bin/saber_setup.sh
                         ${TESTFILE_DIR_SABER}
                         ${CMAKE_CURRENT_BINARY_DIR}
                         ${CMAKE_BINARY_DIR} )

# Download SABER data
if( NOT DEFINED LOCAL_PATH_TESTFILES_SABER )
    message( STATUS "Download sources:" )

    # Check whether the URLs exist or not
    foreach ( saber_data_tar_name ${saber_data_tar} )
        list( APPEND url_names_data ${GIT_BRANCH}/${saber_data_tar_name} )
    endforeach()
    ecbuild_check_urls( NAMES  ${url_names_data}
                        RESULT SPECIFIC_TEST_FILES )

    # Set distant directory
    if( SPECIFIC_TEST_FILES MATCHES 0 )
        # Download and extract new test files (distant directory = git branch)
        set( DIRNAME ${GIT_BRANCH} )
    else()
        # Download and extract develop test files (distant directory = develop)
        set( DIRNAME "develop" )
    endif()
    message( STATUS "  Test data: " ${ECBUILD_DOWNLOAD_BASE_URL} "/" ${DIRNAME} )

    # Download and extract data files
    ecbuild_get_test_multidata( TARGET   get_saber_data
                                NAMES    ${saber_data_tar}
                                DIRNAME  ${DIRNAME}
                                DIRLOCAL ${TESTFILE_DIR_SABER}/testdata
                                EXTRACT )

    # Check whether the URLs exist or not
    foreach( saber_ref_tar_name ${saber_ref_tar} )
        list( APPEND url_names_ref ${GIT_BRANCH}/${saber_ref_tar_name} )
    endforeach()
    ecbuild_check_urls( NAMES  ${url_names_ref}
                        RESULT SPECIFIC_TEST_FILES )

    # Set distant directory
    if( SPECIFIC_TEST_FILES MATCHES 0 )
        # Download and extract new test files (distant directory = git branch)
        set( DIRNAME ${GIT_BRANCH} )
    else()
        # Download and extract develop test files (distant directory = develop)
        set( DIRNAME "develop" )
    endif()
    message( STATUS "  Reference: " ${ECBUILD_DOWNLOAD_BASE_URL}/${DIRNAME} )

    # Download and extract reference files
    ecbuild_get_test_multidata( TARGET   get_saber_ref
                                NAMES    ${saber_ref_tar}
                                DIRNAME  ${DIRNAME}
                                DIRLOCAL ${TESTFILE_DIR_SABER}/testref
                                EXTRACT )
endif()

# Executables
ecbuild_add_executable( TARGET  saber_bump.x
                        SOURCES mains/bump_main.cc
                                mains/bump_main.F90
                                mains/type_model.F90
                        LIBS    saber )

if ( SABER_TEST_OOPS OR SABER_TEST_INTERPOLATION )
    set( QG_LIBS saber ${oops_qg_LIBRARIES} )
endif()
if( SABER_TEST_OOPS )
    ecbuild_add_executable( TARGET  saber_qg_estimate_parameters.x
                            SOURCES mains/qgEstimateParams.cc
                            LIBS    ${QG_LIBS} )

    ecbuild_add_executable( TARGET  saber_qg_dirac.x
                            SOURCES mains/qgDirac.cc
                            LIBS    ${QG_LIBS} )

    ecbuild_add_executable( TARGET  saber_qg_4dvar.x
                            SOURCES mains/qg4DVar.cc
                            LIBS    ${QG_LIBS} )

endif()
if( SABER_TEST_INTERPOLATION )
    ecbuild_add_executable( TARGET  saber_interpolation_bump.x
                            SOURCES mains/InterpolationBump.cc
                            LIBS    ${QG_LIBS} )
endif()

# Mono-core tests
set( mpi 1 )
set( omp 1 )
foreach( test ${saber_test} )
    execute_process( COMMAND     sed "-e s/_MPI_/${mpi}/g;s/_OMP_/${omp}/g"
                     INPUT_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                     OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}_${mpi}-${omp}.yaml )

    ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_run
                      MPI          ${mpi}
                      OMP          ${omp}
                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_bump.x
                      ARGS         testinput/${test}_${mpi}-${omp}.yaml testoutput
                      DEPENDS      saber_bump.x
                      TEST_DEPENDS get_saber_data )

    ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_compare
                      TYPE SCRIPT
                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                      ARGS         ${test} ${mpi} ${omp}
                      TEST_DEPENDS get_saber_ref
                                   test_${test}_${mpi}-${omp}_run )

#    if( SABER_TEST_PLOT )
#        ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_plot
#                          TYPE SCRIPT
#                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_plot.py
#                          ARGS         ${CMAKE_BINARY_DIR}/bin ${CMAKE_CURRENT_BINARY_DIR}/testdata ${test} ${mpi} ${omp}
#                          TEST_DEPENDS test_${test}_${mpi}-${omp}_run )
#    endif()

    if( SABER_TEST_VALGRIND )
        ecbuild_add_test( TARGET test_${test}_${mpi}-${omp}_valgrind
                          MPI    ${mpi}
                          OMP    ${omp}
                          COMMAND ${CMAKE_BINARY_DIR}/bin/saber_valgrind.sh
                          ARGS ${CMAKE_BINARY_DIR}/bin/saber_bump.x testinput/${test}_${mpi}-${omp}.yaml testoutput
                          DEPENDS saber_bump.x
                          TEST_DEPENDS get_saber_data )
    endif()
endforeach()

# Dual-core tests (MPI)
if( SABER_TEST_MPI )
    set( mpi 2 )
    set( omp 1 )
    foreach( test ${saber_test} )
        execute_process( COMMAND     sed "-e s/_MPI_/${mpi}/g;s/_OMP_/${omp}/g"
                         INPUT_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                         OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}_${mpi}-${omp}.yaml )

        ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_run
                          MPI          ${mpi}
                          OMP          ${omp}
                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_bump.x
                          ARGS         testinput/${test}_${mpi}-${omp}.yaml testoutput
                          DEPENDS      saber_bump.x
                          TEST_DEPENDS get_saber_data )

        ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_compare
                          TYPE SCRIPT
                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                          ARGS         ${test} ${mpi} ${omp}
                          TEST_DEPENDS get_saber_ref
                                       test_${test}_${mpi}-${omp}_run )

#        if( SABER_TEST_PLOT )
#            ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_plot
#                              TYPE SCRIPT
#                              COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_plot.py
#                              ARGS         ${CMAKE_BINARY_DIR}/bin ${CMAKE_CURRENT_BINARY_DIR}/testdata ${test} ${mpi} ${omp}
#                              TEST_DEPENDS test_${test}_${mpi}-${omp}_run )
#        endif()
    endforeach()
endif()

# Dual-core tests (OpenMP)
if( SABER_TEST_OMP )
    set( mpi 1 )
    set( omp 2 )
    foreach( test ${saber_test} )
        execute_process( COMMAND     sed "-e s/_MPI_/${mpi}/g;s/_OMP_/${omp}/g"
                         INPUT_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                         OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}_${mpi}-${omp}.yaml )

        ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_run
                          MPI          ${mpi}
                          OMP          ${omp}
                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_bump.x
                          ARGS         testinput/${test}_${mpi}-${omp}.yaml testoutput
                          DEPENDS      saber_bump.x
                          TEST_DEPENDS get_saber_data )

        ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_compare
                          TYPE SCRIPT
                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                          ARGS         ${test} ${mpi} ${omp}
                          TEST_DEPENDS get_saber_ref
                                       test_${test}_${mpi}-${omp}_run )

#        if( SABER_TEST_PLOT )
#            ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_plot
#                              TYPE SCRIPT
#                              COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_plot.py
#                              ARGS         ${CMAKE_BINARY_DIR}/bin ${CMAKE_CURRENT_BINARY_DIR}/testdata ${test} ${mpi} ${omp}
#                              TEST_DEPENDS test_${test}_${mpi}-${omp}_run )
#        endif()
    endforeach()
endif()

# Multi-core tests (MPI)
if( SABER_TEST_MULTI )
    # Get the number of available processors
    execute_process( COMMAND python ${CMAKE_CURRENT_SOURCE_DIR}/get_nprocs.py
                    OUTPUT_VARIABLE nproc )
    set( omp 1 )
    foreach( mpi RANGE 4 12 2 )
        if( ${mpi} LESS_EQUAL ${nproc} )
            foreach( test ${saber_test_multi} )
                execute_process( COMMAND     sed "-e s/_MPI_/${mpi}/g;s/_OMP_/${omp}/g"
                                 INPUT_FILE  ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                                 OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}_${mpi}-${omp}.yaml )

                ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_run
                                  MPI          ${mpi}
                                  OMP          ${omp}
                                  COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_bump.x
                                  ARGS         testinput/${test}_${mpi}-${omp}.yaml testoutput
                                  DEPENDS      saber_bump.x
                                  TEST_DEPENDS get_saber_data )

                ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_compare
                                  TYPE SCRIPT
                                  COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                                  ARGS         ${test} ${mpi} ${omp}
                                  TEST_DEPENDS get_saber_ref
                                               test_${test}_${mpi}-${omp}_run )

#                if( SABER_TEST_PLOT )
#                    ecbuild_add_test( TARGET       test_${test}_${mpi}-${omp}_plot
#                                      TYPE SCRIPT
#                                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_plot.py
#                                      ARGS         ${CMAKE_BINARY_DIR}/bin ${CMAKE_CURRENT_BINARY_DIR}/testdata ${test} ${mpi} ${omp}
#                                      TEST_DEPENDS test_${test}_${mpi}-${omp}_run )
#                endif()
            endforeach()
        endif()
    endforeach()
endif()

# Specific comparisons
ecbuild_add_test( TARGET       test_bump_read_cmat_parallel-serial_compare
                  TYPE SCRIPT
                  COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                  ARGS         bump_read_cmat bump_read_cmat_serial 2-1 dirac
                  TEST_DEPENDS test_bump_read_cmat_2-1_run
                               test_bump_read_cmat_serial_2-1_run )

ecbuild_add_test( TARGET       test_bump_write_cmat_parallel-serial_compare
                  TYPE SCRIPT
                  COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                  ARGS         bump_write_cmat bump_write_cmat_serial 2-1 cmat
                  TEST_DEPENDS test_bump_write_cmat_2-1_run
                               test_bump_write_cmat_serial_2-1_run )

if( SABER_TEST_TIER GREATER 1 )
    ecbuild_add_test( TARGET       test_bump_nicas_mpicom_lsqrt_a-b_dirac_compare
                      TYPE SCRIPT
                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                      ARGS         bump_nicas_mpicom_lsqrt_a bump_nicas_mpicom_lsqrt_b 1-1 dirac
                      TEST_DEPENDS test_bump_nicas_mpicom_lsqrt_a_1-1_run
                                   test_bump_nicas_mpicom_lsqrt_b_1-1_run )

    ecbuild_add_test( TARGET       test_bump_nicas_mpicom_lsqrt_a-c_dirac_compare
                      TYPE SCRIPT
                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_compare.sh
                      ARGS         bump_nicas_mpicom_lsqrt_a bump_nicas_mpicom_lsqrt_c 1-1 dirac
                      TEST_DEPENDS test_bump_nicas_mpicom_lsqrt_a_1-1_run
                                   test_bump_nicas_mpicom_lsqrt_c_1-1_run )
endif()

# Model tests
if( SABER_TEST_MODEL )
    set( mpi 6 )
    set( omp 1 )
    foreach( test ${saber_test_model} )
        execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
                         ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                         ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}.yaml )

        ecbuild_add_test( TARGET  test_${test}_link
                          COMMAND ${CMAKE_BINARY_DIR}/bin/saber_links.ksh
                          ARGS    ${SABER_TEST_MODEL_DIR} ${CMAKE_CURRENT_BINARY_DIR}/testdata ${test} )

        ecbuild_add_test( TARGET       test_${test}_run
                          MPI          ${mpi}
                          OMP          ${omp}
                          COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_bump.x
                          ARGS         testinput/${test}.yaml testoutput
                          DEPENDS      saber_bump.x
                          TEST_DEPENDS test_${test}_link )
    endforeach()
endif()

# OOPS tests
if( SABER_TEST_OOPS )
    foreach( test ${saber_test_oops} )
        # Link to yaml files
        execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
                         ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                         ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}.yaml )

        # Link to reference files
        execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
                         ${CMAKE_CURRENT_BINARY_DIR}/testref/${test}/test.log.out
                         ${CMAKE_CURRENT_BINARY_DIR}/testoutput/${test}/test.ref )
    endforeach()

    # Parameters tests
    foreach( test ${saber_test_oops} )
        string( FIND ${test} "qg_parameters" qg_parameters )
        if( qg_parameters MATCHES 0 )
            string(SUBSTRING ${test} 3 -1 testname )
            ecbuild_add_test( TARGET test_qg_${testname}
                              TYPE SCRIPT
                              COMMAND ${oops_BINDIR}/oops_test_wrapper.sh
                              ARGS ${CMAKE_BINARY_DIR}/bin/saber_qg_estimate_parameters.x
                                   testinput/${test}.yaml
                                   ${oops_BINDIR}/oops_compare.py
                                   ${test}/test.log.out
                                   ${test}/test.ref
                                   0.0
                                   0
                                   "${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} 1"
                              OMP 2
                              DEPENDS saber_qg_estimate_parameters.x
                              TEST_DEPENDS get_saber_data )
        endif()
    endforeach()

    #??Links
    ecbuild_add_test( TARGET       test_qg_links
                      TYPE SCRIPT
                      COMMAND      ${CMAKE_BINARY_DIR}/bin/saber_qg_links.sh
                      TEST_DEPENDS test_qg_parameters_bump_cov
                                   test_qg_parameters_bump_hyb
                                   test_qg_parameters_bump_lct
                                   test_qg_parameters_bump_loc )


    foreach( test ${saber_test_oops} )
        # Number of tasks
        string( FIND ${test} "4d" 4dpos REVERSE )
        string( LENGTH ${test} length )
        math( EXPR 4d ${length}-${4dpos}-2 )
        if ( (4d MATCHES 0) OR (test MATCHES qg_4densvar_bump) )
            set( NTASKS 13 )
        else()
            set( NTASKS 1 )
        endif()

        # Dirac tests
        string( FIND ${test} "qg_dirac" qg_dirac )
        if ( qg_dirac MATCHES 0 )
            ecbuild_add_test( TARGET test_${test}
                              TYPE SCRIPT
                              COMMAND ${oops_BINDIR}/oops_test_wrapper.sh
                              ARGS ${CMAKE_BINARY_DIR}/bin/saber_qg_dirac.x
                                   testinput/${test}.yaml
                                   ${oops_BINDIR}/oops_compare.py
                                   ${test}/test.log.out
                                   ${test}/test.ref
                                   0.0
                                   0
                                   "${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${NTASKS}"
                              OMP 2
                              DEPENDS saber_qg_dirac.x
                              TEST_DEPENDS test_qg_links )
        endif()

        # Variational tests
        string( FIND ${test} "qg_3d" qg_3d )
        string( FIND ${test} "qg_4d" qg_4d )
        if ( (qg_3d MATCHES 0) OR (qg_4d MATCHES 0) )
            ecbuild_add_test( TARGET test_${test}
                              TYPE SCRIPT
                              COMMAND ${oops_BINDIR}/oops_test_wrapper.sh
                              ARGS ${CMAKE_BINARY_DIR}/bin/saber_qg_4dvar.x
                                   testinput/${test}.yaml
                                   ${oops_BINDIR}/oops_compare.py
                                   ${test}/test.log.out
                                   ${test}/test.ref
                                   0.0
                                   0
                                   "${MPIEXEC_EXECUTABLE} ${MPIEXEC_NUMPROC_FLAG} ${NTASKS}"
                              OMP 2
                              DEPENDS saber_qg_4dvar.x
                              TEST_DEPENDS test_qg_links )

        endif()
    endforeach()
endif()

# Interpolation tests
if( SABER_TEST_INTERPOLATION )
    # Link to yaml files
    list( APPEND saber_test_interpolation interpolation_bump )
    foreach( test ${saber_test_interpolation} )
        execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
                         ${CMAKE_CURRENT_SOURCE_DIR}/testinput/${test}.yaml
                         ${CMAKE_CURRENT_BINARY_DIR}/testinput/${test}.yaml )
    endforeach()

    # Add tests
    ecbuild_add_test( TARGET test_interpolation_bump
                      MPI 4
                      OMP 1
                      COMMAND ${CMAKE_BINARY_DIR}/bin/saber_interpolation_bump.x
                      ARGS    testinput/interpolation_bump.yaml
                      DEPENDS saber_interpolation_bump.x )
endif()
