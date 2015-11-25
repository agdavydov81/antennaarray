// lTTS.h: interface for the ClTTS class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_LTTS_H__39187453_E147_46AD_8EE5_77739AF4F5E9__INCLUDED_)
#define AFX_LTTS_H__39187453_E147_46AD_8EE5_77739AF4F5E9__INCLUDED_

#include <SoundFile.h>
#include <SoundOutputMME.h>

#define lTTS_ALP_COUNT	336

typedef unsigned int uint;

class ClTTS
{
public:
	union ALAPHONE{
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

public:
	ClTTS();
	~ClTTS();

	char accent_text_symbol;

	CSoundFile		alp_base[lTTS_ALP_COUNT];
	CSoundOutputMME	dev_out;

	uint LoadBase(char *path);

	uint Speak(const char *text);

	enum{
		success,
		error_sign=	0x80000000
	};

	static const char alp_name[lTTS_ALP_COUNT][8];
};

#endif // !defined(AFX_LTTS_H__39187453_E147_46AD_8EE5_77739AF4F5E9__INCLUDED_)
