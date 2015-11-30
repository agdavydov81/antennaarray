#ifndef TEXT_GENERATOR_H
#define TEXT_GENERATOR_H
#include <vector>
#include <array>
#include <string>

#ifndef uint
typedef unsigned int uint;
#endif
#ifndef ulong
typedef unsigned long ulong;
#endif

class CTextGenerator
{
public:
	CTextGenerator(ulong seed=0);
	CTextGenerator(const char *filename, ulong seed=0);
	virtual ~CTextGenerator();

	/// Generate next SLS text paragraph.
	std::string Generate();

private:
	std::vector<std::string> txt;
	std::vector<std::vector<uint>> cdfs;

	void LoadProbabilities(const char *file_name);

	static const uint phrase_cdf[];
	static const uint syntagma_cdf[];
	static const uint word_cdf[];
	static const uint syll_cdf[];
	static const size_t	syll_num[];
	static const size_t	syll_accent[];
};

#endif // __TEXT_GENERATOR_H__