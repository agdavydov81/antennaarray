# - Find SNDFILE
# Find the native LIBSNDFILE includes and library
# This module defines
#  SNDFILE_INCLUDE_DIRS, where to find sndfile.h, etc.
#  SNDFILE_LIBRARIES, the libraries needed to use SNDFILE.
#  SNDFILE_FOUND, If false, do not try to use SNDFILE.

find_path(SNDFILE_INCLUDE_DIRS sndfile.h  /usr/include )

find_library(SNDFILE_LIBRARIES  NAMES libsndfile-1 sndfile  /usr/lib )

if (WIN32)
	find_file(SNDFILE_LIBRARIES_DLL "libsndfile-1.dll" /usr/lib)
	if(NOT SNDFILE_LIBRARIES_DLL)
		message(FATAL_ERROR "Could not find SNDFILE DLL (libsndfile-1.dll)")
	endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SNDFILE  DEFAULT_MSG  SNDFILE_LIBRARIES SNDFILE_INCLUDE_DIRS)

mark_as_advanced(SNDFILE_LIBRARIES SNDFILE_INCLUDE_DIRS)
