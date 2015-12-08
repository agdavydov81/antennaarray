#include "text_generator.h"
#include <ctime>
#include <iterator>
#include <fstream>
#include <sstream>
#include <numeric>
#include <algorithm>

//Распределение числа фраз в фоноабзаце
const uint		CTextGenerator::phrase_cdf[] = { 0, 5, 15, 30, 60, 85, 95, 100 };
//Распределение числа синтагм во фразе
const uint		CTextGenerator::syntagma_cdf[] = { 0, 5, 15, 45, 70, 85, 95, 100 };
//Распределение числа слов в синтагме
const uint		CTextGenerator::word_cdf[] = { 0, 5, 15, 45, 70, 85, 95, 100 };
//Распределение числа слогов в слове и положения ударения
const uint		CTextGenerator::syll_cdf[] = {
	0,
	164125,
	343209,	528106,
	601897,	731577,	794120,
	803794,	863045,	924009,	930700,
	932168,	942444,	973197,	981961,	982528,
	982573,	983865,	988539,	995541,	996648,	996695,
	996698,	996828,	997328,	998342,	999413,	999604,	999609,
	999609,	999617,	999648,	999723,	999859,	999946,	999956,	999956,
	999956,	999956,	999959,	999961,	999974,	999995,	1000000,1000000,1000000 };
const size_t	CTextGenerator::syll_num[] = {
	1,
	2,	2,
	3,	3,	3,
	4,	4,	4,	4,
	5,	5,	5,	5,	5,
	6,	6,	6,	6,	6,	6,
	7,	7,	7,	7,	7,	7,	7,
	8,	8,	8,	8,	8,	8,	8,	8,
	9,	9,	9,	9,	9,	9,	9,	9,	9 };
const size_t	CTextGenerator::syll_accent[] = {
	0,
	0,	1,
	0,	1,	2,
	0,	1,	2,	3,
	0,	1,	2,	3,	4,
	0,	1,	2,	3,	4,	5,
	0,	1,	2,	3,	4,	5,	6,
	0,	1,	2,	3,	4,	5,	6,	7,
	0,	1,	2,	3,	4,	5,	6,	7,	8 };

CTextGenerator::CTextGenerator(ulong seed) : rnd(seed == 0 ? static_cast<ulong>(time(nullptr)) : seed)
{
}

CTextGenerator::CTextGenerator(const char *filename, ulong seed) : CTextGenerator(seed)
{
	LoadProbabilities(filename);
}

CTextGenerator::CTextGenerator(const boost::filesystem::path &filename, ulong seed) : CTextGenerator(seed)
{
	LoadProbabilities(filename);
}

CTextGenerator::~CTextGenerator()
{
}

void CTextGenerator::LoadProbabilities(const char* filename)
{
	LoadProbabilities(boost::filesystem::path(filename));
}

void CTextGenerator::LoadProbabilities(const boost::filesystem::path &bfilename)
{
	std::string filename(bfilename.generic_string());
	try {
		std::ifstream fh(filename);
		if (!fh)
			throw std::runtime_error("Can't open input file.");

		std::string line;
		if (!std::getline(fh, line))
			throw std::runtime_error("Error getting header line.");

		size_t txt_num, txt_sum_length;
		std::istringstream(line) >> txt_num >> txt_sum_length;

		if (!std::getline(fh, line))
			throw std::runtime_error("Error getting text line.");
		if (line.length() != txt_sum_length)
			throw std::runtime_error("Incorrect text length.");
        std::istringstream line_stream(line);
		txt.assign((std::istream_iterator<std::string>(line_stream)), std::istream_iterator<std::string>());
		if (txt.size() != txt_num)
			throw std::runtime_error("Incorrect text elements number.");

		++txt_num;
		std::vector<uint> data((std::istream_iterator<uint>(fh)), std::istream_iterator<uint>());
		if (data.size() != txt_num*txt_num)
			throw std::runtime_error("Incorrect probability values number.");

		cdfs.resize(txt_num);
		for (size_t ci = 0; ci < txt_num; ++ci) {
			cdfs[ci].resize(txt_num);

			std::partial_sum(data.begin() + ci*txt_num + 1, data.begin() + (ci + 1)*txt_num, cdfs[ci].begin() + 1);

			if (cdfs[ci].back() != data[ci*txt_num])
				throw std::runtime_error("Probabilities table values error.");
		}
	}
	catch (const std::exception &err) {
		throw std::runtime_error(std::string(__FUNCTION__) + "File \"" + filename + "\" processing error: " + err.what());
	}
}

#define rand_gen(cdf__) rand_gen_arr(cdf__, sizeof(cdf__)/sizeof(cdf__[0]))

std::string CTextGenerator::Generate()
{
	std::stringstream sstr;

	size_t last_txt_ind = 0;
	for (size_t phrase_i = 0, phrase_num = rand_gen(phrase_cdf) + 1; phrase_i < phrase_num; ++phrase_i) {
		for (size_t syntagma_i = 0, syntagma_num = rand_gen(syntagma_cdf) + 1; syntagma_i < syntagma_num; ++syntagma_i) {
			for (size_t word_i = 0, word_num = rand_gen(word_cdf) + 1; word_i < word_num; ++word_i) {
				for (size_t syll_i = 0, syll_ind = rand_gen(syll_cdf), syll_num_val = syll_num[syll_ind], syll_accent_val = syll_accent[syll_ind]; syll_i < syll_num_val; ++syll_i) {
					last_txt_ind = rand_gen_vec(cdfs[last_txt_ind]);
					sstr << txt[last_txt_ind].c_str();
					last_txt_ind++;
					if (syll_i == syll_accent_val)
						sstr << "'";
				}
				if (word_i + 1 != word_num)
					sstr << " ";
			}
			if (syntagma_i + 1 != syntagma_num)
				sstr << ", ";
		}
		sstr << ". ";
	}

	return sstr.str();
}
