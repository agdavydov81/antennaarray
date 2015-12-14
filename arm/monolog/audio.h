#ifndef AUDIO_H
#define AUDIO_H

#include <iostream>
#include <deque>
#include <portaudio.h>
#include <cstdint>
#include <boost/thread.hpp>

void portaudio_init();

void portaudio_list_devices();

struct PORTAUDIO_USERDATA {
	std::deque<int16_t> data;
	boost::mutex mut;
};
void portaudio_stream_callback(const int16_t *input, int16_t *output, unsigned long frameCount,
	const PaStreamCallbackTimeInfo* timeInfo, PaStreamCallbackFlags statusFlags, PORTAUDIO_USERDATA *userData);

#endif // AUDIO_H
