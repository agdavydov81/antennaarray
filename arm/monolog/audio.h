#ifndef AUDIO_H
#define AUDIO_H

#include <iostream>
#include <portaudio.h>

class PortAudio
{
public:
	PortAudio();
	virtual ~PortAudio();

	void ListDevices(std::ostream &out = std::cout) const;
private:
	void ListSupportedStandardSampleRates(std::ostream &out, const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters) const;

	PaStream *audio_stream;
public:
	void Open(int out_device_, int channels_, double samplerate_, PaStreamCallback *user_callback_, void *user_data_);
	void Close();

	operator bool() const;
};

#endif // AUDIO_H
