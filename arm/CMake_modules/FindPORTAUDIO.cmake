# - Find PORTAUDIO
# Find the native LIBPORTAUDIO includes and library
# This module defines
#  PORTAUDIO_INCLUDE_DIRS, where to find portaudio.h, etc.
#  PORTAUDIO_LIBRARIES, the libraries needed to use PORTAUDIO.
#  PORTAUDIO_FOUND, If false, do not try to use PORTAUDIO.

# set(PORTAUDIO_USE_STATIC_LIBS ON) # OFF by default
if (WIN32)
	if (PORTAUDIO_USE_STATIC_LIBS)
		set(PA_STATIC "_static")
	endif()
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(PA_PLATFORM "_x64")
	else(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(PA_PLATFORM "_x86")
	endif()
endif()

find_path(PORTAUDIO_INCLUDE_DIRS portaudio.h  /usr/include )

find_library(PORTAUDIO_LIBRARIES  NAMES "portaudio${PA_STATIC}${PA_PLATFORM}"  /usr/lib)
if (WIN32 AND NOT PORTAUDIO_USE_STATIC_LIBS)
	find_file(PORTAUDIO_LIBRARIES_DLL "portaudio${PA_PLATFORM}.dll" /usr/lib)
	if(NOT PORTAUDIO_LIBRARIES_DLL)
		message(FATAL_ERROR "Could not find PORTAUDIO DLL (portaudio${PA_PLATFORM}.dll)")
	endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PORTAUDIO  DEFAULT_MSG  PORTAUDIO_LIBRARIES PORTAUDIO_INCLUDE_DIRS)

mark_as_advanced(PORTAUDIO_LIBRARIES PORTAUDIO_INCLUDE_DIRS) 
