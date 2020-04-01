# (C) Copyright 2013 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

if( CMAKE_CXX_COMPILER_ID MATCHES Cray )

  ecbuild_add_cxx_flags("-hnomessage=3140") # colon separated numbers
  ecbuild_add_fortran_flags("-hnomessage=3140") # colon separated numbers

# CC-3140 crayc++: WARNING File = atlas/functionspace/NodeColumns.cc, Line = 1, Column = 1
#  The IPA optimization level was changed to "1" due to the presence of OMP
#          directives, ACC directives, or ASM intrinsics.

endif()

#ecbuild_add_cxx_flags("-Wl,-ydgemm_")
#ecbuild_add_fortran_flags("-Wl,-ydgemm_")
#ecbuild_add_cxx_flags("-fsanitize=address")
#ecbuild_add_cxx_flags("-fsanitize=thread")
#ecbuild_add_cxx_flags("-fsanitize=memory")
