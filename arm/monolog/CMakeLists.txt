set(NAME monolog)

set(${NAME}_SRCS
	monolog.cpp
	text_generator.h
	text_generator.cpp
	allophone_tts.h
	allophone_tts.cpp
	audio.h
	audio.cpp
	../auxiliary/libresample/src/filterkit.c
	../auxiliary/libresample/src/resample.c
	../auxiliary/libresample/src/resamplesubs.c
	../auxiliary/wav_markers_regions.cpp
	)

add_executable(${NAME} ${${NAME}_SRCS})
target_link_libraries(${NAME} ${PORTAUDIO_LIBRARIES} ${SNDFILE_LIBRARIES} ${Boost_LIBRARIES})
if (NOT WIN32)
	target_link_libraries(${NAME} ${LIBDL_LIBRARIES} pthread)
endif()

install(TARGETS ${NAME}   DESTINATION bin)
install(FILES monolog.xml det_res.txt DESTINATION share/slspp/monolog)
install(DIRECTORY db_bor1 DESTINATION share/slspp/monolog)
if (WIN32)
	install(FILES ${PORTAUDIO_LIBRARIES_DLL} ${SNDFILE_LIBRARIES_DLL} DESTINATION bin)
endif()
