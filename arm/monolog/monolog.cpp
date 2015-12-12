#include <iostream>
#include <fstream>
#include "text_generator.h"
#include "allophone_tts.h"
#include <sndfile.hh>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include <portaudio.h>
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

namespace bpo = boost::program_options;
namespace bfs = boost::filesystem;

void portaudio_list_sound_devices();

int main(int argc, const char *argv[]) {
	try {
		// Declare the supported options.
		bpo::options_description arg_desc("Allowed options");
		arg_desc.add_options()
			("help", "produce help message")
			("seed", bpo::value<ulong>(), "set random generator seed")
			("statpath", bpo::value<std::string>(), "set statistics file filename")
			("basepath", bpo::value<std::string>(), "set allophones base pathname")
			("textstream", bpo::value<std::string>(), "set text stream output file")
			("allophonestream", bpo::value<std::string>(), "set allophone stream output file")
			("soundstream", bpo::value<std::string>(), "set OGG/Vorbis sound stream output file")
			("sounddevice", bpo::value<int>(), "set sound output device ID")
			("listdevices", "output list of available sound devices")
			;

		bpo::variables_map arg_vm;
		bpo::store(bpo::parse_command_line(argc, argv, arg_desc), arg_vm);
		bpo::notify(arg_vm);

		if (argc == 1 || arg_vm.count("help")) {
			std::cout << arg_desc << std::endl;
			return 0;
		}

		// Initialize PortAudio library
		{
			int fd;
			// Suppress error messages output directly from library
#ifdef WIN32
			fd = open("nul", O_WRONLY);
#else
			fd = open("/dev/null", O_WRONLY);
#endif
			dup2(fd, 2);
			close(fd);
			Pa_Initialize();
		}
		if (arg_vm.count("listdevices")) {
			portaudio_list_sound_devices();
			return 0;
		}
		int sound_device = arg_vm.count("sounddevice") ? arg_vm["sounddevice"].as<int>() : Pa_GetDefaultOutputDevice();

		// Prepare base and text generator
		ulong rand_seed = arg_vm.count("seed") ? arg_vm["seed"].as<ulong>() : static_cast<ulong>(time(nullptr));
		std::string stat_path = arg_vm.count("statpath") ? arg_vm["statpath"].as<std::string>() : "det_res.txt";
		std::string base_path = arg_vm.count("basepath") ? arg_vm["basepath"].as<std::string>() : "db_bor1";

		CTextGenerator text_gen(stat_path, rand_seed);
		CAllophoneTTS tts(base_path);

		// Prepare log files
		std::ofstream text_stream;
		if (arg_vm.count("textstream"))
			text_stream.open(arg_vm["textstream"].as<std::string>());
		std::ofstream allophone_stream;
		if (arg_vm.count("allophonestream"))
			allophone_stream.open(arg_vm["allophonestream"].as<std::string>());

		SndfileHandle sound_stream;
		std::ofstream sound_stream_lab;
		if (arg_vm.count("soundstream")) {
			sound_stream = SndfileHandle(arg_vm["soundstream"].as<std::string>(), SFM_WRITE, SF_FORMAT_OGG | SF_FORMAT_VORBIS, tts.base.channels, tts.base.samplerate);
			sound_stream_lab.open(arg_vm["soundstream"].as<std::string>() + ".lab");
		}


		uint64_t frames_counter = 0;
		for (int i = 0; i < 3; ++i) {
			std::string text = text_gen.Generate();
			if (text_stream.is_open())
				text_stream << text << std::endl;

			std::deque<size_t> queue = tts.Text2Allophones(text.c_str());
			if (allophone_stream.is_open()) {
				for (const auto &ind : queue)
					allophone_stream << tts.base.names[ind] << " ";
				allophone_stream << std::endl;
			}

			for (const auto &ind : queue) {
				const auto &signal = tts.base.datas[ind].signal;

				if (sound_stream_lab.is_open()) {
					auto signal_frames = signal.size() / tts.base.channels;
					sound_stream.write(&signal[0], signal_frames);
					auto lab_begin = frames_counter * 10000000 / tts.base.samplerate;
					frames_counter += signal_frames;
					auto lab_end = frames_counter * 10000000 / tts.base.samplerate;
					sound_stream_lab << lab_begin << " " << lab_end << " " << tts.base.names[ind] << std::endl;
				}
			}
		}


		return 0;
	}
	catch (const std::exception &err) {
		std::cerr << "Exception: " << err.what() << std::endl;
		return -1;
	}

	Pa_Terminate();
}

// Replica from pa_devs.c from portaudio library example
void portaudio_print_supported_standard_sample_rates(const PaStreamParameters *inputParameters, const PaStreamParameters *outputParameters);
void portaudio_list_sound_devices() {
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
