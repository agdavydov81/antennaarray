#include <iostream>
#include "text_generator.h"
#include "allophone_tts.h"
#include <sndfile.hh>

int main(int argc, const char *argv[])
{
	try
	{
		CTextGenerator text_gen("det_res.txt",123);
		CAllophoneTTS tts("db_bor1");

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
