/********************************************************************
	created:	30.11.2015 20:07
	file base:	wav_markers_regions.h
	author:		Andrei Davydov
*********************************************************************/

#ifndef WAV_MARKERS_REGIONS_H
#define WAV_MARKERS_REGIONS_H

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
# pragma once
#endif

#include <vector>
#include <string>

/**	\brief			Структура описания одного маркера.
*/struct WAV_MARKER{
	WAV_MARKER(size_t pos_=0, const char *name_="") : pos(pos_), name(name_) {};
	size_t	pos;		/**< Позиция маркера в отсчетах. */
	std::string name;	/**< Имя маркера. */
};

/**	\brief			Структура описания одного региона.
*/struct WAV_REGION{
	WAV_REGION(size_t pos_=0, size_t length_=0, const char *name_="") : pos(pos_), length(length_), name(name_) {};
	size_t	pos;		/**< Позиция начала региона в отсчетах. */
	size_t	length;		/**< Длина региона в отсчетах. */
	std::string name;	/**< Имя региона. */
};

void wav_markers_regions_read(const char *file_name, std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions);
#ifdef _MSC_VER
void wav_markers_regions_read(const wchar_t *file_name, std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions);
#endif

void wav_markers_regions_write(const char *file_name, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions);
#ifdef _MSC_VER
void wav_markers_regions_write(const wchar_t *file_name, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions);
#endif

#endif // WAV_MARKERS_REGIONS_H
