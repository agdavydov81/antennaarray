set(NAME audiofront)

set(${NAME}_SRCS
	audiofront.cpp
	)

add_definitions(-DUNICODE -D_UNICODE)

add_executable(${NAME} ${${NAME}_SRCS})
target_link_libraries(${NAME} ${PORTAUDIO_LIBRARIES} ${SNDFILE_LIBRARIES} ${Boost_LIBRARIES})
if (NOT WIN32)
	target_link_libraries(${NAME} ${LIBDL_LIBRARIES} pthread)
endif()

install(TARGETS ${NAME}   DESTINATION bin)



add_executable(pa_devs pa_devs.c)
target_link_libraries(pa_devs ${PORTAUDIO_LIBRARIES})
install(TARGETS pa_devs   DESTINATION bin)


add_executable(paex_read_write_wire paex_read_write_wire.c)
target_link_libraries(paex_read_write_wire ${PORTAUDIO_LIBRARIES})
install(TARGETS paex_read_write_wire   DESTINATION bin)
