#ifndef AUDIO_H
#define AUDIO_H

#include <iostream>
#include <portaudio.h>
#include <vector>

class PortAudio
{
public:
	PortAudio();
	virtual ~PortAudio();

	void ListDevices(std::ostream &out = std::cout) const;
private:
	std::vector<double> GetSupportedStandardSampleRates(const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters) const;
	void ListSupportedStandardSampleRates(std::ostream &out, const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters) const;

	PaStream *audio_stream;
public:
	double Open(int out_device_, int channels_, double samplerate_, double buffer, PaStreamCallback *user_callback_, void *user_data_);
	void Close();

	operator bool() const;
};

#endif // AUDIO_H
