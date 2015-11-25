# Global settings
cmake_minimum_required(VERSION 2.6)
project(ARMProj)
set(${PROJECT_NAME}_VERSION_MAJOR 0)
set(${PROJECT_NAME}_VERSION_MINOR 0)
set(${PROJECT_NAME}_VERSION_PATCH 1)

# In order to be able to use the newly written FindXXX package, the
# location of the FindXXX.cmake file must be added to the cmake modules
# list from within a CMakeLists.txt file as follows:
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/CMake_modules/")

if (MSVC AND INTEL)
	# Intel Compiler best optimization options
	set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O3 /Ot /fp:fast=2 /QaxSSE2")
endif()
if (CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
#	if (NOT (CMAKE_BUILD_TYPE STREQUAL "Debug") )
#		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
#	endif()
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
endif()

if(UNIX)
	set(CMAKE_PLATFORM_TYPE "linux")
elseif(WIN32)
	set(CMAKE_PLATFORM_TYPE "win")
elseif(APPLE)
	set(CMAKE_PLATFORM_TYPE "apple")
else(UNIX)
	set(CMAKE_PLATFORM_TYPE "platform")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(CMAKE_PLATFORM "${CMAKE_PLATFORM_TYPE}64")
	set(ENV{LIB} $ENV{LIB64})
	set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)
else(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(CMAKE_PLATFORM "${CMAKE_PLATFORM_TYPE}32")
endif()

set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} "${CMAKE_SOURCE_DIR}/thirdpart/${CMAKE_PLATFORM}/include")
set(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} "${CMAKE_SOURCE_DIR}/thirdpart/${CMAKE_PLATFORM}/lib")

# Plug Boost
# set(Boost_DEBUG 1)
if (WIN32)
	set(Boost_USE_STATIC_LIBS   ON)
endif()
set(Boost_USE_MULTITHREADED ON)
add_definitions(-DBOOST_ALL_NO_LIB)
add_definitions(-DBOOST_FILESYSTEM_VERSION=3)
find_package(Boost REQUIRED COMPONENTS thread filesystem system date_time regex unit_test_framework program_options chrono)
include_directories(${Boost_INCLUDE_DIRS})
#link_directories(${Boost_LIBRARY_DIRS})

#Plug PortAudio
find_package(PORTAUDIO REQUIRED)
if (PORTAUDIO_FOUND)
	include_directories(${PORTAUDIO_INCLUDE_DIRS})
endif()

# Plug DSP libraries
# set(IPP_USE_STATIC_LIBS ON)
# find_package(IPP REQUIRED) # Plug IPP
# if (IPP_FOUND)
# 	include_directories(${IPP_INCLUDE_DIRS})
# 	add_definitions(-DHAVE_IPP)
# 	add_definitions(-DDSP_FFT_IPP)
# 	set(DSP_LIBRARIES ${DSP_LIBRARIES} ${IPP_LIBRARIES})
# endif()

# if(WIN32)
# 	set(MKL_USE_STATIC_LIBS ON)
# endif()
# # set(MKL_USE_LP64 ON)
# find_package(MKL REQUIRED) # Plug MKL
# if(MKL_FOUND)
# 	include_directories(${MKL_INCLUDE_DIRS})
# 	add_definitions(-DHAVE_MKL)
# 	if(CMAKE_SIZEOF_VOID_P EQUAL 8 AND NOT MKL_USE_LP64)
# 		add_definitions(-DMKL_ILP64)
# 	endif()
# endif()
# 
# find_package(Grundton3 REQUIRED) # plug Grundton3
# include_directories(${GRUNDTON3_INCLUDE_DIRS})
# 
# find_package(INTL REQUIRED) # plug INTL localisation library
# include_directories(${INTL_INCLUDE_DIRS})
# 
# find_package(ICONV REQUIRED) # plug INTL localisation library
# include_directories(${ICONV_INCLUDE_DIRS})

find_package(SNDFILE REQUIRED) # plug libsndfile
include_directories(${SNDFILE_INCLUDE_DIRS})

if(NOT WIN32)
	find_package(LibDL REQUIRED) # plud dynamic library loading Unix mechanism
	include_directories(${LIBDL_INCLUDE_DIRS})
endif()

include_directories(${CMAKE_SOURCE_DIR}/auxiliary)
include_directories(${PROJECT_BINARY_DIR})


# MSVC bugfeaturefixes
if(MSVC)
	add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
	add_definitions(-D_SCL_SECURE_NO_DEPRECATE)
	add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
	add_definitions(-DNOMINMAX)
endif()


# # target docs
# #configure_file(doxyfile.in doxyfile @ONLY)
# #add_custom_target(DOCUMENTATION   COMMAND doxygen ${PROJECT_BINARY_DIR}/doxyfile   WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})


set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/build/${CMAKE_PLATFORM})
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/build/${CMAKE_PLATFORM})
# set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/../../bin/build_${CMAKE_PLATFORM})

# Enable testing for current directory and below
enable_testing()
find_program(PURIFYCOMMAND purify)
if(PURIFYCOMMAND)
	message(STATUS "Found PURIFY testing tool: " ${PURIFYCOMMAND})
else(PURIFYCOMMAND)
	find_program(MEMORYCHECK_COMMAND valgrind)
	if(MEMORYCHECK_COMMAND)
		message(STATUS "Found VALGRIND testing tool: " ${MEMORYCHECK_COMMAND})
	endif()
endif()


# submodules
add_subdirectory(auxiliary)
# add_subdirectory(vmorph)
add_subdirectory(audiofront)


## build a CPack driven installer package
#include(InstallRequiredSystemLibraries)
#set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_NAME} - Crossplatform speech tools")
#set(CPACK_PACKAGE_VENDOR "DevTeam")
#set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_SOURCE_DIR}/License.txt")
#set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/License.txt")
#set(CPACK_PACKAGE_VERSION_MAJOR "${${PROJECT_NAME}_VERSION_MAJOR}")
#set(CPACK_PACKAGE_VERSION_MINOR "${${PROJECT_NAME}_VERSION_MINOR}")
#set(CPACK_PACKAGE_VERSION_PATCH "${${PROJECT_NAME}_VERSION_PATCH}")
#set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
#set(CPACK_PACKAGE_CONTACT "none@google.com")
#set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
#if(WIN32)
##	set(CPACK_PACKAGE_ICON "${CMAKE_SOURCE_DIR}\\\\logo.ico")
#	set(CPACK_NSIS_DISPLAY_NAME "DevTeam ${PROJECT_NAME} ${CPACK_PACKAGE_VERSION}")
#	set(CPACK_NSIS_HELP_LINK "http://none.com/")
#	set(CPACK_NSIS_URL_INFO_ABOUT "http://none.com/")
#	set(CPACK_NSIS_CONTACT ${CPACK_PACKAGE_CONTACT})
#else(WIN32)
#	if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
#		set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
#	else(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "x86_64")
#		set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
#	endif()
#	set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.3.1-6), libgcc1 (>= 1:4.4.1-12) libintl(>=1.18) libsndfile1(>=1.20)")
#	set(CPACK_RPM_PACKAGE_LICENSE ${CPACK_RESOURCE_FILE_LICENSE})
#	set(CPACK_RPM_PACKAGE_GROUP "devel")
#	set(CPACK_RPM_PACKAGE_REQUIRES "libc6>=2.3.1, libgcc1>=4.4.1 libintl>=1.18, libsndfile1>=1.20")
#endif()
#include(CPack)

# enable dashboard scripting
include(CTest)
