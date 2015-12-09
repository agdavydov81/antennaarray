#include <iostream>
#include "text_generator.h"
#include "allophone_tts.h"
#include <sndfile.hh>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>

namespace bpo = boost::program_options;
namespace bfs = boost::filesystem;

int main(int argc, const char *argv[])
{
	try
	{
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
			;

		bpo::variables_map arg_vm;
		bpo::store(bpo::parse_command_line(argc, argv, arg_desc), arg_vm);
		bpo::notify(arg_vm);

		if (argc == 1 || arg_vm.count("help")) {
			std::cout << arg_desc << std::endl;
			return 0;
		}

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
		if (arg_vm.count("soundstream"))
		{
			sound_stream = SndfileHandle(arg_vm["soundstream"].as<std::string>(), SFM_WRITE, SF_FORMAT_OGG | SF_FORMAT_VORBIS, tts.base.channels, tts.base.samplerate);
			sound_stream_lab.open(arg_vm["soundstream"].as<std::string>() + ".lab");
		}


		uint64_t frames_counter = 0;
		for (int i = 0; i < 3; ++i)
		{
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
	catch (const std::exception &err)
	{
		std::cerr << "Exception: " << err.what() << std::endl;
		return -1;
	}
}
