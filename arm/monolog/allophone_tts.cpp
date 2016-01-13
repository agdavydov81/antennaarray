// lTTS.cpp: implementation of the CAllophoneTTS class.
//
//////////////////////////////////////////////////////////////////////

#include "allophone_tts.h"
#include <sstream>
#include <array>
#include <stdexcept>
#include <boost/algorithm/string.hpp>
#include <wav_markers_regions.h>
#include "../auxiliary/libresample/include/libresample.h"

#if defined(_WIN32) && (defined(UNICODE) || defined(_UNICODE))
typedef wchar_t		_tchar;
#else
typedef char		_tchar;
#endif
typedef std::basic_string<_tchar>	_tstring;

#ifdef ENABLE_SNDFILE_WINDOWS_PROTOTYPES
#include <windows.h>
#endif
#include <sndfile.hh>

const double CAllophoneTTS::prosody_max_factor = 16.0;

CAllophoneTTS::ALLOPHONE_BASE::ALLOPHONE_BASE() : samplerate(0), channels(0) {
}

CAllophoneTTS::CAllophoneTTS(char accent_text_symbol_) : accent_text_symbol(accent_text_symbol_) {
	prosody_handle = resample_open(0, 1 / (prosody_max_factor*1.01), prosody_max_factor*1.01);
	if (!prosody_handle)
		throw std::runtime_error(std::string(__FUNCTION__) + ": Can't create prosody resample object.");
	prosody_ratio = 1;
	prosody_delay = 0;
}

CAllophoneTTS::~CAllophoneTTS() {
	if (prosody_handle)
		resample_close(prosody_handle);
}

CAllophoneTTS::CAllophoneTTS(const char *base_path_, const boost::property_tree::ptree &pt_, char accent_text_symbol_) : CAllophoneTTS(accent_text_symbol_) {
	LoadBase(base_path_);
	LoadConfig(pt_);
}

CAllophoneTTS::CAllophoneTTS(const boost::filesystem::path &base_path_, const boost::property_tree::ptree &pt_, char accent_text_symbol_) : CAllophoneTTS(accent_text_symbol_) {
	LoadBase(base_path_);
	LoadConfig(pt_);
}

void CAllophoneTTS::LoadBase(const char *base_path) {
	if (base_path)
		LoadBase(boost::filesystem::path(base_path));
}

size_t FindString(const std::deque<const char *> names, const char *name) {
	size_t ret = std::lower_bound(names.begin(), names.end(), name, [](const char *str1, const char *str2) { return strcmp(str1, str2) < 0; }) - names.begin();
	if (strcmp(names[ret], name))
		throw std::runtime_error(std::string(__FUNCTION__) + ": Can't find name \"" + name + "\" in base.");
	return ret;
}

void CAllophoneTTS::LoadBase(const boost::filesystem::path &bpath) {
	if (bpath.empty())
		return;

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
		"z'204",	"z'205",	"z204",		"z205",		"zh204",	"zh205",
		"#pause1",	"#pause2",	"#pause3"
	};

	base.samplerate = 0;
	base.channels = 0;
	base.names.clear();
	base.datas.clear();

	std::string current_path;

	try
	{
		base.names.assign(alp_name_init, alp_name_init + sizeof(alp_name_init) / sizeof(alp_name_init[0]));
		std::sort(base.names.begin(), base.names.end(), [](const char *a_, const char *b_) { return strcmp(a_, b_) < 0; });

		syntagm_index = FindString(base.names, "#pause1");
		phrase_index = FindString(base.names, "#pause2");
		paragraph_index = FindString(base.names, "#pause3");

		for (const auto &current_name : base.names) {
			current_path = (bpath / boost::filesystem::path(current_name).append(".wav")).string();

			SndfileHandle file(current_path.c_str());
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
			wav_markers_regions_read(current_path.c_str(), markers, regions);

			data.pitches.resize(markers.size());
			std::transform(markers.cbegin(), markers.cend(), data.pitches.begin(), [](const WAV_MARKER &m) { return m.pos; });
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

CAllophoneTTS::PROSODY_CONTOUR LoadContour(const char *root_, const boost::property_tree::ptree &pt_) {
	CAllophoneTTS::PROSODY_CONTOUR ret;

	{
		std::istringstream isstr(pt_.get(std::string(root_) + ".position", ""));
		ret.position.assign((std::istream_iterator<double>(isstr)), std::istream_iterator<double>());
	}

	{
		std::istringstream isstr(pt_.get(std::string(root_) + ".factor", ""));
		ret.factor.assign((std::istream_iterator<double>(isstr)), std::istream_iterator<double>());
	}

	if (ret.position.size() != ret.factor.size()) {
		std::stringstream sstr;
		sstr << __FUNCTION__ << ": In \"" << root_ << "\" element the number of position points ("
			<< ret.position.size() << ") not equal to the number of factor points (" << ret.factor.size() << ").";
		throw std::runtime_error(sstr.str());
	}

	for (size_t i = 1; i < ret.position.size(); ++i)
		if (ret.position[i - 1]>ret.position[i])
			throw std::runtime_error(std::string(__FUNCTION__) + ": The points in \"" + root_ + ".position\" element are unordered.");

	if (!ret.position.empty()) {
		if (ret.position.front() != 0)
			throw std::runtime_error(std::string(__FUNCTION__) + ": The first point position in \"" + root_ + ".position\" must equals to zero.");
		if (ret.position.back() != 1)
			throw std::runtime_error(std::string(__FUNCTION__) + ": The last point position in \"" + root_ + ".position\" must equals to one.");
	}

	for (const auto &val : ret.factor)
		if (val < 1 / CAllophoneTTS::prosody_max_factor || val > CAllophoneTTS::prosody_max_factor)
			throw std::runtime_error(std::string(__FUNCTION__) + ": The factor value in \"" + root_ + ".factor in out of range.");

	return ret;
}

void CAllophoneTTS::LoadConfig(const boost::property_tree::ptree &pt) {
	syntagm_contour = LoadContour("tts.prosody.syntagm.frequency", pt);
	phrase_contour = LoadContour("tts.prosody.phrase.frequency", pt);
	paragraph_contour = LoadContour("tts.prosody.paragraph.frequency", pt);

	if (syntagm_contour.position.size()) {
		float input_data = 0;
		std::array<float, 16> prosody_buffer;
		int inUsed = 1;
		int out = 0;
		prosody_delay = 0;
		while (!out) {
			out = resample_process(prosody_handle, prosody_ratio, &input_data, 1, 0, &inUsed, &prosody_buffer[0], static_cast<int>(prosody_buffer.size()));
			prosody_delay++;
		}
	}
}

void CAllophoneTTS::PushBackAlaphone(const char *alp, const char *ind, std::deque<size_t> &queue) const {
	char alp_name[32];
	strcpy(alp_name, alp);
	strcat(alp_name, ind);

	size_t pos = static_cast<size_t>(std::lower_bound(base.names.cbegin(), base.names.cend(), alp_name, [](const char *a, const char *b) { return strcmp(a, b) < 0; }) - base.names.cbegin());
	assert(pos >= 0 && pos < base.datas.size());
	queue.push_back(pos);
}

int CAllophoneTTS::Word2Alaphones(char *word, bool last_word, std::deque<size_t> &queue) const {
	char alp[8], ind[8] = "xxx";
	char prev_symb = 0;

	int preaccent_pos, accent_pos, word_len;
	GetAccent(word, preaccent_pos, accent_pos, word_len);

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

void CAllophoneTTS::GetAccent(char *word, int &preaccent_pos, int &accent_pos, int &word_len) const {
	word_len = 0;
	accent_pos = 0;
	while (true)
	{
		const auto &c = word[word_len];
		if (c == accent_text_symbol) {
			accent_pos = word_len;
			word_len++;
			continue;
		}
		if (((c >= 'à') && (c <= 'ÿ')) || (c == '¸')) {
			word_len++;
			continue;
		}
		break;
	}

	if (word[accent_pos] == accent_text_symbol) {
		accent_pos--;
		word_len--;
		memmove(word + accent_pos, word + accent_pos + 1, word_len - accent_pos);
		word[word_len] = ' ';
	}
	else {
		int vovel_cnt = 0;
		for (int i = 0; i < word_len; i++)
			if (GroupVovel(word[i]))
				vovel_cnt++;

		accent_pos = vovel_cnt >> 1;
		vovel_cnt = 0;
		for (int i = 0; i < word_len; i++)
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

bool CAllophoneTTS::GroupVovel(char c) const {
	return strchr("àå¸èîóûýþÿ", c) != nullptr;
}

bool CAllophoneTTS::GroupChar01(char c) const {
	return strchr("òäñçöøæíðà", c) != nullptr;
}

bool CAllophoneTTS::GroupChar02(char c) const {
	return strchr("ïáôâëìóî", c) != nullptr;
}

bool CAllophoneTTS::GroupChar03(char c) const {
	return c == '\0' || strchr("üúàîóýûå¸þÿ", c) != nullptr;
}

bool CAllophoneTTS::GroupChar04(char c) const {
	return strchr("üå¸þÿè", c) != nullptr;
}

bool CAllophoneTTS::GroupChar05(char c) const {
	return c == '\0' || strchr("ïòêôöù÷õù", c) != nullptr;
}

bool CAllophoneTTS::GroupChar06(char c) const {
	return strchr("áäãçæëìíâéð", c) != nullptr;
}

bool CAllophoneTTS::GroupChar07(char c) const {
	return strchr("àåîóûè", c) != nullptr;
}

bool CAllophoneTTS::GroupChar08(char c) const {
	return strchr("áäãçæ", c) != nullptr;
}

std::deque<size_t> CAllophoneTTS::Text2Allophones(const char *text) const {
	std::vector<char> phrase(text, text + strlen(text) + 1);
	boost::algorithm::to_lower(phrase);

	std::deque<size_t> queue;

	const char tag_pause[] = "#pause";

	char *phrase_pos = &phrase[0];
	while (*phrase_pos) {
		while (!(*phrase_pos >= 'à' && *phrase_pos <= 'ÿ' || *phrase_pos == '¸' || *phrase_pos == accent_text_symbol) ||
			*phrase_pos == '#') {
			switch (*phrase_pos) {
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
			case '#':
				if (!strncmp(phrase_pos, tag_pause, sizeof(tag_pause) - 1)) {
					phrase_pos[sizeof(tag_pause)] = '\0';
					size_t pos = static_cast<size_t>(std::lower_bound(base.names.cbegin(), base.names.cend(), phrase_pos, [](const char *a, const char *b) { return strcmp(a, b) < 0; }) - base.names.cbegin());
					assert(pos >= 0 && pos < base.datas.size());
					queue.push_back(pos);
					phrase_pos += sizeof(tag_pause);
				}
				break;
			default:
				break;
			}
			phrase_pos++;
		}

		phrase_pos += Word2Alaphones(phrase_pos, false, queue);
	}
phrase_finish:

	return queue;
}

std::vector<int16_t> CAllophoneTTS::Allophones2Sound(double outdevice2base_ratio, std::deque<size_t> &allophones, std::deque<MARK_DATA> *marks) {
	std::vector<int16_t> ret;
	if (marks)
		marks->clear();

	// Find next pause
	size_t syntagm_size = 0;
	auto pause_it = allophones.begin();
	for (auto ie = allophones.cend(); pause_it != ie; ++pause_it) {
		if (*pause_it == syntagm_index || *pause_it == phrase_index || *pause_it == paragraph_index)
			break;
		syntagm_size += base.datas[*pause_it].signal.size();
	}
	if (pause_it == allophones.cend())
		throw std::runtime_error(std::string(__FUNCTION__) + ": Can't determine syntagm bounds.");

	const PROSODY_CONTOUR &prosody_contour = *pause_it == syntagm_index ? syntagm_contour :
		(*pause_it == phrase_index ? phrase_contour : paragraph_contour);

	ret.reserve(syntagm_size + base.datas[*pause_it].signal.size());

	float ret_min = static_cast<float>(std::numeric_limits<int16_t>::min());
	float ret_max = static_cast<float>(std::numeric_limits<int16_t>::max());
	{
		float prosody_input = 0;
		std::array<float, 16> prosody_output;
		int prosody_inUsed = 1;
		size_t prosody_border = 0; // prosody coefficients recalculation position
		size_t prosody_contour_ind = 0;
		double prosody_a = 0, prosody_b = 0;

		size_t syntagm_pos = 0;
		for (auto alp_it = allophones.cbegin(); alp_it != pause_it; ++alp_it) {
			const auto &sgnl = base.datas[*alp_it].signal;

			if (marks)
				marks->push_back(MARK_DATA(ret.size() + prosody_delay, base.names[*alp_it]));

			if (prosody_contour.position.empty()) {
				ret.insert(ret.end(), sgnl.cbegin(), sgnl.cend());
				continue;
			}

			auto sgnl_it = sgnl.cbegin();
			for (size_t sgnl_i = 0, sgnl_sz = sgnl.size(); sgnl_i < sgnl_sz; ++sgnl_i, ++syntagm_pos, ++sgnl_it) {

				if (syntagm_pos == prosody_border) {
					prosody_b = (prosody_contour.factor[prosody_contour_ind + 1] * prosody_contour.position[prosody_contour_ind] * syntagm_size -
						prosody_contour.factor[prosody_contour_ind] * prosody_contour.position[prosody_contour_ind + 1] * syntagm_size) /
						(prosody_contour.factor[prosody_contour_ind] - prosody_contour.factor[prosody_contour_ind + 1]);
					if (std::isinf(prosody_b))
						prosody_b = (prosody_b < 0 ? -1 : 1) * std::numeric_limits<double>::max() / prosody_max_factor;
					prosody_a = (1 / prosody_contour.factor[prosody_contour_ind]) * (prosody_contour.position[prosody_contour_ind] * syntagm_size + prosody_b);

					prosody_contour_ind++;
					prosody_border = static_cast<size_t>(floor(prosody_contour.position[prosody_contour_ind] * syntagm_size + 0.5)); // round
				}

				prosody_input = *sgnl_it;

				prosody_ratio = prosody_a / (syntagm_pos + prosody_b);

				int out = resample_process(prosody_handle, outdevice2base_ratio*prosody_ratio, &prosody_input, 1, 0, &prosody_inUsed, &prosody_output[0], static_cast<int>(prosody_output.size()));
				if (out < 0)
					throw std::runtime_error(std::string(__FUNCTION__) + ": Prosody resampler return negative value.");

				for (int i = 0; i < out; ++i)
					ret.push_back(static_cast<int16_t>(std::max(ret_min, std::min(ret_max, prosody_output[i]))));
			}
		}
	}

	if (marks)
		marks->push_back(MARK_DATA(ret.size() + prosody_delay, base.names[*pause_it]));

	const auto &sgnl = base.datas[*pause_it].signal;
	if (prosody_contour.position.empty())
		ret.insert(ret.end(), sgnl.cbegin(), sgnl.cend());
	else {
		prosody_ratio = 1;

		auto sgnl_it = sgnl.cbegin();
		size_t sgnl_sz = sgnl.size();
		std::array<float, 256> sgnl_input;
		std::array<float, 512> sgnl_output;
		size_t sgnl_input_pos = 0;
		int prosody_inUsed = 0;

		while (sgnl_sz) {
			size_t copy_sz = std::min(sgnl_input.size() - sgnl_input_pos, sgnl_sz);
			std::copy(sgnl_it, sgnl_it + copy_sz, sgnl_input.begin() + sgnl_input_pos);
			sgnl_it += copy_sz;
			sgnl_sz -= copy_sz;
			sgnl_input_pos += copy_sz;

			int out = resample_process(prosody_handle, outdevice2base_ratio*prosody_ratio, &sgnl_input[0], sgnl_input_pos, 0, &prosody_inUsed, &sgnl_output[0], static_cast<int>(sgnl_output.size()));
			if (out < 0)
				throw std::runtime_error(std::string(__FUNCTION__) + ": Prosody resampler return negative value.");

			std::copy(sgnl_input.cbegin() + prosody_inUsed, sgnl_input.cbegin() + sgnl_input_pos, sgnl_input.begin());
			sgnl_input_pos -= prosody_inUsed;

			for (int i = 0; i < out; ++i)
				ret.push_back(static_cast<int16_t>(std::max(ret_min, std::min(ret_max, sgnl_output[i]))));
		}
	}

	allophones.erase(allophones.begin(), pause_it + 1);

	return ret;
}
