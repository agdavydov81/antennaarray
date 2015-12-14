set(NAME monolog)

set(${NAME}_SRCS
	monolog.cpp
	text_generator.h
	text_generator.cpp
	allophone_tts.h
	allophone_tts.cpp
	../auxiliary/wav_markers_regions.h
	../auxiliary/wav_markers_regions.cpp
	audio.h
	audio.cpp
	)

add_definitions(-DUNICODE -D_UNICODE)
if (WIN32)
	add_definitions(-DENABLE_SNDFILE_WINDOWS_PROTOTYPES=1)
endif()

add_executable(${NAME} ${${NAME}_SRCS})
target_link_libraries(${NAME} ${PORTAUDIO_LIBRARIES} ${SNDFILE_LIBRARIES} ${Boost_LIBRARIES})
if (NOT WIN32)
	target_link_libraries(${NAME} ${LIBDL_LIBRARIES} pthread)
endif()

install(TARGETS ${NAME}   DESTINATION bin)
