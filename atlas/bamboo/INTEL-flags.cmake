# don't use trans library until it supports build without MPI
set( ENABLE_MPI                 OFF CACHE BOOL "Disable MPI under Intel compilation" )
set( ENABLE_TRANS               ON  CACHE BOOL "Enable TRANS" )
set( ENABLE_BOUNDSCHECKING      ON  CACHE BOOL "Enable bounds checking")
set( ENABLE_TESSELATION         OFF CACHE BOOL "Disable CGAL" ) # cgal is old in leap42
