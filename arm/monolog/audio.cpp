#include "audio.h"
#include <vector>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else // linux
#include <sys/ioctl.h>
#include <unistd.h>
#endif


// Initialize PortAudio library
void portaudio_init() {
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

// Replica from pa_devs.c from portaudio library example
void portaudio_print_supported_standard_sample_rates(const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters) {
	static double standardSampleRates[] = {
		8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
		44100.0, 48000.0, 88200.0, 96000.0, 192000.0 };

	std::cout << "\t";

	PaError err;
	for (int i = 0, ie = sizeof(standardSampleRates) / sizeof(standardSampleRates[0]); i < ie; ++i)
		if ((err = Pa_IsFormatSupported(inputParameters, outputParameters, standardSampleRates[i])) == paFormatIsSupported)
			std::cout << standardSampleRates[i] << " ";

	std::cout << std::endl;
}

void portaudio_list_devices() {
	std::cout << "PortAudio version number = " << Pa_GetVersion() << std::endl;
	std::cout << "PortAudio version text = '" << Pa_GetVersionText() << "'" << std::endl;

	int numDevices = Pa_GetDeviceCount();
	std::cout << "Number of devices = " << numDevices << std::endl;
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
		std::cout << &separator_line[0] << std::endl;
		std::cout << "Device #" << i;

		/* Mark global and API specific default devices */
		bool defaultDisplayed = false;
		if (i == def_in) {
			std::cout << " [Default Input";
			defaultDisplayed = true;
		}
		else if (i == Pa_GetHostApiInfo(deviceInfo->hostApi)->defaultInputDevice) {
			auto hostInfo = Pa_GetHostApiInfo(deviceInfo->hostApi);
			std::cout << " [Default " << hostInfo->name << " Input";
			defaultDisplayed = true;
		}

		if (i == def_out) {
			std::cout << (defaultDisplayed ? ", " : " [") << "Default Output";
			defaultDisplayed = true;
		}
		else if (i == Pa_GetHostApiInfo(deviceInfo->hostApi)->defaultOutputDevice) {
			auto hostInfo = Pa_GetHostApiInfo(deviceInfo->hostApi);
			std::cout << (defaultDisplayed ? ", " : " [") << "Default " << hostInfo->name << " Output";
			defaultDisplayed = true;
		}

		std::cout << (defaultDisplayed ? "]" : "") << std::endl;

		// print device info fields
		std::cout << "Name                        = " << deviceInfo->name << std::endl;
		std::cout << "Host API                    = " << Pa_GetHostApiInfo(deviceInfo->hostApi)->name << std::endl;
		std::cout << "Max inputs = " << deviceInfo->maxInputChannels << ", Max outputs = " << deviceInfo->maxOutputChannels << std::endl;

		std::cout << "Default low input latency   = " << deviceInfo->defaultLowInputLatency << std::endl;
		std::cout << "Default low output latency  = " << deviceInfo->defaultLowOutputLatency << std::endl;
		std::cout << "Default high input latency  = " << deviceInfo->defaultHighInputLatency << std::endl;
		std::cout << "Default high output latency = " << deviceInfo->defaultHighOutputLatency << std::endl;

#ifdef WIN32
#if PA_USE_ASIO
		/* ASIO specific latency information */
		if (Pa_GetHostApiInfo(deviceInfo->hostApi)->type == paASIO) {
			long minLatency, maxLatency, preferredLatency, granularity;

			err = PaAsio_GetAvailableLatencyValues(i, &minLatency, &maxLatency, &preferredLatency, &granularity);

			std::cout << "ASIO minimum buffer size    = " << minLatency << std::endl;
			std::cout << "ASIO maximum buffer size    = " << maxLatency << std::endl;
			std::cout << "ASIO preferred buffer size  = " << preferredLatency << std::endl;

			if (granularity == -1)
				std::cout << "ASIO buffer granularity     = power of 2" << std::endl;
			else
				std::cout << "ASIO buffer granularity     = " << granularity << std::endl;
	}
#endif /* PA_USE_ASIO */
#endif /* WIN32 */

		std::cout << "Default sample rate         = " << deviceInfo->defaultSampleRate << std::endl;

		PaStreamParameters inputParameters, outputParameters;
		/* poll for standard sample rates */
		inputParameters.device = i;
		inputParameters.channelCount = deviceInfo->maxInputChannels;
		inputParameters.sampleFormat = paInt16;
		inputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
		inputParameters.hostApiSpecificStreamInfo = NULL;

		outputParameters.device = i;
		outputParameters.channelCount = deviceInfo->maxOutputChannels;
		outputParameters.sampleFormat = paInt16;
		outputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
		outputParameters.hostApiSpecificStreamInfo = NULL;

		if (inputParameters.channelCount > 0) {
			std::cout << "Supported standard sample rates for half-duplex 16 bit " << inputParameters.channelCount << " channel input =" << std::endl;
			portaudio_print_supported_standard_sample_rates(&inputParameters, NULL);
		}

		if (outputParameters.channelCount > 0) {
			std::cout << "Supported standard sample rates for half-duplex 16 bit " << outputParameters.channelCount << " channel output =" << std::endl;
			portaudio_print_supported_standard_sample_rates(NULL, &outputParameters);
		}

		if (inputParameters.channelCount > 0 && outputParameters.channelCount > 0) {
			std::cout << "Supported standard sample rates for full-duplex 16 bit " << inputParameters.channelCount << " channel input, " << outputParameters.channelCount << " channel output =" << std::endl;
			portaudio_print_supported_standard_sample_rates(&inputParameters, &outputParameters);
		}
	}
}

void portaudio_stream_callback(const int16_t *input, int16_t *output, unsigned long frameCount,
	const PaStreamCallbackTimeInfo* timeInfo, PaStreamCallbackFlags statusFlags, PORTAUDIO_USERDATA *userData) {
	boost::mutex::scoped_lock lock(userData->mut);
}
