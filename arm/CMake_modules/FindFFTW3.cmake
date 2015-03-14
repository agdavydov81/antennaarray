# - Find FFTW3
# Find the native FFTW3 includes and library
# This module defines
#  FFTW3_INCLUDE_DIRS, where to find fftw3.h, etc.
#  FFTW3_LIBRARIES, the libraries needed to use FFTW3.
#  FFTW3_FOUND, If false, do not try to use FFTW3.

find_path(FFTW3_INCLUDE_DIRS fftw3.h)

find_library(FFTW3_LIBRARY_FLOAT		NAMES libfftw3f-3)
find_library(FFTW3_LIBRARY_DOUBLE  		NAMES libfftw3-3)
find_library(FFTW3_LIBRARY_LONGDOUBLE	NAMES libfftw3l-3)

set(FFTW3_LIBRARIES ${FFTW3_LIBRARY_FLOAT} ${FFTW3_LIBRARY_DOUBLE} ${FFTW3_LIBRARY_LONGDOUBLE})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FFTW3  DEFAULT_MSG  FFTW3_LIBRARY_FLOAT FFTW3_LIBRARY_DOUBLE FFTW3_LIBRARY_LONGDOUBLE FFTW3_INCLUDE_DIRS) 

mark_as_advanced(FFTW3_INCLUDE_DIRS FFTW3_LIBRARIES)
