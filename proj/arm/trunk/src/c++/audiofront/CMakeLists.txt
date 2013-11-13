set(NAME audiofront)

set(${NAME}_SRCS
	audiofront.cpp
	)

add_definitions(-DUNICODE -D_UNICODE)

add_executable(${NAME} ${${NAME}_SRCS})
target_link_libraries(${NAME} ${SNDFILE_LIBRARIES} ${Boost_LIBRARIES})
if (NOT WIN32)
	target_link_libraries(${NAME} ${LIBDL_LIBRARIES} pthread)
endif()

install(TARGETS ${NAME}   DESTINATION bin)
