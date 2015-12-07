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
			;

		bpo::variables_map arg_vm;
		bpo::store(bpo::parse_command_line(argc, argv, arg_desc), arg_vm);
		bpo::notify(arg_vm);

		if(arg_vm.count("help")) {
			std::cout << arg_desc << std::endl;
			return 0;
		}

		ulong rand_seed = arg_vm.count("seed") ? arg_vm["seed"].as<ulong>() : static_cast<ulong>(time(nullptr));
		std::string stat_path = arg_vm.count("statpath") ? arg_vm["statpath"].as<std::string>() : "det_res.txt";
		std::string base_path = arg_vm.count("basepath") ? arg_vm["basepath"].as<std::string>() : "db_bor1";
		
		CTextGenerator text_gen(stat_path, rand_seed);
		CAllophoneTTS tts(base_path);

		SndfileHandle writer("sls.wav", SFM_WRITE, SF_FORMAT_WAV | SF_FORMAT_PCM_16, tts.base.channels, tts.base.samplerate);

		for (int i = 0; i < 100; ++i)
		{
			std::string text = text_gen.Generate();
			std::cout << text << std::endl;

			std::deque<size_t> queue = tts.Text2Allophones(text.c_str());


			for (const auto &ind : queue) {
				const auto &signal = tts.base.datas[ind].signal;
				writer.write(&signal[0], signal.size() / tts.base.channels);
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
