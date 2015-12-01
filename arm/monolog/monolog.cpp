#include <iostream>
#include "text_generator.h"
#include "allophone_tts.h"

int main(int argc, const char *argv[])
{
	try
	{
		CTextGenerator text_gen("det_res.txt");
		CAllophoneTTS tts("db_bor1");

		for (int i = 0; i < 10; ++i)
		{
			std::string text = text_gen.Generate();
			std::cout << text << std::endl;

			std::deque<size_t> queue = tts.Text2Allophones(text.c_str());
		}

		return 0;
	}
	catch(const std::exception &err)
	{
		std::cerr << "Exception: " << err.what() << std::endl;
		return -1;
	}
}
