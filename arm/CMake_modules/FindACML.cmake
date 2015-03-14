# - Find ACML
# Find the native ACML includes and library
# This module defines
#  ACML_INCLUDE_DIRS, where to find acml.h, etc.
#  ACML_LIBRARIES, the libraries needed to use ACML.
#  ACML_FOUND, If false, do not try to use ACML.

#set(ACML_USE_PARALLEL_LIBS ON) # OFF by default

if(WIN32)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(ACML_LIB3264 "win64")
	else(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(ACML_LIB3264 "pgi32")
	endif()
	if(ACML_USE_PARALLEL_LIBS)
		set(ACML_LIBMP "_mp")
	endif()
	set(ACML_SUBROOT "$ENV{ACML_ROOT}/${ACML_LIB3264}${ACML_LIBMP}")
endif()

find_path(ACML_INCLUDE_DIRS acml.h   HINTS "${ACML_SUBROOT}/include" )

find_library(ACML_LIBRARIES   NAMES libacml_dll   HINTS "${ACML_SUBROOT}/lib" )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ACML  DEFAULT_MSG  ACML_LIBRARIES ACML_INCLUDE_DIRS)

mark_as_advanced(ACML_LIBRARIES ACML_INCLUDE_DIRS)
