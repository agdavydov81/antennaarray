#include <iostream>
#include <string>
#include <portaudio.h>
#include <pugixml/pugixml.hpp>
#include <boost/thread.hpp>
#include <cstdio>

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

void disp_dev_info(const char *dev_type, PaDeviceIndex dev_ind, int ch_num);
int audio_stream_callback(	const int16_t *input, int16_t *output,
							unsigned long frameCount,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData );

int in_ch_num = 1, out_ch_num = 2;

int main(int argc, const char *argv[]) {
	int ret=0;
	PaError pa_err=paNoError;

	try {
		std::cout << "AudioFront 0.0.3" << std::endl;

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

		disp_dev_info("Input device", in_dev, in_ch_num);

		disp_dev_info("Output device", out_dev, out_ch_num);

		std::cout << "Sample rate: " << fs << std::endl;

		PaStream *audio_stream;
		PaStreamParameters in_stream_info =  {in_dev,  in_ch_num,  paInt16, Pa_GetDeviceInfo(in_dev )->defaultHighInputLatency,  NULL};
		PaStreamParameters out_stream_info = {out_dev, out_ch_num, paInt16, Pa_GetDeviceInfo(out_dev)->defaultHighOutputLatency, NULL};

		if((pa_err=Pa_OpenStream(&audio_stream, &in_stream_info, &out_stream_info, fs, paFramesPerBufferUnspecified, paClipOff, (PaStreamCallback *)audio_stream_callback, NULL))!=paNoError)
			throw std::runtime_error(std::string("Pa_OpenStream error: ")+Pa_GetErrorText(pa_err));

		// Now start recording
		if((pa_err=Pa_StartStream(audio_stream))!=paNoError)
			throw std::runtime_error(std::string("Pa_StartStream error: ")+Pa_GetErrorText(pa_err));

		printf("Hit ENTER to stop program.\n");
		getchar();

		if((pa_err=Pa_CloseStream(audio_stream))!=paNoError)
			throw std::runtime_error(std::string("Input Pa_CloseStream error: ")+Pa_GetErrorText(pa_err));
	}
	catch(const std::exception & err) {
		std::cerr << err.what() << std::endl;
		ret = -1;
	}

	return ret;
}

void disp_dev_info(const char *dev_type, PaDeviceIndex dev_ind, int ch_num) {
	const PaDeviceInfo * dev_info = Pa_GetDeviceInfo(dev_ind);
	const PaHostApiInfo * api_info = Pa_GetHostApiInfo(dev_info->hostApi);

	std::cout << dev_type << " (id=" << dev_ind << "):" << std::endl;

	std::cout	<< "    " << api_info->name << ": " << dev_info->name << " ("
		<< dev_info->maxInputChannels  << " ch, " << dev_info->defaultHighInputLatency  << " delay IN | "
		<< dev_info->maxOutputChannels << " ch, " << dev_info->defaultHighOutputLatency << " delay OUT, at "
		<< dev_info->defaultSampleRate << " Hz); " << ch_num << " channels open"
		<< std::endl;
}

int audio_stream_callback(	const int16_t *input, int16_t *output,
							unsigned long frameCount,
							const PaStreamCallbackTimeInfo* timeInfo,
							PaStreamCallbackFlags statusFlags,
							void *userData ) {

	if(in_ch_num==out_ch_num) {
		if(input)
			memmove(output, input, in_ch_num*frameCount*sizeof(*output));
		else
			memset(output, 0, in_ch_num*frameCount*sizeof(*output));
	}
	else { // in_ch_num!=out_ch_num
		if(in_ch_num==1 && out_ch_num==2) {
			int16_t *out_data=output;
			for(const int16_t *in_data=input, *in_end=input+frameCount*in_ch_num; in_data!=in_end; ) {
				*(out_data++) = *in_data;
				*(out_data++) = *(in_data++);
			}
		}
		else {
			for(int out_ch=0; out_ch<out_ch_num; ++out_ch) {
				int16_t *out_data=output+out_ch;
				for(const int16_t *in_data=input, *in_end=input+frameCount*in_ch_num; in_data!=in_end; in_data+=in_ch_num, out_data+=out_ch_num)
					*out_data = *in_data;
			}
		}
	}

	return paContinue;
}
