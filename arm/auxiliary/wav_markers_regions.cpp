#include "wav_markers_regions.h"
#include <stdexcept>
#include <fstream>
#include <cstdint>
#include <cstddef>
#include <memory>
#include <algorithm>

#pragma pack(push, 1)

struct UNIVERSAL_CHUNK {
	union{
		char		name_ch4[4];
		uint32_t	name_id;
	};
	uint32_t	size;
};

struct RIFF_CHUNK : UNIVERSAL_CHUNK {
	uint32_t	format;
};

struct FMT_CHUNK : UNIVERSAL_CHUNK {
	uint16_t	sound_format;
	uint16_t	num_channels;
	uint32_t	sample_rate;
	uint32_t	byte_rate;
	uint16_t	block_align;
	uint16_t	bits_per_sample;
	uint16_t	extra_bytes;
};

struct FACT_CHUNK : UNIVERSAL_CHUNK {
	uint32_t	samples_num;
};

struct DATA_CHUNK : UNIVERSAL_CHUNK {
};

struct CUE_TBL{
	uint32_t	Id;
	uint32_t	position;
	uint32_t	fcc_chunk;
	uint32_t	chunk_start;
	uint32_t	block_start;
	uint32_t	sample_offset;
};

struct CUE_HEAD : UNIVERSAL_CHUNK {
	uint32_t	table_size;
};

struct CUE_ALL : CUE_HEAD {
	CUE_TBL		table[1];
};

struct LIST_CHUNK : UNIVERSAL_CHUNK {
	uint32_t	type;
};

struct LTXT_CHUNK : UNIVERSAL_CHUNK {
	uint32_t	Id;
	uint32_t	length;
	uint32_t	purpose;
	uint16_t	country;
	uint16_t	language;
	uint16_t	dialect;
	uint16_t	code_page;
};

struct LABL_HEAD : UNIVERSAL_CHUNK {
	uint32_t	Id;
};

struct LABL_ALL : LABL_HEAD {
	char		name_str[1];
};

enum FILE_IDs {
	id_RIFF=	0x46464952,
	id_WAVE=	0x45564157,
	id_fmt=		0x20746D66,
	id_fact=	0x74636166,
	id_data=	0x61746164,
	id_cue=		0x20657563,
	id_LIST=	0x5453494C,
	id_adtl=	0x6C746461,
	id_INFO=	0x4F464E49,
	id_ltxt=	0x7478746C,
	id_labl=	0x6C62616C,
	id_rgn=		0x206E6772
};

#pragma pack(pop)

size_t chunk_search(std::ifstream &fh, const std::streampos &file_size, FILE_IDs chunk_id, bool reset_pos = true) {
	if(reset_pos)
		fh.seekg((sizeof(RIFF_CHUNK)+1)&-2, fh.beg);

	UNIVERSAL_CHUNK chunk;
	while(file_size-fh.tellg()>=sizeof(chunk)) {
		if(!fh.read((char *)&chunk, sizeof(chunk)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");

		if(chunk.name_id==chunk_id)
			return chunk.size;

		fh.seekg((chunk.size+1)&-2, fh.cur);
	}

	return 0;
}

void wav_markers_regions_read_(std::ifstream &fh, std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions) {
	markers.clear();
	regions.clear();

	if(!fh)
		throw std::runtime_error(std::string(__FUNCTION__) + ": Can't open file.");

	fh.seekg(0, fh.end);
	std::streampos file_size = fh.tellg();
	fh.seekg(0, fh.beg);

	// Read RIFF-WAVE-FMT head ///////////////////////////////////////////////
	{
		RIFF_CHUNK riff_head;
		if(!fh.read((char *)&riff_head, sizeof(riff_head)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");

		if(riff_head.name_id!=id_RIFF || riff_head.format!=id_WAVE)
			throw std::runtime_error(std::string(__FUNCTION__) + ": Unsupported file format: not RIFF-WAVE file.");

		file_size = std::min(file_size, (std::streampos)(riff_head.size+sizeof(UNIVERSAL_CHUNK)));
	}

	// Read CUE chunk ////////////////////////////////////////////////////////
	size_t chunk_size;
	if(!(chunk_size=chunk_search(fh, file_size, id_cue)))
		return;

	std::vector<char> cue_data(chunk_size+sizeof(UNIVERSAL_CHUNK));
	CUE_ALL *CUE = (CUE_ALL *)&cue_data[0];
	fh.seekg(-(std::streampos)sizeof(UNIVERSAL_CHUNK), fh.cur);
	if(!fh.read(&cue_data[0], cue_data.size()))
		throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");

	// Read LIST chunk ///////////////////////////////////////////////////////
	std::vector<char> list_data;

	fh.seekg((sizeof(RIFF_CHUNK)+1)&-2, fh.beg);
	while(chunk_size=chunk_search(fh, file_size, id_LIST, false)) {
		LIST_CHUNK cur_list;
		if(!fh.read((char *)&cur_list.type, sizeof(cur_list.type)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");
		if(cur_list.type==id_adtl) {
			list_data.resize(chunk_size-sizeof(cur_list.type));
			fh.read(&list_data[0], list_data.size());
			break;
		}
		else
			fh.seekg((chunk_size-sizeof(cur_list.type)+1)&-2, fh.cur);
	}
	if(list_data.empty())
		return;
	const char *list_data_prt = &list_data[0];

	// Parse all data ////////////////////////////////////////////////////////
	struct NEXT_CHUNK{
		union {
			char		name_ch4[4];
			uint32_t	name_id;
			uint32_t	next_chunk_pos;
		};
		uint32_t	size;
	};
	struct LTXT_NEXT:NEXT_CHUNK{
		uint32_t	Id;
		uint32_t	length;
		uint32_t	purpose;
		uint16_t	country;
		uint16_t	language;
		uint16_t	dialect;
		uint16_t	code_page;
	}*LTXT,*ltxt_last;
	LTXT=ltxt_last=NULL;

	struct LABL_NEXT:NEXT_CHUNK{
		uint32_t	Id;
		char		name_str[1];
	}*LABL,*labl_last,*labl_tek;
	LABL=labl_last=labl_tek=NULL;

	labl_tek=(LABL_NEXT *)list_data_prt;

	size_t i=0;
	while(i+sizeof(UNIVERSAL_CHUNK)<list_data.size()){
		switch(labl_tek->name_id){
		case id_ltxt:
			if(!LTXT){
				LTXT=ltxt_last=(LTXT_NEXT *)labl_tek;
			}
			else{
				ltxt_last->next_chunk_pos=(uint32_t)((ptrdiff_t)labl_tek-(ptrdiff_t)list_data_prt);
				ltxt_last=(LTXT_NEXT *)labl_tek;
			}
			break;
		case id_labl:
			if(!LABL){
				LABL=labl_last=labl_tek;
			}
			else{
				labl_last->next_chunk_pos=(uint32_t)((ptrdiff_t)labl_tek-(ptrdiff_t)list_data_prt);
				labl_last=labl_tek;
			}
			break;
		}
		i+=((labl_tek->size+sizeof(UNIVERSAL_CHUNK)+1)&-2);
		labl_tek=(LABL_NEXT *)((size_t)list_data_prt+i);
	}
	if(ltxt_last)
		ltxt_last->next_chunk_pos=0;
	if(labl_last)
		labl_last->next_chunk_pos=0;

	ltxt_last=LTXT;
	while(ltxt_last){
		labl_tek=LABL;
		labl_last=NULL;
		while((labl_tek)&&(ltxt_last->Id!=labl_tek->Id)){
			labl_last=labl_tek;
			labl_tek = labl_tek->next_chunk_pos ? (LABL_NEXT *)(labl_tek->next_chunk_pos + list_data_prt) : NULL;
		}
		if(labl_tek){
			i=0;
			while((i<CUE->table_size)&&(ltxt_last->Id!=CUE->table[i].Id))
				i++;
			if(i<CUE->table_size){
				regions.push_back(WAV_REGION(CUE->table[i].position,ltxt_last->length,labl_tek->name_str));
				if(!labl_last)
					LABL = LABL->next_chunk_pos ? (LABL_NEXT *)(LABL->next_chunk_pos + list_data_prt) : NULL;
				else
					labl_last->next_chunk_pos=labl_tek->next_chunk_pos;
				CUE->table[i].fcc_chunk=0;
			}
		}

		ltxt_last = ltxt_last->next_chunk_pos ? (LTXT_NEXT *)(ltxt_last->next_chunk_pos + list_data_prt) : NULL;
	}

	for (i=0;i<CUE->table_size;i++)
		if(CUE->table[i].fcc_chunk==id_data) {
			labl_tek=LABL;
			labl_last=NULL;
			while((labl_tek)&&(CUE->table[i].Id!=labl_tek->Id)){
				labl_last=labl_tek;
				labl_tek = labl_tek->next_chunk_pos ? (LABL_NEXT *)(labl_tek->next_chunk_pos + list_data_prt) : NULL;
			}
			const char *cur_name = "";
			if(labl_tek){
				cur_name = labl_tek->name_str;
				if(!labl_last)
					LABL = LABL->next_chunk_pos ? (LABL_NEXT *)(LABL->next_chunk_pos + list_data_prt) : NULL;
				else
					labl_last->next_chunk_pos=labl_tek->next_chunk_pos;
			}
			markers.push_back(WAV_MARKER(CUE->table[i].position, cur_name));
		}
}

void wav_markers_regions_read(const char *file_name, std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions) {
    std::ifstream file_stream(file_name, std::ios_base::in | std::ios_base::binary);
	wav_markers_regions_read_(file_stream, markers, regions);
}

#ifdef _MSC_VER
void wav_markers_regions_read(const wchar_t *file_name, std::vector<WAV_MARKER> &markers, std::vector<WAV_REGION> &regions) {
    std::ifstream file_stream(file_name, std::ios_base::in | std::ios_base::binary);
	wav_markers_regions_read_(file_stream, markers, regions);
}
#endif

std::streampos delete_markers_regions_from_file(std::fstream &fh, std::streampos file_size) {
	std::streampos put_pos=(sizeof(RIFF_CHUNK)+1)&-2;

	fh.seekg(put_pos, fh.beg);

	while(file_size-fh.tellg()>=sizeof(UNIVERSAL_CHUNK)) {
		UNIVERSAL_CHUNK cur_chunk;
		if(!fh.read((char *)&cur_chunk, sizeof(cur_chunk)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");

		std::streampos next_chunk_pos = (fh.tellg() + (std::streampos)cur_chunk.size + (std::streampos)1)&-2;

		bool is_copy_chunk=true;
		if(cur_chunk.name_id==id_cue) {
			is_copy_chunk = false;
		}
		else if(cur_chunk.name_id==id_LIST) {
			LIST_CHUNK list_chunk;
			if(cur_chunk.size<sizeof(list_chunk.type) || !fh.read((char *)&list_chunk.type, sizeof(list_chunk.type)))
				throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");
			if(list_chunk.type==id_adtl)
				is_copy_chunk = false;
			else
				fh.seekg(-(std::streampos)sizeof(list_chunk.type), fh.cur);
		}

		if(is_copy_chunk) {
			if(put_pos+(std::streampos)sizeof(cur_chunk)==fh.tellg()) {
				put_pos = next_chunk_pos;
			}
			else {
				std::streampos get_pos = fh.tellg();

				fh.seekp(put_pos);
				fh.write((const char *)&cur_chunk, sizeof(cur_chunk));
				put_pos+=sizeof(cur_chunk);

				std::vector<char> buff(std::min((uint32_t)64*1024, cur_chunk.size));
				while(cur_chunk.size) {
					uint32_t cur_sz = std::min(cur_chunk.size, (uint32_t)buff.size());
					fh.seekg(get_pos, fh.beg);
					if(!fh.read(&buff[0], cur_sz))
						throw std::runtime_error(std::string(__FUNCTION__) + ": File read error.");
					get_pos+=cur_sz;
					fh.seekp(put_pos, fh.beg);
					if(!fh.write(&buff[0], cur_sz))
						throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
					put_pos+=cur_sz;
					cur_chunk.size-=cur_sz;
				}
				if(fh.tellp()&1) {
					if(!fh.write("", 1))
						throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
					put_pos+=1;
				}
			}
		}

		fh.seekg(next_chunk_pos, fh.beg);
	}

	return put_pos;
}

std::streampos write_markers_regions_to_file(std::fstream &fh, std::streampos put_pos, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions) {
	if(!regions.size() && !markers.size())
		return put_pos;

	// Write cue chunk ///////////////////////////////////////////////////////
	fh.seekp(put_pos);
	CUE_HEAD CUE;
	CUE.name_id=id_cue;
	CUE.size=(uint32_t)((markers.size()+regions.size())*sizeof(CUE_TBL)+sizeof(CUE_HEAD)-sizeof(UNIVERSAL_CHUNK));
	CUE.table_size=(uint32_t)(markers.size()+regions.size());
	if(!fh.write((const char *)&CUE, sizeof(CUE)))
		throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");

	CUE_TBL cue_tbl;
	cue_tbl.fcc_chunk =		id_data;
	cue_tbl.chunk_start =	0;
	cue_tbl.block_start =	0;
	for (size_t i=0; i<regions.size(); ++i) {
		cue_tbl.Id =								(uint32_t)i+1;
		cue_tbl.position = cue_tbl.sample_offset =	(uint32_t)regions[i].pos;
		if(!fh.write((const char *)&cue_tbl, sizeof(cue_tbl)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
	}
	for (size_t i=0; i<markers.size(); ++i) {
		cue_tbl.Id =								(uint32_t)(regions.size()+i+1);
		cue_tbl.position = cue_tbl.sample_offset =	(uint32_t)markers[i].pos;
		if(!fh.write((const char *)&cue_tbl, sizeof(cue_tbl)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
	}

	// Write LIST chunk //////////////////////////////////////////////////////
	std::streampos LIST_pos = fh.tellp();
	LIST_CHUNK LIST;
	LIST.name_id=	id_LIST;
	LIST.size=		0;
	LIST.type=		id_adtl;
	if(!fh.write((const char *)&CUE, sizeof(CUE)))
		throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");

	LTXT_CHUNK LTXT;
	LTXT.name_id =		id_ltxt;
	LTXT.size =			sizeof(LTXT_CHUNK)-sizeof(UNIVERSAL_CHUNK);
	LTXT.purpose =		id_rgn;
	LTXT.country =		0;
	LTXT.language =		0;
	LTXT.dialect =		0;
	LTXT.code_page =	0;

	LABL_HEAD LABL;
	LABL.name_id=		id_labl;

	// Write regions /////////////////////////////////////////////////////////
	for (size_t i=0; i<regions.size(); ++i) {
		LTXT.Id =			(uint32_t)i+1;
		LTXT.length=		(uint32_t)regions[i].length;
		if(!fh.write((const char *)&LTXT, sizeof(LTXT)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
	}
	for (size_t i=0; i<regions.size(); ++i) {
		size_t str_sz =		regions[i].name.size();
		LABL.size =			(uint32_t)(sizeof(LABL_HEAD)-sizeof(UNIVERSAL_CHUNK) + str_sz+1);
		LABL.Id =			(uint32_t)i+1;
		if(!fh.write((const char *)&LABL, sizeof(LABL)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
		if(!fh.write(regions[i].name.c_str(), str_sz+1))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
		if(LABL.size&1)
			if(!fh.write("", 1))
				throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
	}

	// Write markers /////////////////////////////////////////////////////////
	for (size_t i=0; i<markers.size(); ++i) {
		size_t str_sz =		markers[i].name.size();
		LABL.size =			(uint32_t)(sizeof(LABL_HEAD)-sizeof(UNIVERSAL_CHUNK) + str_sz+1);
		LABL.Id =			(uint32_t)(regions.size()+i+1);
		if(!fh.write((const char *)&LABL, sizeof(LABL)))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
		if(!fh.write(markers[i].name.c_str(), str_sz+1))
			throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
		if(LABL.size&1)
			if(!fh.write("", 1))
				throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");
	}

	// Update LIST chunk length //////////////////////////////////////////////
	std::streampos new_sz = fh.tellp();
	fh.seekp(LIST_pos);
	LIST.size = (uint32_t)(new_sz-LIST_pos-sizeof(UNIVERSAL_CHUNK));
	if(!fh.write((const char *)&LIST, sizeof(LIST)))
		throw std::runtime_error(std::string(__FUNCTION__) + ": File write error.");

	return new_sz;
}

#ifdef _WIN32
#include <windows.h>
#elif defined(__linux__)
#include <unistd.h>
#include <sys/types.h>
#endif

std::streampos wav_markers_regions_write_(std::fstream &fh, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions) {
	RIFF_CHUNK riff_head;
	if (!fh.read((char *)&riff_head, sizeof(riff_head)))
		throw std::runtime_error(std::string(__FUNCTION__) + ": Incorrect file format.");

	if (riff_head.name_id != id_RIFF || riff_head.format != id_WAVE)
		throw std::runtime_error(std::string(__FUNCTION__) + ": Unsupported file format: not RIFF-WAVE file.");

	fh.seekg(0, fh.end);
	std::streampos file_size = std::min(fh.tellg(), (std::streampos)(riff_head.size + sizeof(UNIVERSAL_CHUNK)));

	// Delete old markers and regions ////////////////////////////////////////
	std::streampos new_sz = delete_markers_regions_from_file(fh, file_size);

	// Write new markers and regions /////////////////////////////////////////
	new_sz = write_markers_regions_to_file(fh, new_sz, markers, regions);

	// Update RIFF header ////////////////////////////////////////////////////
	riff_head.size = (uint32_t)(new_sz - (std::streampos)sizeof(UNIVERSAL_CHUNK));
	fh.seekp(0, fh.beg);
	fh.write((const char *)&riff_head, sizeof(riff_head));
	fh.seekg(0, fh.end);
	std::streampos real_size = fh.tellg();
	fh.close();

	// Decrease file size ////////////////////////////////////////////////////
	if (riff_head.size + (std::streampos)sizeof(UNIVERSAL_CHUNK) != real_size)
		return new_sz;

	return std::streampos(-1);
}

void wav_markers_regions_write(const char *file_name, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions) {
    std::fstream file_stream(file_name, std::ios_base::in | std::ios_base::out | std::ios_base::binary);
	std::streampos new_sz = wav_markers_regions_write_(file_stream, markers, regions);

	if(new_sz != std::streampos(-1))
	{
#ifdef _WIN32
		HANDLE win_fh = CreateFileA(file_name, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (win_fh == INVALID_HANDLE_VALUE)
			throw std::runtime_error(std::string(__FUNCTION__) + ": Can't shrink file.");
		LARGE_INTEGER win_pos;
		win_pos.QuadPart = new_sz;
		SetFilePointerEx(win_fh, win_pos, NULL, FILE_BEGIN);
		SetEndOfFile(win_fh);
		CloseHandle(win_fh);
#elif defined(__linux__)
		if (truncate(file_name, new_sz) != 0)
			throw std::runtime_error(std::string(__FUNCTION__) + ": Can't truncate file.");
#endif
	}
}

#ifdef _MSC_VER
void wav_markers_regions_write(const wchar_t *file_name, const std::vector<WAV_MARKER> &markers, const std::vector<WAV_REGION> &regions) {
    std::fstream file_stream(file_name, std::ios_base::in | std::ios_base::out | std::ios_base::binary);
	std::streampos new_sz = wav_markers_regions_write_(file_stream, markers, regions);

	if (new_sz != std::streampos(-1))
	{
#ifdef _WIN32
		HANDLE win_fh = CreateFileW(file_name, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (win_fh == INVALID_HANDLE_VALUE)
			throw std::runtime_error(std::string(__FUNCTION__) + ": Can't shrink file.");
		LARGE_INTEGER win_pos;
		win_pos.QuadPart = new_sz;
		SetFilePointerEx(win_fh, win_pos, NULL, FILE_BEGIN);
		SetEndOfFile(win_fh);
		CloseHandle(win_fh);
#elif defined(__linux__)
		truncate(file_name, new_sz);
#endif
	}
}
#endif
