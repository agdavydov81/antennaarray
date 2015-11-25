#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iterator>
#include <numeric>
#include <algorithm>
#include <ctime>
#include "random.h"

typedef unsigned int uint;

void load_probabilities(const char *file_name,
						std::vector< std::string > &txt,
						std::vector< std::vector<uint> > &cdfs);

//Распределение числа фраз в фоноабзаце
const uint	phrase_cdf_init[]={		0, 5, 15, 30, 60, 85, 95, 100};
 //Распределение числа синтагм во фразе
const uint	syntagma_cdf_init[]={	0, 5, 15, 45, 70, 85, 95, 100};
//Распределение числа слов в синтагме
const uint	word_cdf_init[]={		0, 5, 15, 45, 70, 85, 95, 100};
//Распределение числа слогов в слове и положения ударения
uint	syll_cdf_init[]={
		0,
		164125,
		343209,	528106,
		601897,	731577,	794120,
		803794,	863045,	924009,	930700,
		932168,	942444,	973197,	981961,	982528,
		982573,	983865,	988539,	995541,	996648,	996695,
		996698,	996828,	997328,	998342,	999413,	999604,	999609,
		999609,	999617,	999648,	999723,	999859,	999946,	999956,	999956,
		999956,	999956,	999959,	999961,	999974,	999995,	1000000,1000000,1000000};
size_t	syll_num_init[]={
		1,
		2,	2,
		3,	3,	3,
		4,	4,	4,	4,
		5,	5,	5,	5,	5,
		6,	6,	6,	6,	6,	6,
		7,	7,	7,	7,	7,	7,	7,
		8,	8,	8,	8,	8,	8,	8,	8,
		9,	9,	9,	9,	9,	9,	9,	9,	9};
size_t	syll_accent_init[]={
		0,
		0,	1,
		0,	1,	2,
		0,	1,	2,	3,
		0,	1,	2,	3,	4,
		0,	1,	2,	3,	4,	5,
		0,	1,	2,	3,	4,	5,	6,
		0,	1,	2,	3,	4,	5,	6,	7,
		0,	1,	2,	3,	4,	5,	6,	7,	8};

size_t rand_gen(const std::vector<uint> &cdf) {
	return (std::upper_bound(cdf.begin(), cdf.end(), randomMT()%cdf.back())-cdf.begin())-1;
}

int main(int argc, char *argv[]) {
	if(argc!=3 && argc!=4) {
		printf("Usage: sls_gen_text <out_file_name> <paragraph_number> [random_seed]\n");
		return 1;
	}

	std::vector< std::string > txt;
	std::vector< std::vector<uint> > cdfs;

	unsigned long rand_seed = argc==4 ? strtol(argv[3],NULL,0) : (unsigned long)time(0);
	size_t paragraph_num=strtol(argv[2],NULL,10);

	try {
		load_probabilities("det_res.txt", txt, cdfs);

		std::vector<uint> phrase_cdf(phrase_cdf_init, phrase_cdf_init+sizeof(phrase_cdf_init)/sizeof(phrase_cdf_init[0]));
		std::vector<uint> syntagma_cdf(syntagma_cdf_init, syntagma_cdf_init+sizeof(syntagma_cdf_init)/sizeof(syntagma_cdf_init[0]));
		std::vector<uint> word_cdf(word_cdf_init, word_cdf_init+sizeof(word_cdf_init)/sizeof(word_cdf_init[0]));
		std::vector<uint> syll_cdf(syll_cdf_init, syll_cdf_init+sizeof(syll_cdf_init)/sizeof(syll_cdf_init[0]));

		randomizeMT(rand_seed);

		std::ofstream fh(argv[1]);
		fh << "  ";

		// Synthesis main loop
		for(size_t paragraph_i=0; paragraph_i<paragraph_num; ++paragraph_i) {
			size_t last_txt_ind=0;
			for(size_t phrase_i=0, phrase_num=rand_gen(phrase_cdf)+1; phrase_i<phrase_num; ++phrase_i) {
				for(size_t syntagma_i=0, syntagma_num=rand_gen(syntagma_cdf)+1; syntagma_i<syntagma_num; ++syntagma_i) {
					for(size_t word_i=0, word_num=rand_gen(word_cdf)+1; word_i<word_num; ++word_i) {
						for(size_t syll_i=0, syll_ind=rand_gen(syll_cdf), syll_num=syll_num_init[syll_ind], syll_accent=syll_accent_init[syll_ind]; syll_i<syll_num; ++syll_i) {
							last_txt_ind = rand_gen(cdfs[last_txt_ind]);
							fh << txt[last_txt_ind].c_str();
							last_txt_ind++;
							if(syll_i==syll_accent)
								fh << "'";
						}
						if(word_i+1!=word_num)
							fh << " ";
					}
					if(syntagma_i+1!=syntagma_num)
						fh << ", ";
				}
				fh << "." << std::endl;
			}
			fh << "  ";
		}
	}
	catch(const std::exception &err) {
		std::cerr << "Error: " << err.what() << std::endl;
		return 1;
	}

	return 0;
}

void load_probabilities(const char *file_name,
						std::vector< std::string > &txt,
						std::vector< std::vector<uint> > &cdfs) {

	try {
		std::ifstream fh(file_name);
		if(!fh)
			throw std::runtime_error("Can't open input file.");

		std::string line;
		if(!std::getline(fh, line))
			throw std::runtime_error("Error getting header line.");

		size_t txt_num, txt_sum_length;
		std::istringstream(line) >> txt_num >> txt_sum_length;

		if(!std::getline(fh, line))
			throw std::runtime_error("Error getting text line.");
		if(line.length()!=txt_sum_length)
			throw std::runtime_error("Incorrect text length.");
		txt.assign((std::istream_iterator<std::string>(std::istringstream(line))), std::istream_iterator<std::string>());
		if(txt.size()!=txt_num)
			throw std::runtime_error("Incorrect text elements number.");

		++txt_num;
		std::vector<uint> data((std::istream_iterator<uint>(fh)), std::istream_iterator<uint>());
		if(data.size()!=txt_num*txt_num)
			throw std::runtime_error("Incorrect probability values number.");

		cdfs.resize(txt_num);
		for(size_t ci=0; ci<txt_num; ++ci) {
			cdfs[ci].resize(txt_num);

			std::partial_sum(data.begin()+ci*txt_num+1, data.begin()+(ci+1)*txt_num, cdfs[ci].begin()+1);

			if(cdfs[ci].back()!=data[ci*txt_num])
				throw std::runtime_error("Probabilities table values error.");
		}
	}
	catch(const std::exception &err) {
		throw std::runtime_error(std::string("File \"")+file_name+"\" processing error: "+err.what());
	}
}
