#include <iostream>
#include <string>
#include <portaudio.h>
#include <pugixml/pugixml.hpp>
#include <boost/thread.hpp>

struct PA_OBJECT {
	PA_OBJECT() {
		PaError pa_err;
		if((pa_err=Pa_Initialize())!=paNoError)
			throw std::runtime_error(std::string("Pa_Initialize error: ")+Pa_GetErrorText(pa_err));
	}
	~PA_OBJECT() {
		Pa_Terminate();
	}
};

void disp_dev_info(PaDeviceIndex dev_ind);
int audio_stream_callback(	const void *input, void *output,
							unsigned long frameCount,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData );

int main(void) {
	int ret=0;
	PaError pa_err=paNoError;

	try {
		std::cout << "AudioFront 0.0.1" << std::endl;
		std::cout << Pa_GetVersionText() << std::endl;

		double fs = 11025;

		PA_OBJECT pa_obj;

		PaDeviceIndex in_dev=Pa_GetDefaultInputDevice();
		if(in_dev==paNoDevice)
			throw std::runtime_error("PortAudio: No default input device");
		std::cout << "Input device:" << std::endl;
		disp_dev_info(in_dev);

		PaDeviceIndex out_dev=Pa_GetDefaultOutputDevice();
		if(out_dev==paNoDevice)
			throw std::runtime_error("PortAudio: No default output device");
		std::cout << "Output device:" << std::endl;
		disp_dev_info(out_dev);

		PaStream *audio_stream;
		PaStreamParameters in_stream_info =  {in_dev,  1, paInt16, Pa_GetDeviceInfo(in_dev )->defaultLowInputLatency,  NULL};
		PaStreamParameters out_stream_info = {out_dev, 1, paInt16, Pa_GetDeviceInfo(out_dev)->defaultLowOutputLatency, NULL};

		if((pa_err=Pa_OpenStream(&audio_stream, &in_stream_info, &out_stream_info, fs, paFramesPerBufferUnspecified, paClipOff, audio_stream_callback, NULL))!=paNoError)
			throw std::runtime_error(std::string("Pa_OpenStream error: ")+Pa_GetErrorText(pa_err));

		if((pa_err=Pa_StartStream(audio_stream))!=paNoError)
			throw std::runtime_error(std::string("Pa_StartStream error: ")+Pa_GetErrorText(pa_err));

		printf("Hit ENTER to stop program.\n");
		getchar();

		if((pa_err=Pa_CloseStream(audio_stream))!=paNoError)
			throw std::runtime_error(std::string("Pa_CloseStream error: ")+Pa_GetErrorText(pa_err));
	}
	catch(const std::exception & err) {
		std::cerr << err.what() << std::endl;
		ret = -1;
	}

	return ret;
}

void disp_dev_info(PaDeviceIndex dev_ind) {
	const PaDeviceInfo * dev_info = Pa_GetDeviceInfo(dev_ind);
	const PaHostApiInfo * api_info = Pa_GetHostApiInfo(dev_info->hostApi);

	std::cout	<< "    " << api_info->name << ": " << dev_info->name << " ("
		<< dev_info->maxInputChannels  << " ch, " << dev_info->defaultLowInputLatency  << " delay IN | "
		<< dev_info->maxOutputChannels << " ch, " << dev_info->defaultLowOutputLatency << " delay OUT, at "
		<< dev_info->defaultSampleRate << " Hz)"
		<< std::endl;
}

int audio_stream_callback(	const void *input, void *output,
							unsigned long frameCount,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData ) {

	if(input)
		memmove(output, input, frameCount*sizeof(int16_t));
	else
		memset(output, 0, frameCount*sizeof(int16_t));

	return paContinue;
}
