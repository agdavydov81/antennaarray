#ifndef ALLOPHONE_TTS_H
#define ALLOPHONE_TTS_H

#include <deque>
#include <vector>

#ifndef uint
typedef unsigned int uint;
#endif

class CAllophoneTTS
{
public:
	union ALAPHONE {
		uint alp_code;
		char alp_name[8];
	};

protected:
	uint Word2Alaphones(char *word,bool last_word,ALAPHONE **queue,int *queue_size);
	void GetAccent(char *word,int *preaccent_pos,int *accent_pos);
	bool GroupWordChar(char c);
	bool GroupVovel(char c);
	bool GroupChar01(char c);
	bool GroupChar02(char c);
	bool GroupChar03(char c);
	bool GroupChar04(char c);
	bool GroupChar05(char c);
	bool GroupChar06(char c);
	bool GroupChar07(char c);
	bool GroupChar08(char c);
	void AddAlaphone(ALAPHONE **queue,int *queue_size,char *alp,char *ind);

	enum{
		post_pass,
		post_JE1,
		post_JE2,
		post_JO1,
		post_JO2,
		post_JU1,
		post_JU2,
		post_JA1,
		post_JA2
	};

	char accent_text_symbol;

	std::deque<const char *> alp_name;

	size_t samplerate;
	size_t channels;

	struct ALLOPHONE_DATA
	{
		ALLOPHONE_DATA(size_t signal_size = 0) : signal(signal_size) {};
		std::vector<int16_t> signal;
		std::vector<size_t>  pitches;
	};

	std::deque<ALLOPHONE_DATA>	alp_base;

public:
	CAllophoneTTS(char accent_text_symbol_ = '\'');
	CAllophoneTTS(const char *path, char accent_text_symbol_ = '\'');

	void LoadBase(const char *path);

	uint Speak(const char *text);

	enum{
		success,
		error_sign=	0x80000000
	};
};

#endif
