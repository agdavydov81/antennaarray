set(NAME monolog)

set(${NAME}_SRCS
	monolog.cpp
	text_generator.h
	text_generator.cpp
	allophone_tts.h
	allophone_tts.cpp
	audio.h
	audio.cpp
	../auxiliary/wav_markers_regions.cpp
	../auxiliary/libresample/src/filterkit.c
	../auxiliary/libresample/src/resample.c
	../auxiliary/libresample/src/resamplesubs.c
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
install(FILES monolog.xml det_res.txt DESTINATION bin)
install(DIRECTORY db_bor1 DESTINATION bin)
if (WIN32)
	install(FILES ${PORTAUDIO_LIBRARIES_DLL} ${SNDFILE_LIBRARIES_DLL} DESTINATION bin)
endif()
