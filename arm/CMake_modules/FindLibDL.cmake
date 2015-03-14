# - Find libdl
# Find the native LIBDL includes and library
#
#  LIBDL_INCLUDE_DIRS - where to find dlfcn.h, etc.
#  LIBDL_LIBRARIES   - List of libraries when using libdl.
#  LIBDL_FOUND       - True if libdl found.


if (LIBDL_INCLUDE_DIRS)
  # Already in cache, be silent
  set(LIBDL_FIND_QUIETLY TRUE)
endif()

find_path(LIBDL_INCLUDE_DIRS dlfcn.h)

set(LIBDL_NAMES dl libdl ltdl libltdl)
find_library(LIBDL_LIBRARY NAMES ${LIBDL_NAMES} )

# handle the QUIETLY and REQUIRED arguments and set LIBDL_FOUND to TRUE if 
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibDL DEFAULT_MSG LIBDL_LIBRARY LIBDL_INCLUDE_DIRS)

if(LIBDL_FOUND)
  set( LIBDL_LIBRARIES ${LIBDL_LIBRARY} )
else(LIBDL_FOUND)
  set( LIBDL_LIBRARIES )
endif()

mark_as_advanced( LIBDL_LIBRARY LIBDL_INCLUDE_DIRS )
