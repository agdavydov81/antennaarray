#include <iostream>
#include <stdexcept>
#include <fstream>
#include "text_generator.h"
#include "allophone_tts.h"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include "audio.h"

#ifdef ENABLE_SNDFILE_WINDOWS_PROTOTYPES
#include <windows.h>
#endif
#include <sndfile.hh>

namespace bpo = boost::program_options;
namespace bfs = boost::filesystem;

int main(int argc, const char *argv[]) {
	try {
		// Declare the supported options.
		bpo::options_description arg_desc("Allowed options");
		arg_desc.add_options()
			("help", "produce help message")
			("seed", bpo::value<ulong>(), "set random generator seed")
			("statpath", bpo::value<bfs::path>(), "set statistics file filename")
			("ttsbase", bpo::value<bfs::path>(), "set TTS base pathname")
			("ttsxml", bpo::value<bfs::path>(), "set TTS configuration pathname")
			("outtext", bpo::value<bfs::path>(), "set text stream output file")
			("outallophone", bpo::value<bfs::path>(), "set allophone stream output file")
			("outsound", bpo::value<bfs::path>(), "set sound stream output file")
			("outdevice", bpo::value<int>(), "set sound output device ID (-1 to disable)")
			("listdevices", "output list of available sound devices")
			;

		bpo::variables_map arg_vm;
		bpo::store(bpo::parse_command_line(argc, argv, arg_desc), arg_vm);
		bpo::notify(arg_vm);

		if (argc == 1 || arg_vm.count("help")) {
			std::cout << arg_desc << std::endl;
			return 0;
		}

		PaError portaudio_error;
		PaStream *portaudio_stream;
		PORTAUDIO_USERDATA portaudio_userdata;
		portaudio_init();
		if (arg_vm.count("listdevices")) {
			portaudio_list_devices();
			return 0;
		}
		int out_device = arg_vm.count("outdevice") ? arg_vm["outdevice"].as<int>() : Pa_GetDefaultOutputDevice();

		// Prepare base and text generator
		ulong rand_seed = arg_vm.count("seed") ? arg_vm["seed"].as<ulong>() : static_cast<ulong>(time(nullptr));
		auto stat_path = arg_vm.count("statpath") ? arg_vm["statpath"].as<bfs::path>() : bfs::path("det_res.txt");
		auto tts_base = arg_vm.count("ttsbase") ? arg_vm["ttsbase"].as<bfs::path>() : bfs::path("db_bor1");
		auto tts_xml = arg_vm.count("ttsxml") ? arg_vm["ttsxml"].as<bfs::path>() : bfs::path(tts_base)/".."/"tts.xml";

		CTextGenerator text_gen(stat_path, rand_seed);
		CAllophoneTTS tts(tts_base, tts_xml);

		// Prepare log files
		std::ofstream out_text;
		if (arg_vm.count("outtext"))
			out_text.open(arg_vm["outtext"].as<bfs::path>().c_str());
		std::ofstream out_allophone;
		if (arg_vm.count("outallophone"))
			out_allophone.open(arg_vm["outallophone"].as<bfs::path>().c_str());

		SndfileHandle out_sound;
		std::ofstream out_sound_lab;
		if (arg_vm.count("outsound")) {
			auto snd_path = arg_vm["outsound"].as<bfs::path>();
			
			auto ext = snd_path.extension().generic_wstring();
			std::transform(ext.begin(), ext.end(), ext.begin(), towlower);

			int format = SF_FORMAT_PCM_16 | SF_FORMAT_WAV;
			if (!ext.compare(L".ogg"))
				format = SF_FORMAT_OGG | SF_FORMAT_VORBIS;
			else if (!ext.compare(L".fla") || !ext.compare(L".flac"))
				format = SF_FORMAT_FLAC | SF_FORMAT_PCM_16;

			out_sound = SndfileHandle(snd_path.c_str(), SFM_WRITE, format, tts.base.channels, tts.base.samplerate);

			snd_path.replace_extension(".lab");
			out_sound_lab.open(snd_path.c_str());
		}

		if (out_device >= 0) {
			PaStreamParameters out_stream_info = { out_device, static_cast<int>(tts.base.channels), paInt16, Pa_GetDeviceInfo(out_device)->defaultHighOutputLatency, NULL };

			if ((portaudio_error = Pa_OpenStream(&portaudio_stream, nullptr, &out_stream_info, tts.base.samplerate, paFramesPerBufferUnspecified, paNoFlag, (PaStreamCallback *)portaudio_stream_callback, &portaudio_userdata)) != paNoError)
				throw std::runtime_error(std::string("Pa_OpenStream error: ") + Pa_GetErrorText(portaudio_error));
		}

		uint64_t frames_counter = 0;
		for (int i = 0; i < 3; ++i) {
			std::string text = text_gen.Generate();
			if (out_text.is_open())
				out_text << text << std::endl;

			std::deque<size_t> queue = tts.Text2Allophones(text.c_str());
			if (out_allophone.is_open()) {
				for (const auto &ind : queue)
					out_allophone << tts.base.names[ind] << " ";
				out_allophone << std::endl;
			}


			while (!queue.empty()) {
				auto sound = tts.Allophones2Sound(queue);

				if (out_sound_lab.is_open()) {
					auto signal_frames = sound.size() / tts.base.channels;
					out_sound.write(&sound[0], signal_frames);
					auto lab_begin = frames_counter * 10000000 / tts.base.samplerate;
					frames_counter += signal_frames;
					auto lab_end = frames_counter * 10000000 / tts.base.samplerate;
					out_sound_lab << lab_begin << " " << lab_end << " syntagm" << std::endl;
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
