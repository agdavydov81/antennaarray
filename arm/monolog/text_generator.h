#ifndef TEXT_GENERATOR_H
#define TEXT_GENERATOR_H
#include <vector>
#include <array>
#include <string>
#include <boost/random.hpp>
#include <boost/filesystem.hpp>

#ifndef uint
typedef unsigned int uint;
#endif
#ifndef ulong
typedef unsigned long ulong;
#endif

class CTextGenerator
{
public:
	CTextGenerator(ulong seed = 0);
	CTextGenerator(const char *filename, ulong seed = 0);
	CTextGenerator(const boost::filesystem::path &filename, ulong seed = 0);
	virtual ~CTextGenerator();

	/// Generate next SLS text paragraph.
	std::string Generate();

private:
	boost::mt19937 rnd;
	size_t rand_gen_vec(const std::vector<size_t> &cdf) {
		boost::random::uniform_int_distribution<> dist(cdf.front(), cdf.back() - 1);
		return (std::upper_bound(cdf.begin(), cdf.end(), (size_t)dist(rnd)) - cdf.begin()) - 1;
	}
	template<typename T>
	size_t rand_gen_arr(const T *cdf, size_t cdf_sz) {
		boost::random::uniform_int_distribution<> dist(0, cdf[cdf_sz - 1] - 1);
		return ((std::upper_bound(cdf, cdf + cdf_sz, (T)dist(rnd)) - cdf) - 1);
	}

	std::vector<std::string> txt;
	std::vector<std::vector<size_t>> cdfs;

	void LoadProbabilities(const char *filename);
	void LoadProbabilities(const boost::filesystem::path &filename);
	

	static const uint phrase_cdf[];
	static const uint syntagma_cdf[];
	static const uint word_cdf[];
	static const uint syll_cdf[];
	static const size_t	syll_num[];
	static const size_t	syll_accent[];
};

#endif // __TEXT_GENERATOR_H__