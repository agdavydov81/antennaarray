# - Find IPP
# Find the native IPP includes and library
# This module defines
#  IPP_INCLUDE_DIRS, where to find ipp.h, etc.
#  IPP_LIBRARIES, the libraries needed to use IPP.
#  IPP_FOUND, If false, do not try to use IPP.

# set(IPP_USE_STATIC_LIBS ON) # OFF by default; In static link case do not forget call ippStaticInit() before calling other Intel IPP functions
# set(IPP_USE_PARALLEL_LIBS ON) # OFF by default

# http://software.intel.com/en-us/articles/simplified-link-instructions-for-the-ipp-library/

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(PROCESSOR_BITS 64)
else(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(PROCESSOR_BITS 32)
endif()

############################## Search for headers ##############################
if(NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "")
	set(IS_IPP_6 1)
else(NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "")
	## Search for Intel 11 or 12 compiler
	if ((NOT EXISTS ${ICPP11_ENV})  AND  (NOT EXISTS ${ICPP12_ENV}))
		if(WIN32)
			set(ICPP11_ENV $ENV{ICPP_COMPILER11})
			set(ICPP12_ENV $ENV{ICPP_COMPILER12})
		elseif(UNIX)
			set(ICPP12_ENV /opt/intel)
		endif()
	endif()


	if(ICPP12_ENV)
		set(ICPP_ROOT ${ICPP12_ENV})
	elseif(ICPP11_ENV)
		set(ICPP_ROOT ${ICPP11_ENV})
	else(ICPP12_ENV)
		if(IPP_FIND_REQUIRED)
			message(FATAL_ERROR "Could not find Intel 11 or 12 Compiler and IPP")
		else(IPP_FIND_REQUIRED)
			if(NOT IPP_FIND_QUIETLY)
				message(STATUS "Could not find Intel 11 or 12 Compiler and IPP")
			endif()
		endif()
	endif()
endif()


if(IS_IPP_6)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(IPP_LIB3264DIR em64t)
		set(IPP_LIB64SUFFIX em64t)
		set(IPP_INTEL_LIBPATH_SUFFIX /lib/intel64)
	else(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(IPP_LIB3264DIR ia32)
		set(IPP_INTEL_LIBPATH_SUFFIX /lib/ia32)
	endif()
	set(IPP_INCLUDE_PATH ${ICPP_ROOT}/ipp/${IPP_LIB3264DIR}/include)
else(IS_IPP_6)
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(IPP_LIB3264DIR intel64)
	else(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(IPP_LIB3264DIR ia32)
	endif()
	set(IPP_INCLUDE_PATH ${ICPP_ROOT}/ipp/include)
	set(IPP_INTEL_LIBPATH_SUFFIX /compiler/lib/${IPP_LIB3264DIR})
endif()


# override IPP_INCLUDE_PATH to environment variable is esists
if(NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "")
	set(IPP_INCLUDE_PATH $ENV{IPP${PROCESSOR_BITS}_ROOT}/include)
endif()


## Search for IPP headers
find_path(IPP_INCLUDE_DIRS ipp.h   HINTS ${IPP_INCLUDE_PATH} )
if(IPP_INCLUDE_DIRS)
	set(IPP_FOUND "YES")
else(IPP_INCLUDE_DIRS)
	set(IPP_FOUND "NO")
	set(IPP_MISSING ${IPP_MISSING} "ipp.h")
endif()


############################## Search for libraries ##############################
if(ICPP11_ENV OR NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "")
	set(IPP_LIBROOT ippac ippcc ippch ippcv ippdc ippdi ippgen ippi ippj ippm ippr ipps ippsc ippsr ippvc ippvm) # all libs except ippcore
	if (IPP_USE_STATIC_LIBS)
		foreach(IPP_LIB_CUR ${IPP_LIBROOT})
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ${IPP_LIB_CUR}emerged${IPP_LIB64SUFFIX})
		endforeach(IPP_LIB_CUR)
		if (IPP_USE_PARALLEL_LIBS)
			set(IPP_LIBST_PAR_SUFFIX _t)
		endif()
		foreach(IPP_LIB_CUR ${IPP_LIBROOT})
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ${IPP_LIB_CUR}merged${IPP_LIB64SUFFIX}${IPP_LIBST_PAR_SUFFIX})
		endforeach(IPP_LIB_CUR)

		if (IPP_USE_PARALLEL_LIBS)
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ippcore${IPP_LIB64SUFFIX}_t)
			if (UNIX)
				set(IPP_LIB_NAMES ${IPP_LIB_NAMES} libirc libsvml libimf libiomp5)
			else (UNIX)
				set(IPP_LIB_NAMES ${IPP_LIB_NAMES} libircmt svml_dispmt libmmt libiomp5md)
			endif()
		else (IPP_USE_PARALLEL_LIBS)
if(WIN32)
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ippcore${IPP_LIB64SUFFIX}l)
elseif(UNIX)
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ippcore${IPP_LIB64SUFFIX})
endif()
		endif()

		set(IPP_LIB_PATH ${ICPP_ROOT}/ipp/${IPP_LIB3264DIR}/lib)

	else (IPP_USE_STATIC_LIBS)
		foreach(IPP_LIB_CUR ${IPP_LIBROOT})
			set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ${IPP_LIB_CUR}${IPP_LIB64SUFFIX})
		endforeach(IPP_LIB_CUR)
		set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ippcore${IPP_LIB64SUFFIX} libiomp5md)
		set(IPP_LIB_PATH ${ICPP_ROOT}/ipp/${IPP_LIB3264DIR}/stublib)
	endif()
else(ICPP11_ENV OR NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "") # ICPP12_ENV
	set(IPP_LIBROOT ippac ippcc ippch ippcore ippcv ippdc ippdi ippi ippj ippm ippr ipps ippsc ippvc ippvm) # root names of all libs
	if (IPP_USE_STATIC_LIBS)
		if (IPP_USE_PARALLEL_LIBS)
			set(ICPP12_LIBSUFFIX _t)
			if (UNIX)
				set(ICPP12_ETCLIBS libirc libsvml libimf libiomp5)
			else (UNIX)
				set(ICPP12_ETCLIBS libircmt libirc svml_dispmt libmmt libiomp5md)
			endif()
		else (IPP_USE_PARALLEL_LIBS)
			set(ICPP12_LIBSUFFIX _l)
		endif()
	else(IPP_USE_STATIC_LIBS)
		set(ICPP12_ETCLIBS  libiomp5md)
	endif()
	foreach(IPP_LIB_CUR ${IPP_LIBROOT})
		set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ${IPP_LIB_CUR}${ICPP12_LIBSUFFIX})
	endforeach(IPP_LIB_CUR)
	set(IPP_LIB_NAMES ${IPP_LIB_NAMES} ${ICPP12_ETCLIBS})

	set(IPP_LIB_PATH ${ICPP_ROOT}/ipp/lib/${IPP_LIB3264DIR})
endif()


# override IPP_LIB_PATH to environment variable is esists
if(NOT $ENV{IPP${PROCESSOR_BITS}_ROOT} STREQUAL "")
	set(IPP_LIB_PATH $ENV{IPP${PROCESSOR_BITS}_ROOT}/lib)
endif()


foreach (IPP_LIBNAME ${IPP_LIB_NAMES})
	find_library(${IPP_LIBNAME}_LIBRARY
		NAMES ${IPP_LIBNAME}
		HINTS ${IPP_LIB_PATH} ${ICPP_ROOT}/${IPP_INTEL_LIBPATH_SUFFIX}
	)

	if(${IPP_LIBNAME}_LIBRARY)
		set(IPP_LIBRARIES ${IPP_LIBRARIES} ${${IPP_LIBNAME}_LIBRARY})
	else(${IPP_LIBNAME}_LIBRARY)
		set(IPP_FOUND "NO")
		set(IPP_MISSING ${IPP_MISSING} ${IPP_LIBNAME})
	endif()
endforeach(IPP_LIBNAME)


if(IPP_FOUND)
	if(NOT IPP_FIND_QUIETLY)
		message(STATUS "Found IPP: ${IPP_LIBRARIES}")
	endif()
else(IPP_FOUND)
	if(IPP_FIND_REQUIRED)
		message(FATAL_ERROR "Could not find IPP  (missing:  ${IPP_MISSING})")
	else(IPP_FIND_REQUIRED)
		if(NOT IPP_FIND_QUIETLY)
			message(STATUS "Could NOT find IPP  (missing:  ${IPP_MISSING})")
		endif()
	endif()
endif()

mark_as_advanced(IPP_LIBRARIES IPP_INCLUDE_DIRS)
