/********************************************************************
	created:	13.12.2013 13:35
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

void wav_markers_regions_read(
#if defined(_MSC_VER) && (defined(UNICODE) || defined(_UNICODE))
	const wchar_t *file_name,
#else
	const char *file_name,
#endif
	std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions);

void wav_markers_regions_write(
#if defined(_MSC_VER) && (defined(UNICODE) || defined(_UNICODE))
	const wchar_t *file_name,
#else
	const char *file_name,
#endif
	const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions);

#endif // WAV_MARKERS_REGIONS_H
