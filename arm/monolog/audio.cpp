#include "audio.h"
#include <vector>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdexcept>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else // linux
#include <sys/ioctl.h>
#include <unistd.h>
#endif

PortAudio::PortAudio() : audio_stream(nullptr){
	/*
	int fd;
	// Suppress error messages output directly from library
	#ifdef WIN32
	fd = open("nul", O_WRONLY);
	#else
	fd = open("/dev/null", O_WRONLY);
	#endif
	dup2(fd, 2);
	close(fd);
	*/
	PaError portaudio_error;
	if ((portaudio_error = Pa_Initialize()) != paNoError)
		throw std::runtime_error(std::string("Pa_Initialize error: ") + Pa_GetErrorText(portaudio_error));
}

PortAudio::~PortAudio() {
	Close();

	Pa_Terminate();
}

// Replica from pa_devs.c from portaudio library example
void PortAudio::ListSupportedStandardSampleRates(std::ostream &out, const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters) const {
	static double standardSampleRates[] = {
		8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
		44100.0, 48000.0, 88200.0, 96000.0, 192000.0 };

	out << "\t";

	PaError err;
	for (int i = 0, ie = sizeof(standardSampleRates) / sizeof(standardSampleRates[0]); i < ie; ++i)
		if ((err = Pa_IsFormatSupported(inputParameters, outputParameters, standardSampleRates[i])) == paFormatIsSupported)
			out << standardSampleRates[i] << " ";

	out << std::endl;
}

void PortAudio::ListDevices(std::ostream &out) const {
	out << "PortAudio version number = " << Pa_GetVersion() << std::endl;
	out << "PortAudio version text = '" << Pa_GetVersionText() << "'" << std::endl;

	int numDevices = Pa_GetDeviceCount();
	out << "Number of devices = " << numDevices << std::endl;
	if (numDevices < 0)
		throw std::runtime_error("Pa_GetDeviceCount return negative value.");

	int console_width = 80;
#ifdef _WIN32
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi))
		console_width = csbi.srWindow.Right - csbi.srWindow.Left;
#else
	struct winsize w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	console_width = w.ws_col;
#endif
	std::vector<char> separator_line(console_width, '-');
	separator_line.push_back('\0');

	int def_in = Pa_GetDefaultInputDevice();
	int def_out = Pa_GetDefaultOutputDevice();

	for (int i = 0; i < numDevices; ++i) {
		auto deviceInfo = Pa_GetDeviceInfo(i);
		out << &separator_line[0] << std::endl;
		out << "Device #" << i;

		/* Mark global and API specific default devices */
		bool defaultDisplayed = false;
		if (i == def_in) {
			out << " [Default Input";
			defaultDisplayed = true;
		}
		else if (i == Pa_GetHostApiInfo(deviceInfo->hostApi)->defaultInputDevice) {
			auto hostInfo = Pa_GetHostApiInfo(deviceInfo->hostApi);
			out << " [Default " << hostInfo->name << " Input";
			defaultDisplayed = true;
		}

		if (i == def_out) {
			out << (defaultDisplayed ? ", " : " [") << "Default Output";
			defaultDisplayed = true;
		}
		else if (i == Pa_GetHostApiInfo(deviceInfo->hostApi)->defaultOutputDevice) {
			auto hostInfo = Pa_GetHostApiInfo(deviceInfo->hostApi);
			out << (defaultDisplayed ? ", " : " [") << "Default " << hostInfo->name << " Output";
			defaultDisplayed = true;
		}

		out << (defaultDisplayed ? "]" : "") << std::endl;

		// print device info fields
		out << "Name                        = " << deviceInfo->name << std::endl;
		out << "Host API                    = " << Pa_GetHostApiInfo(deviceInfo->hostApi)->name << std::endl;
		out << "Max inputs = " << deviceInfo->maxInputChannels << ", Max outputs = " << deviceInfo->maxOutputChannels << std::endl;

		out << "Default low input latency   = " << deviceInfo->defaultLowInputLatency << std::endl;
		out << "Default low output latency  = " << deviceInfo->defaultLowOutputLatency << std::endl;
		out << "Default high input latency  = " << deviceInfo->defaultHighInputLatency << std::endl;
		out << "Default high output latency = " << deviceInfo->defaultHighOutputLatency << std::endl;

#ifdef WIN32
#if PA_USE_ASIO
		/* ASIO specific latency information */
		if (Pa_GetHostApiInfo(deviceInfo->hostApi)->type == paASIO) {
			long minLatency, maxLatency, preferredLatency, granularity;

			err = PaAsio_GetAvailableLatencyValues(i, &minLatency, &maxLatency, &preferredLatency, &granularity);

			out << "ASIO minimum buffer size    = " << minLatency << std::endl;
			out << "ASIO maximum buffer size    = " << maxLatency << std::endl;
			out << "ASIO preferred buffer size  = " << preferredLatency << std::endl;

			if (granularity == -1)
				out << "ASIO buffer granularity     = power of 2" << std::endl;
			else
				out << "ASIO buffer granularity     = " << granularity << std::endl;
	}
#endif /* PA_USE_ASIO */
#endif /* WIN32 */

		out << "Default sample rate         = " << deviceInfo->defaultSampleRate << std::endl;

		PaStreamParameters inputParameters, outputParameters;
		/* poll for standard sample rates */
		inputParameters.device = i;
		inputParameters.channelCount = deviceInfo->maxInputChannels;
		inputParameters.sampleFormat = paInt16;
		inputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
		inputParameters.hostApiSpecificStreamInfo = nullptr;

		outputParameters.device = i;
		outputParameters.channelCount = deviceInfo->maxOutputChannels;
		outputParameters.sampleFormat = paInt16;
		outputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
		outputParameters.hostApiSpecificStreamInfo = nullptr;

		if (inputParameters.channelCount > 0) {
			out << "Supported standard sample rates for half-duplex 16 bit " << inputParameters.channelCount << " channel input =" << std::endl;
			ListSupportedStandardSampleRates(out, &inputParameters, nullptr);
		}

		if (outputParameters.channelCount > 0) {
			out << "Supported standard sample rates for half-duplex 16 bit " << outputParameters.channelCount << " channel output =" << std::endl;
			ListSupportedStandardSampleRates(out, nullptr, &outputParameters);
		}

		if (inputParameters.channelCount > 0 && outputParameters.channelCount > 0) {
			out << "Supported standard sample rates for full-duplex 16 bit " << inputParameters.channelCount << " channel input, " << outputParameters.channelCount << " channel output =" << std::endl;
			ListSupportedStandardSampleRates(out, &inputParameters, &outputParameters);
		}
	}
}

void PortAudio::Open(int out_device_, int channels_, double samplerate_, PaStreamCallback *user_callback_, void *user_data_) {
	Close();

	PaStreamParameters out_stream_info = { out_device_, channels_, paInt16, Pa_GetDeviceInfo(out_device_)->defaultHighOutputLatency, nullptr };

	PaError portaudio_error;
	if ((portaudio_error = Pa_OpenStream(&audio_stream, nullptr, &out_stream_info, samplerate_, paFramesPerBufferUnspecified,
		paNoFlag, user_callback_, user_data_)) != paNoError)
			throw std::runtime_error(std::string("Pa_OpenStream error: ") + Pa_GetErrorText(portaudio_error));

	if ((portaudio_error = Pa_StartStream(audio_stream)) != paNoError)
		throw std::runtime_error(std::string("Pa_StartStream error: ") + Pa_GetErrorText(portaudio_error));
}

void PortAudio::Close() {
	if (!audio_stream)
		return;

	PaError portaudio_error;
	if ((portaudio_error = Pa_CloseStream(audio_stream)) != paNoError)
		throw std::runtime_error(std::string("Pa_CloseStream error: ") + Pa_GetErrorText(portaudio_error));
	audio_stream = nullptr;
}

PortAudio::operator bool() const
{
	return audio_stream != nullptr;
}
