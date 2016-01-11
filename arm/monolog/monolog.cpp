#include <iostream>
#include <stdexcept>
#include <fstream>
#include "text_generator.h"
#include "allophone_tts.h"
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include "audio.h"
#include <deque>
#include <cstdint>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/thread.hpp>
#include <boost/date_time.hpp>

#ifdef ENABLE_SNDFILE_WINDOWS_PROTOTYPES
#include <windows.h>
#endif
#include <sndfile.hh>

#ifdef _WIN32
#include <windows.h>
#else  /* _WIN32 */
#include <unistd.h>
#include <limits.h>
#endif  /* _WIN32 */


namespace bpo = boost::program_options;
namespace bfs = boost::filesystem;
namespace bpt = boost::property_tree;

class PortAudioData {
public:
	PortAudioData(size_t channels_, long data_buffer_) : channels(channels_), data_buffer(data_buffer_){}

	boost::mutex mut;
	size_t channels;
	long data_buffer;
	std::deque<int16_t> data;

	bool Insert(const std::vector<int16_t> &sound_) {
		boost::mutex::scoped_lock lock(mut);

		data.insert(data.end(), sound_.begin(), sound_.end());

		return (long)data.size() >= data_buffer;
	}

	operator bool() const {
		return (long)data.size() >= data_buffer;
	}

	static int Callback(const int16_t *input, int16_t *output, unsigned long frameCount,
		const PaStreamCallbackTimeInfo* timeInfo, PaStreamCallbackFlags statusFlags, PortAudioData *userData) {
		boost::mutex::scoped_lock lock(userData->mut);

		size_t data_sz = std::min((size_t)frameCount*userData->channels, userData->data.size());
		std::copy(userData->data.begin(), userData->data.begin() + data_sz, output);
		userData->data.erase(userData->data.begin(), userData->data.begin() + data_sz);

		std::fill(output + data_sz, output + frameCount*userData->channels, 0);

		return paContinue;
	}
};

int main(int argc, const char *argv[]) {
	const char *str_help		= "help";
	const char *str_seed		= "seed";
	const char *str_statpath	= "statpath";
	const char *str_ttsbase		= "ttsbase";
	const char *str_config		= "config";
	const char *str_outtext		= "outtext";
	const char *str_outallophone= "outallophone";
	const char *str_outsound	= "outsound";
	const char *str_outdevice	= "outdevice";
	const char *str_listdevices	= "listdevices";
	const char *str_outbuffer	= "outbuffer";
	const char *str_length		= "length";

	try {
		// Declare the supported options.
		bpo::options_description arg_desc("Allowed options");
		arg_desc.add_options()
			(str_help, "produce help message")
			(str_seed, bpo::value<ulong>(), "set random generator seed")
			(str_statpath, bpo::value<bfs::path>(), "set statistics file filename")
			(str_ttsbase, bpo::value<bfs::path>(), "set TTS base pathname")
			(str_config, bpo::value<bfs::path>(), "set configuration pathname")
			(str_outtext, bpo::value<bfs::path>(), "set text stream output file")
			(str_outallophone, bpo::value<bfs::path>(), "set allophone stream output file")
			(str_outsound, bpo::value<bfs::path>(), "set sound stream output file")
			(str_outdevice, bpo::value<int>(), "set sound output device ID (-1 to disable)")
			(str_listdevices, "list of available sound devices")
			(str_outbuffer, bpo::value<double>(), "output device buffer size in seconds (2 by default)")
			(str_length, bpo::value<double>(), "minimum sound length in seconds (-1 to infinite - default)")
			;

		bpo::variables_map arg_vm;
		bpo::store(bpo::parse_command_line(argc, argv, arg_desc), arg_vm);
		bpo::notify(arg_vm);

		if (arg_vm.count(str_help)) {
			std::cout << arg_desc << std::endl;
			return 0;
		}

		PortAudio audio;
		if (arg_vm.count(str_listdevices)) {
			audio.ListDevices();
			return 0;
		}
		int arg_outdevice = arg_vm.count(str_outdevice) ? arg_vm[str_outdevice].as<int>() : Pa_GetDefaultOutputDevice();

		/// Get shared resources base path //////////////////////////
		bfs::path share_root;

#ifdef _WIN32
		{
			std::vector<TCHAR> buff(MAX_PATH+8);

			while (true) {
				auto ret = GetModuleFileName(NULL, &buff[0], buff.size());
				if (!ret)
					throw std::runtime_error("Can't get executable path.");
				if (ret + 4 < buff.size())
					break;
				buff.resize(buff.size() + 256);
			}
			share_root = buff;
		}
#else  /* _WIN32 */
		{
			char buff[PATH_MAX];
			auto len = ::readlink("/proc/self/exe", buff, sizeof(buff) - 1);
			if (len == -1)
				throw std::runtime_error("Can't get executable path.");
			buff[len] = '\0';
			share_root = buff;
		}
#endif  /* _WIN32 */
		share_root = share_root.parent_path().parent_path() / "share" / "slspp" / "monolog";

		// Prepare base and text generator
		ulong arg_seed = arg_vm.count(str_seed) ? arg_vm[str_seed].as<ulong>() : static_cast<ulong>(time(nullptr));
		auto arg_statpath = arg_vm.count(str_statpath) ? arg_vm[str_statpath].as<bfs::path>() : (share_root / "det_res.txt");
		auto arg_ttsbase = arg_vm.count(str_ttsbase) ? arg_vm[str_ttsbase].as<bfs::path>() : (share_root / "db_bor1");
		auto arg_config = arg_vm.count(str_config) ? arg_vm[str_config].as<bfs::path>() : (share_root / "monolog.xml");
		auto arg_outbuffer = arg_vm.count(str_outbuffer) ? arg_vm[str_outbuffer].as<double>() : 2;
		auto arg_length = arg_vm.count(str_length) ? arg_vm[str_length].as<double>() : -1.0;

		bpt::ptree pt;
		{
			std::ifstream xml_stream(arg_config.
#ifdef __GNUC__
						generic_string().
#endif
						c_str());
			if (!xml_stream.is_open())
				throw std::runtime_error(std::string(__FUNCTION__) + ": Can't open configuration file.");
			read_xml(xml_stream, pt);
		}

		CTextGenerator text_gen(arg_statpath, arg_seed);
		CAllophoneTTS tts(arg_ttsbase, pt);

		// Prepare log files
		std::ofstream out_text;
		if (arg_vm.count(str_outtext))
			out_text.open(arg_vm[str_outtext].as<bfs::path>().
#ifdef __GNUC__
						generic_string().
#endif
						c_str());
		std::ofstream out_allophone;
		if (arg_vm.count(str_outallophone))
			out_allophone.open(arg_vm[str_outallophone].as<bfs::path>().
#ifdef __GNUC__
						generic_string().
#endif
						c_str());

		SndfileHandle out_sound;
		std::ofstream out_sound_lab;
		if (arg_vm.count(str_outsound)) {
			auto snd_path = arg_vm[str_outsound].as<bfs::path>();

			auto ext = snd_path.extension().generic_wstring();
			std::transform(ext.begin(), ext.end(), ext.begin(), towlower);

			int format = SF_FORMAT_PCM_16 | SF_FORMAT_WAV;
			if (!ext.compare(L".ogg"))
				format = SF_FORMAT_VORBIS | SF_FORMAT_OGG;
			else if (!ext.compare(L".fla") || !ext.compare(L".flac"))
				format = SF_FORMAT_PCM_16 | SF_FORMAT_FLAC;
			else if (!ext.compare(L".w64"))
				format = SF_FORMAT_PCM_16 | SF_FORMAT_W64;

			out_sound = SndfileHandle(snd_path.c_str(), SFM_WRITE, format, tts.base.channels, tts.base.samplerate);

			snd_path.replace_extension(".lab");
			out_sound_lab.open(snd_path.
#ifdef __GNUC__
						generic_string().
#endif
						c_str());
		}

		PortAudioData audio_data(tts.base.channels, (long)std::floor(arg_outbuffer*tts.base.samplerate+0.5));
		double outdevice2base_ratio = 1;
		if (arg_outdevice >= 0)
			outdevice2base_ratio = audio.Open(arg_outdevice, tts.base.channels, tts.base.samplerate, arg_outbuffer, (PaStreamCallback *)PortAudioData::Callback, &audio_data);
		else
			if (!arg_vm.count(str_length))
				arg_length = 100;

		if (!out_text.is_open() && !out_allophone.is_open() && !out_sound_lab.is_open() && arg_outdevice < 0)
			throw std::runtime_error("No output specified.");

		int64_t frames_counter = 0;
		std::deque<CAllophoneTTS::MARK_DATA> marks;
		while (static_cast<double>(frames_counter)/tts.base.samplerate<arg_length || arg_length<0) {
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
				auto sound = tts.Allophones2Sound(outdevice2base_ratio, queue, out_sound_lab.is_open() ? &marks : nullptr);
				auto signal_frames = sound.size() / tts.base.channels;

				if (out_sound_lab.is_open()) {
					out_sound.write(&sound[0], signal_frames);

					for (size_t i = 1; i < marks.size(); ++i)
						out_sound_lab << (frames_counter + marks[i - 1].position) * 10000000 / tts.base.samplerate << " " <<
										(frames_counter + marks[i].position) * 10000000 / tts.base.samplerate << " " <<
										marks[i - 1].name << std::endl;

					if(!marks.empty())
						out_sound_lab << (frames_counter + marks.back().position) * 10000000 / tts.base.samplerate << " " <<
										(frames_counter + signal_frames + tts.prosody_delay) * 10000000 / tts.base.samplerate << " " <<
										marks.back().name << std::endl;
				}

				frames_counter += signal_frames;

				if (audio) {
					audio_data.Insert(sound);
					while (audio_data)
#if BOOST_VERSION > 104900
						boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
#else
						boost::this_thread::sleep(boost::posix_time::milliseconds(100));
#endif
				}
			}
		}

		return 0;
	}
	catch (const std::exception &err) {
		std::cerr << "Exception: " << err.what() << std::endl;
		return -1;
	}
}
