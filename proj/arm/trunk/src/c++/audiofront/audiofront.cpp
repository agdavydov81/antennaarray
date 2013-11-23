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

void disp_dev_info(const char *dev_type, PaDeviceIndex dev_ind);
int audio_stream_callback(	const void *input, void *output,
							unsigned long frameCount,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData );

int main(int argc, const char *argv[]) {
	int ret=0;
	PaError pa_err=paNoError;

	try {
		std::cout << "AudioFront 0.0.2" << std::endl;

		if(argc!=1 && argc!=3 && argc!=4)
			throw std::runtime_error("Usage: audiofront [dev_in dev_out] [fs]");

		std::cout << Pa_GetVersionText() << std::endl;

		double fs = 44100;

		PA_OBJECT pa_obj;

		PaDeviceIndex in_dev, out_dev;

		if(argc<2) {
			if((in_dev=Pa_GetDefaultInputDevice())==paNoDevice)
				throw std::runtime_error("PortAudio: No default input device");
			if((out_dev=Pa_GetDefaultOutputDevice())==paNoDevice)
				throw std::runtime_error("PortAudio: No default output device");
		}
		if(argc>=3) {
			in_dev = atoi(argv[1]);
			out_dev = atoi(argv[2]);
		}
		if(argc>=4) {
			fs = atof(argv[3]);
		}

		disp_dev_info("Input device", in_dev);

		disp_dev_info("Output device", out_dev);

		std::cout << "Sample rate: " << fs << std::endl;

		PaStream *in_stream, *out_stream;
		PaStreamParameters in_stream_info =  {in_dev,  1, paInt16, Pa_GetDeviceInfo(in_dev )->defaultLowInputLatency,  NULL};
		PaStreamParameters out_stream_info = {out_dev, 1, paInt16, Pa_GetDeviceInfo(out_dev)->defaultLowOutputLatency, NULL};

		if((pa_err=Pa_OpenStream(&out_stream, NULL, &out_stream_info, fs, paFramesPerBufferUnspecified, paClipOff, NULL, NULL))!=paNoError)
			throw std::runtime_error(std::string("Output Pa_OpenStream error: ")+Pa_GetErrorText(pa_err));
		if((pa_err=Pa_OpenStream(&in_stream, &in_stream_info, NULL, fs, paFramesPerBufferUnspecified, paClipOff, audio_stream_callback, out_stream))!=paNoError)
			throw std::runtime_error(std::string("Input Pa_OpenStream error: ")+Pa_GetErrorText(pa_err));

		// Output stream buffering
		if((pa_err=Pa_StartStream(out_stream))!=paNoError)
			throw std::runtime_error(std::string("Output Pa_StartStream error: ")+Pa_GetErrorText(pa_err));
		std::vector<int16_t> delay_buf((size_t)(fs*0.5));
		if((pa_err=Pa_WriteStream(out_stream, &delay_buf[0], delay_buf.size())))
			throw std::runtime_error(std::string("Output Pa_WriteStream error: ")+Pa_GetErrorText(pa_err));

		// Now start recording
		if((pa_err=Pa_StartStream(in_stream))!=paNoError)
			throw std::runtime_error(std::string("Input Pa_StartStream error: ")+Pa_GetErrorText(pa_err));

		printf("Hit ENTER to stop program.\n");
		getchar();

		if((pa_err=Pa_CloseStream(in_stream))!=paNoError)
			throw std::runtime_error(std::string("Input Pa_CloseStream error: ")+Pa_GetErrorText(pa_err));
		if((pa_err=Pa_CloseStream(out_stream))!=paNoError)
			throw std::runtime_error(std::string("Output Pa_CloseStream error: ")+Pa_GetErrorText(pa_err));
	}
	catch(const std::exception & err) {
		std::cerr << err.what() << std::endl;
		ret = -1;
	}

	return ret;
}

void disp_dev_info(const char *dev_type, PaDeviceIndex dev_ind) {
	const PaDeviceInfo * dev_info = Pa_GetDeviceInfo(dev_ind);
	const PaHostApiInfo * api_info = Pa_GetHostApiInfo(dev_info->hostApi);

	std::cout << dev_type << " (id=" << dev_ind << "):" << std::endl;

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

	PaStream *out_stream = (PaStream *)userData;

	if(input)
		Pa_WriteStream(out_stream, input, frameCount);

	return paContinue;
}
