# - Find ICONV
# Find the native ICONV includes and library
# This module defines
#  ICONV_INCLUDE_DIRS, where to find iconv.h, etc.
#  ICONV_LIBRARIES, the libraries needed to use ICONV.
#  ICONV_FOUND, If false, do not try to use ICONV.

include(FindPackageHandleStandardArgs)

find_path(ICONV_INCLUDE_DIRS iconv.h)

if(WIN32)
	find_library(ICONV_LIBRARIES NAMES libiconv)
	find_package_handle_standard_args(ICONV  DEFAULT_MSG  ICONV_LIBRARIES ICONV_INCLUDE_DIRS)
else(WIN32)
	find_package_handle_standard_args(ICONV  DEFAULT_MSG  ICONV_INCLUDE_DIRS)
endif()

mark_as_advanced(ICONV_LIBRARIES ICONV_INCLUDE_DIRS)
