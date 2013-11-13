# - Find MKL
# Find the native MKL includes and library
# This module defines
#  MKL_INCLUDE_DIRS, where to find mkl.h, etc.
#  MKL_LIBRARIES, the libraries needed to use MKL.
#  MKL_FOUND, If false, do not try to use MKL.

#set(MKL_USE_STATIC_LIBS ON) # OFF by default
#set(MKL_USE_PARALLEL_LIBS ON) # OFF by default
#set(MKL_USE_LP64 ON) # OFF by default


## Search for Intel 11 or 12 compiler
set(ICPP11_ENV $ENV{ICPP_COMPILER11})
set(ICPP12_ENV $ENV{ICPP_COMPILER12})
if(UNIX)
  set(ICPP12_ENV /opt/intel)
endif()

if(ICPP12_ENV)
	set(ICPP_ROOT ${ICPP12_ENV})
elseif(ICPP11_ENV)
	set(ICPP_ROOT ${ICPP11_ENV})
else(ICPP12_ENV)
	if(MKL_FIND_REQUIRED)
		message(FATAL_ERROR "Could not find Intel 11 or 12 Compiler and MKL")
	else(MKL_FIND_REQUIRED)
		if(NOT MKL_FIND_QUIETLY)
			message(STATUS "Could not find Intel 11 or 12 Compiler and MKL")
		endif()
	endif()
endif()


## Search for MKL headers
find_path(MKL_INCLUDE_DIRS mkl.h   HINTS "${ICPP_ROOT}/mkl/include" )
if(MKL_INCLUDE_DIRS)
	set(MKL_FOUND "YES")
else(MKL_INCLUDE_DIRS)
	set(MKL_FOUND "NO")
	set(MKL_MISSING ${MKL_MISSING} "mkl.h")
endif()


## Search for MKL libs
if(WIN32)
	if(NOT MKL_USE_STATIC_LIBS)
		set(MKL_LIB_SUFFIX _dll)
	endif()
	set(MKL_EXT ".lib")
elseif(UNIX)
	if(MKL_USE_STATIC_LIBS)
		set(MKL_EXT ".a")
	else(MKL_USE_STATIC_LIBS)
		set(MKL_EXT ".so")
	endif()
	set(MKL_NAME_PREFIX "lib")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	if(MKL_USE_LP64)
		set(MKL_NAMES ${MKL_NAMES} mkl_intel_lp64${MKL_LIB_SUFFIX})
	else(MKL_USE_LP64)
		set(MKL_NAMES ${MKL_NAMES} mkl_intel_ilp64${MKL_LIB_SUFFIX})
		ADD_DEFINITIONS(-DMKL_ILP64)
	endif()
	if(ICPP12_ENV)
		set(MKL_LIBPATH_SUFFIX /mkl/lib/intel64)
		set(MKL_INTEL_LIBPATH_SUFFIX /compiler/lib/intel64)
	else(ICPP12_ENV)
		set(MKL_LIBPATH_SUFFIX /mkl/em64t/lib)
		set(MKL_INTEL_LIBPATH_SUFFIX /lib/intel64)
	endif()
else(CMAKE_SIZEOF_VOID_P EQUAL 8)
	if(ICPP12_ENV)
		set(MKL_LIBPATH_SUFFIX /mkl/lib/ia32)
		set(MKL_INTEL_LIBPATH_SUFFIX /compiler/lib/ia32)
	else(ICPP12_ENV)
		set(MKL_LIBPATH_SUFFIX /mkl/ia32/lib)
		set(MKL_INTEL_LIBPATH_SUFFIX /lib/ia32)
	endif()
	if(WIN32)
		set(MKL_NAMES ${MKL_NAMES} mkl_intel_c${MKL_LIB_SUFFIX})
	else(WIN32)
		set(MKL_NAMES ${MKL_NAMES} mkl_intel${MKL_LIB_SUFFIX})
	endif()
endif()

if(MKL_USE_PARALLEL_LIBS)
	set(MKL_NAMES ${MKL_NAMES} mkl_intel_thread${MKL_LIB_SUFFIX} libiomp5md)
else(MKL_USE_PARALLEL_LIBS)
	set(MKL_NAMES ${MKL_NAMES} mkl_sequential${MKL_LIB_SUFFIX})
endif()

set(MKL_NAMES ${MKL_NAMES} mkl_core${MKL_LIB_SUFFIX})

foreach(MKL_NAME ${MKL_NAMES})
	find_library(${MKL_NAME}_LIBRARY
		NAMES ${MKL_NAME_PREFIX}${MKL_NAME}${MKL_EXT}
		HINTS ${ICPP_ROOT}/${MKL_LIBPATH_SUFFIX} ${ICPP_ROOT}/${MKL_INTEL_LIBPATH_SUFFIX} /usr/lib64 /usr/lib /usr/local/lib64 /usr/local/lib /opt/intel/mkl/lib/lib64 /opt/intel/mkl/lib/ia32 /opt/intel/mkl/lib /opt/intel/*/mkl/lib/intel64 /opt/intel/*/mkl/lib/ia32/ /opt/mkl/*/lib/em64t /opt/mkl/*/lib/32 /opt/intel/mkl/*/lib/em64t /opt/intel/mkl/*/lib/32
	)

	if(${MKL_NAME}_LIBRARY)
		set(MKL_LIBRARIES ${MKL_LIBRARIES} ${${MKL_NAME}_LIBRARY})
	else(${MKL_NAME}_LIBRARY)
		set(MKL_FOUND "NO")
		set(MKL_MISSING ${MKL_MISSING} ${MKL_NAME})
	endif()
endforeach(MKL_NAME)

if(MKL_FOUND)
	if(NOT MKL_FIND_QUIETLY)
		message(STATUS "Found MKL: ${MKL_LIBRARIES}")
	endif()
else(MKL_FOUND)
	if(MKL_FIND_REQUIRED)
		message(FATAL_ERROR "Could not find MKL  (missing:  ${MKL_MISSING})")
	else(MKL_FIND_REQUIRED)
		if(NOT MKL_FIND_QUIETLY)
			message(STATUS "Could NOT find MKL  (missing:  ${MKL_MISSING})")
		endif()
	endif()
endif()

mark_as_advanced(MKL_LIBRARIES MKL_INCLUDE_DIRS)
