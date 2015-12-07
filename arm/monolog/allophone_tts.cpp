// lTTS.cpp: implementation of the CAllophoneTTS class.
//
//////////////////////////////////////////////////////////////////////

#include "allophone_tts.h"
#include <sstream>
#include <boost/algorithm/string.hpp>
#include <wav_markers_regions.h>

#if defined(_WIN32) && (defined(UNICODE) || defined(_UNICODE))
typedef wchar_t		_tchar;
#else
typedef char		_tchar;
#endif
typedef std::basic_string<_tchar>	_tstring;

#include <sndfile.hh>

namespace bfs = boost::filesystem;

CAllophoneTTS::ALLOPHONE_BASE::ALLOPHONE_BASE() : samplerate(0), channels(0) {
}

CAllophoneTTS::CAllophoneTTS(char accent_text_symbol_) : accent_text_symbol(accent_text_symbol_) {
}

CAllophoneTTS::CAllophoneTTS(const char *path_, char accent_text_symbol_) : CAllophoneTTS(accent_text_symbol_) {
	LoadBase(path_);
}

CAllophoneTTS::CAllophoneTTS(const boost::filesystem::path &path_, char accent_text_symbol_) : CAllophoneTTS(accent_text_symbol_) {
	LoadBase(path_);
}

void CAllophoneTTS::LoadBase(const char *path) {
	LoadBase(boost::filesystem::path(path));
}

void CAllophoneTTS::LoadBase(const boost::filesystem::path &bpath) {
	static const char *alp_name_init[] = {
		"a000",		"a001",		"a002",		"a003",		"a010",		"a011",
		"a012",		"a013",		"a020",		"a021",		"a022",		"a023",
		"a030",		"a031",		"a032",		"a033",		"a040",		"a041",
		"a042",		"a043",		"a101",		"a102",		"a103",		"a111",
		"a112",		"a113",		"a121",		"a122",		"a123",		"a131",
		"a132",		"a133",		"a141",		"a142",		"a143",		"a201",
		"a202",		"a203",		"a210",		"a211",		"a212",		"a213",
		"a220",		"a221",		"a222",		"a223",		"a230",		"a231",
		"a232",		"a233",		"a240",		"a241",		"a242",		"a243",
		"b'204",	"b'205",	"b204",		"b205",		"c000",		"c001",
		"ch'000",	"ch'001",	"d'204",	"d'205",	"d204",		"d205",
		"e000",		"e001",		"e002",		"e003",		"e010",		"e011",
		"e012",		"e013",		"e020",		"e021",		"e022",		"e023",
		"e030",		"e031",		"e032",		"e033",		"e040",		"e041",
		"e042",		"e043",		"e101",		"e102",		"e103",		"e111",
		"e112",		"e113",		"e121",		"e122",		"e123",		"e131",
		"e132",		"e133",		"e141",		"e142",		"e143",		"e201",
		"e202",		"e203",		"e210",		"e211",		"e212",		"e213",
		"e221",		"e222",		"e223",		"e231",		"e232",		"e233",
		"e240",		"e241",		"e242",		"e243",		"f'000",	"f'001",
		"f000",		"f001",		"g'205",	"g102",		"g103",		"i040",
		"i041",		"i042",		"i043",		"i050",		"i051",		"i052",
		"i053",		"i141",		"i142",		"i143",		"i151",		"i152",
		"i153",		"i240",		"i241",		"i242",		"i243",		"i250",
		"i251",		"i252",		"i253",		"j'316",	"j'317",	"j'320",
		"j'326",	"j'327",	"j'328",	"k'001",	"k100",		"k102",
		"k103",		"l'200",	"l'204",	"l'205",	"l200",		"l204",
		"l205",		"m'200",	"m'204",	"m'205",	"m200",		"m204",
		"m205",		"n'200",	"n'204",	"n'205",	"n200",		"n204",
		"n205",		"o000",		"o001",		"o002",		"o003",		"o010",
		"o011",		"o012",		"o013",		"o020",		"o021",		"o022",
		"o023",		"o030",		"o031",		"o032",		"o033",		"o040",
		"o041",		"o042",		"o043",		"o100",		"o101",		"o102",
		"o103",		"o110",		"o111",		"o112",		"o113",		"o120",
		"o121",		"o122",		"o123",		"o130",		"o131",		"o132",
		"o133",		"o140",		"o141",		"o142",		"o143",		"p'000",
		"p'001",	"p000",		"p001",		"r'400",	"r'409",	"r'40r",
		"r400",		"r409",		"r40r",		"s'000",	"s'001",	"s000",
		"s001",		"sh'000",	"sh'001",	"sh000",	"sh001",	"t'000",
		"t'001",	"t000",		"t001",		"u000",		"u001",		"u002",
		"u003",		"u010",		"u011",		"u012",		"u013",		"u020",
		"u021",		"u022",		"u023",		"u030",		"u031",		"u032",
		"u033",		"u040",		"u041",		"u042",		"u043",		"u101",
		"u102",		"u103",		"u111",		"u112",		"u113",		"u121",
		"u122",		"u123",		"u131",		"u132",		"u133",		"u141",
		"u142",		"u143",		"u201",		"u202",		"u203",		"u210",
		"u211",		"u212",		"u213",		"u220",		"u221",		"u222",
		"u223",		"u230",		"u231",		"u232",		"u233",		"u240",
		"u241",		"u242",		"u243",		"v'316",	"v'317",	"v'318",
		"v'326",	"v'327",	"v'328",	"v316",		"v317",		"v318",
		"v326",		"v327",		"v328",		"x'001",	"x100",		"x102",
		"x103",		"y000",		"y010",		"y011",		"y012",		"y013",
		"y020",		"y021",		"y022",		"y023",		"y111",		"y112",
		"y113",		"y121",		"y122",		"y123",		"y210",		"y211",
		"y212",		"y213",		"y220",		"y221",		"y222",		"y223",
		"z'204",	"z'205",	"z204",		"z205",		"zh204",	"zh205"
	};

	base.samplerate = 0;
	base.channels = 0;
	base.names.clear();
	base.datas.clear();

	bfs::path current_path;

	try
	{
		base.names.assign(alp_name_init, alp_name_init + sizeof(alp_name_init) / sizeof(alp_name_init[0]));
		std::sort(base.names.begin(), base.names.end(), [](const char *a_, const char *b_) { return strcmp(a_, b_) < 0; });

		for (const auto &current_name : base.names) {
			current_path = bpath / bfs::path(std::string(current_name) + ".wav");
			auto current_cpath = current_path.c_str();

			SndfileHandle file(current_cpath);
			if (!file.frames() || !file.samplerate() || !file.channels())
				throw std::runtime_error("Empty file.");
			if (file.channels() != 1)
				throw std::runtime_error("Can't process multichannel data.");

			if (!base.samplerate)
				base.samplerate = file.samplerate();
			if (!base.channels)
				base.channels = file.channels();

			if (file.samplerate() != base.samplerate) {
				std::stringstream sstr;
				sstr << "Incompatible sample rate " << file.samplerate() << "!=" << base.samplerate << ".";
				throw std::runtime_error(sstr.str());
			}
			if (file.channels() != base.channels) {
				std::stringstream sstr;
				sstr << "Incompatible channels number " << file.channels() << "!=" << base.channels << ".";
				throw std::runtime_error(sstr.str());
			}

			ALLOPHONE_BASE::ALLOPHONE_DATA data(static_cast<size_t>(file.frames() * file.channels()));
			if (file.read(&data.signal[0], file.frames()) != file.frames())
				throw std::runtime_error("Can't read all file.");

			std::vector<WAV_MARKER> markers;
			std::vector<WAV_REGION> regions;
			wav_markers_regions_read(current_cpath, markers, regions);

			data.pitches.resize(markers.size());
			std::transform(markers.cbegin(), markers.cend(), data.pitches.begin(), [](auto m) { return m.pos; });
			for (const auto &r : regions)
				if (!r.length)
					data.pitches.push_back(r.pos);

			std::sort(data.pitches.begin(), data.pitches.end());
			for (size_t i = 1; i < data.pitches.size(); ++i)
				if (data.pitches[i - 1] == data.pitches[i])
					data.pitches.erase(data.pitches.begin() + i--);

			base.datas.push_back(std::move(data));
		}
	}
	catch (const std::exception &error)
	{
		base.samplerate = 0;
		base.channels = 0;
		base.names.clear();
		base.datas.clear();

		std::stringstream sstr;
		sstr << __FUNCTION__ << ": Error in file " << current_path << ": " << error.what();
		throw std::runtime_error(sstr.str());
	}
}

void CAllophoneTTS::PushBackAlaphone(const char *alp, const char *ind, std::deque<size_t> &queue) const {
	char alp_name[32];
	strcpy(alp_name, alp);
	strcat(alp_name, ind);

	size_t pos = (size_t)(std::lower_bound(base.names.cbegin(), base.names.cend(), alp_name, [](auto a, auto b) { return strcmp(a, b) < 0; }) - base.names.cbegin());
	assert(pos >= 0 && pos < base.datas.size());
	queue.push_back(pos);
}

int CAllophoneTTS::Word2Alaphones(char *word, bool last_word, std::deque<size_t> &queue) const {
	char alp[8], ind[8] = "xxx";
	char prev_symb = 0;

	int preaccent_pos, accent_pos;
	GetAccent(word, preaccent_pos, accent_pos);

	int word_len = 0;
	while (GroupWordChar(word[word_len]))
		word_len++;

	int post_switch = post_pass;

	for (int i = 0; i < word_len; i++) {
		switch (word[i]) {
		case 'à':	//////////////////////////////////////////////////////////////////////////
			Place_A:
				alp[0] = 'a';
				alp[1] = 0;
				if (i == accent_pos)
					ind[0] = '0';
				else
					if (i == preaccent_pos)
						ind[0] = '1';
					else
						ind[0] = '2';
				if (!i)
					ind[1] = '0';
				else
					if (GroupChar01(prev_symb))
						ind[1] = '1';
					else
						if (GroupChar02(prev_symb))
							ind[1] = '2';
						else
							if ((prev_symb == 'ê') || (prev_symb == 'ã') || (prev_symb == 'õ'))
								ind[1] = '3';
							else
								ind[1] = '4';
				if (last_word && (i == word_len - 1))
					ind[2] = '0';
				else
					if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
						if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
							ind[2] = '2';
						else
							ind[2] = '1';
					else
						if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
							ind[2] = '1';
						else
							if (GroupChar02(word[i + 1]))
								ind[2] = '2';
							else
								ind[2] = '3';


				PushBackAlaphone(alp, ind, queue);
				break;
		case 'á':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_P;
		Place_B:
			alp[0] = 'b';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (GroupChar06(word[i + 1]))
				ind[2] = '4';
			else
				ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'â':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_F;
		Place_V:
			alp[0] = 'v';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '3';
			if (GroupChar07(prev_symb))
				ind[1] = '1';
			else
				ind[1] = '2';
			if (GroupChar07(word[i + 1]))
				if (i + 1 == accent_pos)
					ind[2] = '6';
				else
					ind[2] = '7';
			else
				ind[2] = '8';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ã':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_K;
			if (word[i + 1] == 'ê')
				goto Place_X;
		Place_G:
			alp[0] = 'g';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
				ind[0] = '2';
				ind[1] = '0';
				ind[2] = '5';
			}
			else {
				ind[0] = '1';
				ind[1] = '0';
				if ((word[i + 1] == 'î') || (word[i + 1] == 'ó'))
					ind[2] = '2';
				else
					ind[2] = '3';
			}
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ä':	//////////////////////////////////////////////////////////////////////////
			if ((prev_symb == 'ç') && (word[i + 1] == 'í'))
				break;
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_T;
		Place_D:
			alp[0] = 'd';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (GroupChar06(word[i + 1]))
				ind[2] = '4';
			else
				ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'å':	//////////////////////////////////////////////////////////////////////////
			if ((word[i + 1] == 'ã') && (word[i + 2] == 'î') && (word[i + 3] == 0))
				word[i + 1] = 'â';
			if (!GroupChar03(prev_symb))
				goto Place_E;

			post_switch = post_JE1;
			goto Place_J;
		Place_JE1:
			post_switch = post_JE2;
			goto Place_E;
		Place_JE2:
			post_switch = 0;
			break;
		case '¸':	//////////////////////////////////////////////////////////////////////////
			if (!GroupChar03(prev_symb))
				goto Place_O;

			post_switch = post_JO1;
			goto Place_J;
		Place_JO1:
			post_switch = post_JO2;
			goto Place_O;
		Place_JO2:
			post_switch = 0;
			break;
		case 'æ':	//////////////////////////////////////////////////////////////////////////
			if (word[i + 1] == '÷') {
				alp[0] = 's';
				alp[1] = 'h';
				alp[2] = '\'';
				alp[3] = 0;
				ind[0] = '0';
				ind[1] = '0';
				if ((last_word) && (i == word_len - 1))
					ind[2] = '0';
				else
					ind[2] = '1';
				PushBackAlaphone(alp, ind, queue);
				break;
			}
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_SH;
		Place_ZH:
			alp[0] = 'z';
			alp[1] = 'h';
			alp[2] = 0;
			ind[0] = '2';
			ind[1] = '0';
			if (GroupChar06(word[i + 1]))
				ind[2] = '4';
			else
				ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ç':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar05(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar05(word[i + 2])))
				goto Place_S;
		Place_Z:
			alp[0] = 'z';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (GroupChar06(word[i + 1]))
				ind[2] = '4';
			else
				ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'è':	//////////////////////////////////////////////////////////////////////////
			if ((prev_symb == 'ö') || (prev_symb == 'ø') || (prev_symb == 'æ'))
				goto Place_Y;
			alp[0] = 'i';
			alp[1] = 0;
			if (i == accent_pos)
				ind[0] = '0';
			else
				if (i == preaccent_pos)
					ind[0] = '1';
				else
					ind[0] = '2';
			if (prev_symb == 'ü')
				ind[1] = '4';
			else
				ind[1] = '5';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
					if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
						ind[2] = '2';
					else
						ind[2] = '1';
				else
					if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
						ind[2] = '1';
					else
						if (GroupChar02(word[i + 1]))
							ind[2] = '2';
						else
							ind[2] = '3';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'é':	//////////////////////////////////////////////////////////////////////////
			Place_J:
				alp[0] = 'j';
				alp[1] = '\'';
				alp[2] = 0;
				ind[0] = '3';
				if (GroupChar07(prev_symb))
					ind[1] = '1';
				else
					ind[1] = '2';
				if (GroupChar07(word[i + 1]))
					if (i + 1 == accent_pos)
						ind[2] = '6';
					else
						ind[2] = '7';
				else
					ind[2] = '8';
				if ((ind[0] == '3') && (ind[1] == '1') && (ind[2] == '8'))
					ind[2] = '7';
				if ((ind[0] == '3') && (ind[1] == '2') && (last_word && (i == word_len - 1)))
					ind[2] = '0';
				PushBackAlaphone(alp, ind, queue);
				break;
		case 'ê':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 1])))
				goto Place_G;
		Place_K:
			alp[0] = 'k';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
				ind[0] = '0';
				ind[1] = '0';
				ind[2] = '1';
			}
			else {
				ind[0] = '1';
				ind[1] = '0';
				if (last_word && (i == word_len - 1))
					ind[2] = '0';
				else
					if ((word[i + 1] == 'î') || (word[i + 1] == 'ó'))
						ind[2] = '2';
					else
						ind[2] = '3';
				if (last_word && (i == word_len - 1))
					ind[2] = '0';
			}
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ë':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'l';
			alp[1] = 0;
			if (GroupChar04(word[i + 1]) || ((word[i] == word[i + 1]) && GroupChar04(word[i + 2]))) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				if (GroupChar06(word[i + 1]))
					ind[2] = '4';
				else
					ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ì':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'm';
			alp[1] = 0;
			if (GroupChar04(word[i + 1]) || ((word[i] == word[i + 1]) && GroupChar04(word[i + 2]))) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				if (GroupChar06(word[i + 1]))
					ind[2] = '4';
				else
					ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'í':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'n';
			alp[1] = 0;
			if (GroupChar04(word[i + 1]) || ((word[i] == word[i + 1]) && GroupChar04(word[i + 2]))) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '2';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				if (GroupChar06(word[i + 1] == 'á'))
					ind[2] = '4';
				else
					ind[2] = '5';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'î':	//////////////////////////////////////////////////////////////////////////
			if (i != accent_pos)
				goto Place_A;
			if ((word[i + 1] == 'ã') && (word[i + 2] == 'î') && (word[i + 3] == 0))
				word[i + 1] = 'â';
		Place_O:
			alp[0] = 'o';
			alp[1] = 0;
			if (i == accent_pos)
				ind[0] = '0';
			else
				ind[0] = '1';
			if (!i)
				ind[1] = '0';
			else
				if (GroupChar01(prev_symb))
					ind[1] = '1';
				else
					if (GroupChar02(prev_symb))
						ind[1] = '2';
					else
						if ((prev_symb == 'ê') || (prev_symb == 'ã') || (prev_symb == 'õ'))
							ind[1] = '3';
						else
							ind[1] = '4';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
					if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
						ind[2] = '2';
					else
						ind[2] = '1';
				else
					if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
						ind[2] = '1';
					else
						if (GroupChar02(word[i + 1]))
							ind[2] = '2';
						else
							ind[2] = '3';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ï':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 1])))
				goto Place_B;
		Place_P:
			alp[0] = 'p';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ð':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'r';
			alp[1] = 0;
			if (GroupChar04(word[i + 1]) || ((word[i] == word[i + 1]) && GroupChar04(word[i + 2]))) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '4';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';

			if ((word[i + 1] == 'ï') || (word[i + 1] == 'ò') || (word[i + 1] == 'ê') || (word[i + 1] == 'ö') || (word[i + 1] == '÷') ||
				(word[i + 1] == 'ô') || (word[i + 1] == 'ñ') || (word[i + 1] == 'ø') || (word[i + 1] == 'õ'))
				ind[2] = '9';
			else
				ind[2] = 'r';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ñ':	//////////////////////////////////////////////////////////////////////////
			if (word[i + 1] == '÷') {
				alp[0] = 's';
				alp[1] = 'h';
				alp[2] = 0;
				ind[0] = '0';
				ind[1] = '0';
				if (last_word && (i == word_len - 1))
					ind[2] = '0';
				else
					ind[2] = '1';
				PushBackAlaphone(alp, ind, queue);
				break;
			}
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 2])))
				goto Place_Z;
		Place_S:
			alp[0] = 's';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ò':	//////////////////////////////////////////////////////////////////////////
			if ((prev_symb == 'ñ') && (word[i + 1] == 'í'))
				break;
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 2])))
				goto Place_D;
		Place_T:
			alp[0] = 't';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ó':	//////////////////////////////////////////////////////////////////////////
			Place_U:
				alp[0] = 'u';
				alp[1] = 0;
				if (i == accent_pos)
					ind[0] = '0';
				else
					if (i == preaccent_pos)
						ind[0] = '1';
					else
						ind[0] = '2';
				if (!i)
					ind[1] = '0';
				else
					if (GroupChar01(prev_symb))
						ind[1] = '1';
					else
						if (GroupChar02(prev_symb))
							ind[1] = '2';
						else
							if ((prev_symb == 'ê') || (prev_symb == 'ã') || (prev_symb == 'õ'))
								ind[1] = '3';
							else
								ind[1] = '4';
				if (last_word && (i == word_len - 1))
					ind[2] = '0';
				else
					if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
						if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
							ind[2] = '2';
						else
							ind[2] = '1';
					else
						if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
							ind[2] = '1';
						else
							if (GroupChar02(word[i + 1]))
								ind[2] = '2';
							else
								ind[2] = '3';
				PushBackAlaphone(alp, ind, queue);
				break;
		case 'ô':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 2])))
				goto Place_V;
		Place_F:
			alp[0] = 'f';
			alp[1] = 0;
			if (GroupChar04(word[i + 1])) {
				alp[1] = '\'';
				alp[2] = 0;
			}
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'õ':	//////////////////////////////////////////////////////////////////////////
			Place_X:
				alp[0] = 'x';
				alp[1] = 0;
				if (GroupChar04(word[i + 1])) {
					alp[1] = '\'';
					alp[2] = 0;
					ind[0] = '0';
					ind[1] = '0';
					ind[2] = '1';
				}
				else {
					ind[0] = '1';
					ind[1] = '0';
					if ((word[i + 1] == 'î') || (word[i + 1] == 'ó'))
						ind[2] = '2';
					else
						ind[2] = '3';
					if (last_word && (i == word_len - 1))
						ind[2] = '0';
				}
				PushBackAlaphone(alp, ind, queue);
				break;
		case 'ö':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'c';
			alp[1] = 0;
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case '÷':	//////////////////////////////////////////////////////////////////////////
			alp[0] = 'c';
			alp[1] = 'h';
			alp[2] = '\'';
			alp[3] = 0;
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ø':	//////////////////////////////////////////////////////////////////////////
			if (GroupChar08(word[i + 1]) || ((word[i + 1] == 'ü') && GroupChar08(word[i + 2])))
				goto Place_ZH;
		Place_SH:
			alp[0] = 's';
			alp[1] = 'h';
			alp[2] = 0;
			if (word[i + 1] == 'ü') {
				alp[2] = '\'';
				alp[3] = 0;
			}
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ù':
			alp[0] = 's';
			alp[1] = 'h';
			alp[2] = '\'';
			alp[3] = 0;
			ind[0] = '0';
			ind[1] = '0';
			if (last_word && (i == word_len - 1))
				ind[2] = '0';
			else
				ind[2] = '1';
			PushBackAlaphone(alp, ind, queue);
			break;
		case 'ú':
			break;
		case 'û':	//////////////////////////////////////////////////////////////////////////
			Place_Y:
				alp[0] = 'y';
				alp[1] = 0;
				if (i == accent_pos)
					ind[0] = '0';
				else
					if (i == preaccent_pos)
						ind[0] = '1';
					else
						ind[0] = '2';
				if (!i)
					ind[1] = '0';
				else
					if (GroupChar01(prev_symb))
						ind[1] = '1';
					else
						ind[1] = '2';
				if (last_word && (i == word_len - 1) || (ind[1] == '0'))
					ind[2] = '0';
				else
					if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
						if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
							ind[2] = '2';
						else
							ind[2] = '1';
					else
						if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
							ind[2] = '1';
						else
							if (GroupChar02(word[i + 1]))
								ind[2] = '2';
							else
								ind[2] = '3';
				PushBackAlaphone(alp, ind, queue);
				break;
		case 'ü':	//////////////////////////////////////////////////////////////////////////
			break;
		case 'ý':	//////////////////////////////////////////////////////////////////////////
			Place_E:
				alp[0] = 'e';
				alp[1] = 0;
				if (i == accent_pos)
					ind[0] = '0';
				else
					if (i == preaccent_pos)
						ind[0] = '1';
					else
						ind[0] = '2';
				if (!i)
					ind[1] = '0';
				else
					if (GroupChar01(prev_symb))
						ind[1] = '1';
					else
						if (GroupChar02(prev_symb))
							ind[1] = '2';
						else
							if ((prev_symb == 'ê') || (prev_symb == 'ã') || (prev_symb == 'õ'))
								ind[1] = '3';
							else
								ind[1] = '4';
				if (last_word && (i == word_len - 1))
					if (ind[0] == '2')
						if ((ind[1] == '0') || (ind[1] == '1') || (ind[1] == '4'))
							ind[2] = '0';
						else
							if (ind[1] == '2')
								ind[2] = '1';
							else
								ind[2] = '1';
					else
						ind[2] = '0';
				else
					if ((word[i + 1] == 'ê') || (word[i + 1] == 'ã') || (word[i + 1] == 'õ'))
						if ((word[i + 2] == 'ó') || (word[i + 2] == 'î'))
							ind[2] = '2';
						else
							ind[2] = '1';
					else
						if (GroupChar01(word[i + 1]) || (word[i + 1] == 'å'))
							ind[2] = '1';
						else
							if (GroupChar02(word[i + 1]))
								ind[2] = '2';
							else
								ind[2] = '3';
				PushBackAlaphone(alp, ind, queue);
				break;
		case 'þ':	//////////////////////////////////////////////////////////////////////////
			if (!GroupChar03(prev_symb))
				goto Place_U;

			post_switch = post_JU1;
			goto Place_J;
		Place_JU1:
			post_switch = post_JU2;
			goto Place_U;
		Place_JU2:
			post_switch = 0;
			break;
		case 'ÿ':	//////////////////////////////////////////////////////////////////////////
			if (!GroupChar03(prev_symb))
				goto Place_A;

			post_switch = post_JA1;
			goto Place_J;
		Place_JA1:
			post_switch = post_JA2;
			goto Place_A;
		Place_JA2:
			post_switch = 0;
			break;
		}

		switch (post_switch) {
		case post_pass:
			break;
		case post_JE1:
			goto Place_JE1;
		case post_JE2:
			goto Place_JE2;
		case post_JO1:
			goto Place_JO1;
		case post_JO2:
			goto Place_JO2;
		case post_JU1:
			goto Place_JU1;
		case post_JU2:
			goto Place_JU2;
		case post_JA1:
			goto Place_JA1;
		case post_JA2:
			goto Place_JA2;
		}

		prev_symb = word[i];
	}

	return word_len;
}

void CAllophoneTTS::GetAccent(char *word, int &preaccent_pos, int &accent_pos) const {
	int word_len = 0;
	while (GroupWordChar(word[word_len]))
		word_len++;

	int i = 0;
	while (i < word_len&&word[i] != accent_text_symbol)
		i++;
	if (word[i] == accent_text_symbol) {
		accent_pos = i - 1;
		memmove(word + i, word + i + 1, word_len - i - 1);
		word[word_len - 1] = ' ';
	}
	else {
		int vovel_cnt = 0;
		for (i = 0; i < word_len; i++)
			if (GroupVovel(word[i]))
				vovel_cnt++;

		accent_pos = vovel_cnt >> 1;
		vovel_cnt = 0;
		for (i = 0; i < word_len; i++)
			if (GroupVovel(word[i])) {
				vovel_cnt++;
				if (vovel_cnt >= accent_pos) {
					accent_pos = i;
					break;
				}
			}
	}

	preaccent_pos = accent_pos - 1;
	while ((preaccent_pos > 0) && !GroupVovel(word[preaccent_pos]))
		preaccent_pos--;
}

bool CAllophoneTTS::GroupWordChar(char c) const {
	if (((c >= 'à') && (c <= 'ÿ')) || (c == '¸') || (c == accent_text_symbol))
		return true;
	return false;
}

bool CAllophoneTTS::GroupVovel(char c) const {
	if ((c == 'à') || (c == 'å') || (c == '¸') || (c == 'è') || (c == 'î') || (c == 'ó') || (c == 'û') || (c == 'ý') || (c == 'þ') || (c == 'ÿ'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar01(char c) const {
	if ((c == 'ò') || (c == 'ä') || (c == 'ñ') || (c == 'ç') || (c == 'ö') || (c == 'ø') || (c == 'æ') || (c == 'í') || (c == 'ð') || (c == 'à'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar02(char c) const {
	if ((c == 'ï') || (c == 'á') || (c == 'ô') || (c == 'â') || (c == 'ë') || (c == 'ì') || (c == 'ó') || (c == 'î'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar03(char c) const {
	if ((c == 0) || (c == 'ü') || (c == 'ú') || (c == 'à') || (c == 'î') || (c == 'ó') || (c == 'ý') || (c == 'û') || (c == 'å') || (c == '¸') || (c == 'þ') || (c == 'ÿ'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar04(char c) const {
	if ((c == 'ü') || (c == 'å') || (c == '¸') || (c == 'þ') || (c == 'ÿ') || (c == 'è'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar05(char c) const {
	if ((c == 0) || (c == 'ï') || (c == 'ò') || (c == 'ê') || (c == 'ô') || (c == 'ö') || (c == 'ù') || (c == '÷') || (c == 'õ') || (c == 'ù'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar06(char c) const {
	if ((c == 'á') || (c == 'ä') || (c == 'ã') || (c == 'ç') || (c == 'æ') || (c == 'ë') || (c == 'ì') || (c == 'í') || (c == 'â') || (c == 'é') || (c == 'ð'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar07(char c) const {
	if ((c == 'à') || (c == 'å') || (c == 'î') || (c == 'ó') || (c == 'û') || (c == 'è'))
		return true;
	return false;
}

bool CAllophoneTTS::GroupChar08(char c) const {
	if ((c == 'á') || (c == 'ä') || (c == 'ã') || (c == 'ç') || (c == 'æ'))
		return true;
	return false;
}

std::deque<size_t> CAllophoneTTS::Text2Allophones(const char *text) const {
	std::vector<char> phrase(text, text + strlen(text) + 1);
	boost::algorithm::to_lower(phrase);

	std::deque<size_t> queue;

	int phrase_pos = 0;
	while (phrase[phrase_pos]) {
		while (!GroupWordChar(phrase[phrase_pos])) {
			switch (phrase[phrase_pos]) {
			case 0:
				goto phrase_finish;
			case '.':
			case '!':
			case '?':
				break;
			case ',':
			case ':':
			case '-':
				break;
			default:
				break;
			}
			phrase_pos++;
		}

		phrase_pos += Word2Alaphones(&phrase[phrase_pos], false, queue);
	}
phrase_finish:

	return queue;
}
