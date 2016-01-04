#ifndef ALLOPHONE_TTS_H
#define ALLOPHONE_TTS_H

#include <deque>
#include <vector>
#include <boost/filesystem.hpp>
#include <cstdint>
#include <boost/property_tree/ptree.hpp>

#ifndef uint
typedef unsigned int uint;
#endif

class CAllophoneTTS
{
protected:
	void PushBackAlaphone(const char *alp, const char *ind, std::deque<size_t> &queue) const;
	int Word2Alaphones(char *word,bool last_word, std::deque<size_t> &queue) const;
	void GetAccent(char *word,int &preaccent_pos,int &accent_pos, int &word_len) const;
	bool GroupVovel(char c) const;
	bool GroupChar01(char c) const;
	bool GroupChar02(char c) const;
	bool GroupChar03(char c) const;
	bool GroupChar04(char c) const;
	bool GroupChar05(char c) const;
	bool GroupChar06(char c) const;
	bool GroupChar07(char c) const;
	bool GroupChar08(char c) const;

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
	size_t syntagm_index, phrase_index, paragraph_index;

	void *prosody_handle;
	double prosody_ratio;
public:
	size_t prosody_delay;
	static const double prosody_max_factor;

public:
	struct ALLOPHONE_BASE {
		ALLOPHONE_BASE();

		std::deque<const char *> names;

		size_t samplerate;
		size_t channels;

		struct ALLOPHONE_DATA {
			ALLOPHONE_DATA(size_t signal_size = 0) : signal(signal_size) {};
			std::vector<int16_t> signal;
			std::vector<size_t>  pitches;
		};

		std::deque<ALLOPHONE_DATA>	datas;
	} base;

	CAllophoneTTS(char accent_text_symbol_ = '\'');
	CAllophoneTTS(const char *base_path, const boost::property_tree::ptree &pt, char accent_text_symbol_ = '\'');
	CAllophoneTTS(const boost::filesystem::path &base_path, const boost::property_tree::ptree &pt, char accent_text_symbol_ = '\'');
	virtual ~CAllophoneTTS();

	void LoadBase(const char *base_path);
	void LoadBase(const boost::filesystem::path &base_path);

	void LoadConfig(const boost::property_tree::ptree &pt);

	struct PROSODY_CONTOUR {
		std::vector<double> position, factor;
	} syntagm_contour, phrase_contour, paragraph_contour;

	std::deque<size_t> Text2Allophones(const char *text) const;

	struct MARK_DATA {
		size_t	position;
		const char *name;
		MARK_DATA(size_t position_ = 0, const char *name_ = nullptr) : position(position_), name(name_) {}
	};
	std::vector<int16_t> Allophones2Sound(std::deque<size_t> &allophones, std::deque<MARK_DATA> *marks = nullptr);
};

#endif
