#include <vector>
#include <map>
#include "include/sndfile.hh"

#include "mex.h"

#ifdef MX_API_VER
#if MX_API_VER < 0x07030000
typedef int mwIndex;
#endif
#endif

static const char *info_names[] = {
	"Filename",
	"CompressionMethod",
	"NumChannels",
	"SampleRate",
	"TotalSamples",
	"Duration",
	"BitsPerSample",
	"BitRate",
	"Title",
	"Artist",
	"Comment",
	"Markers",
	"Regions",
	"Error"
};

static const char *marker_names[] = {
	"Position",
	"Name"
};

static const char *region_names[] = {
	"Position",
	"Length",
	"Name"
};

void init_info(mxArray * &info) {
	info = mxCreateStructMatrix(1, 1, sizeof(info_names)/sizeof(info_names[0]), info_names);

	mxSetField(info, 0, "Filename", mxCreateString(""));

	mxSetField(info, 0, "CompressionMethod", mxCreateString(""));

	mxSetField(info, 0, "NumChannels", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "SampleRate", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "TotalSamples", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "Duration", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "BitsPerSample", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "BitRate", mxCreateDoubleMatrix(1, 1, mxREAL));

	mxSetField(info, 0, "Title", mxCreateString(""));

	mxSetField(info, 0, "Artist", mxCreateString(""));

	mxSetField(info, 0, "Comment", mxCreateString(""));

	mxSetField(info, 0, "Markers", mxCreateStructMatrix(0, 1, sizeof(marker_names)/sizeof(marker_names[0]), marker_names));

	mxSetField(info, 0, "Regions", mxCreateStructMatrix(0, 1, sizeof(region_names)/sizeof(region_names[0]), region_names));

	mxSetField(info, 0, "Error", mxCreateString(""));
}

void parse_riff_wav(const char *file_name, mxArray * &info);

void fill_info(const char *file_name, SndfileHandle &snd_file, mxArray * &info) {
	mxDestroyArray(mxGetField(info, 0, "Filename"));
	mxSetField(info, 0, "Filename", mxCreateString(file_name));

	std::map<int, const char*> compress_map;
	compress_map[SF_FORMAT_PCM_S8] =	"PCM signed 8 bit data.";
	compress_map[SF_FORMAT_PCM_16] =	"PCM signed 16 bit data.";
	compress_map[SF_FORMAT_PCM_24] =	"PCM signed 24 bit data.";
	compress_map[SF_FORMAT_PCM_32] =	"PCM signed 32 bit data.";

	compress_map[SF_FORMAT_PCM_U8] =	"PCM unsigned 8 bit data (WAV and RAW only).";

	compress_map[SF_FORMAT_FLOAT] =		"PCM 32-bit float data.";
	compress_map[SF_FORMAT_DOUBLE] =	"PCM 64-bit float data.";

	compress_map[SF_FORMAT_ULAW] =		"U-Law encoded.";
	compress_map[SF_FORMAT_ALAW] =		"A-Law encoded.";
	compress_map[SF_FORMAT_IMA_ADPCM] =	"IMA ADPCM.";
	compress_map[SF_FORMAT_MS_ADPCM] =	"Microsoft ADPCM.";

	compress_map[SF_FORMAT_GSM610] =	"GSM 6.10 encoding.";
	compress_map[SF_FORMAT_VOX_ADPCM] =	"OKI / Dialogix ADPCM.";

	compress_map[SF_FORMAT_G721_32] =	"32kbs G721 ADPCM encoding.";
	compress_map[SF_FORMAT_G723_24] =	"24kbs G723 ADPCM encoding.";
	compress_map[SF_FORMAT_G723_40] =	"40kbs G723 ADPCM encoding.";

	compress_map[SF_FORMAT_DWVW_12] =	"12 bit Delta Width Variable Word encoding.";
	compress_map[SF_FORMAT_DWVW_16] =	"16 bit Delta Width Variable Word encoding.";
	compress_map[SF_FORMAT_DWVW_24] =	"24 bit Delta Width Variable Word encoding.";
	compress_map[SF_FORMAT_DWVW_N] =	"N bit Delta Width Variable Word encoding.";

	compress_map[SF_FORMAT_DPCM_8] =	"8 bit differential PCM (XI only)";
	compress_map[SF_FORMAT_DPCM_16] =	"16 bit differential PCM (XI only)";

	compress_map[SF_FORMAT_VORBIS] =	"Xiph Vorbis encoding.";

	const char *cmprs_type = compress_map[snd_file.format()&0xFFFF];
	if(cmprs_type) {
		mxDestroyArray(mxGetField(info, 0, "CompressionMethod"));
		mxSetField(info, 0, "CompressionMethod", mxCreateString(cmprs_type));
	}

	mxGetPr(mxGetField(info, 0, "NumChannels"))[0] = snd_file.channels();

	mxGetPr(mxGetField(info, 0, "SampleRate"))[0] = snd_file.samplerate();

	mxGetPr(mxGetField(info, 0, "TotalSamples"))[0] = (double)snd_file.frames();

	mxGetPr(mxGetField(info, 0, "Duration"))[0] = (double)snd_file.frames()/snd_file.samplerate();

	parse_riff_wav(file_name, info);
}

#include <stdio.h>

typedef char				lsf_int8_t;
typedef short				lsf_int16_t;
typedef int					lsf_int32_t;
typedef __int64				lsf_int64_t;
typedef unsigned char		lsf_uint8_t;
typedef unsigned short		lsf_uint16_t;
typedef unsigned int		lsf_uint32_t;
typedef unsigned __int64	lsf_uint64_t;

#pragma pack(push, 1)

struct UNIVERSAL_CHUNK {
	union {
		struct {
			lsf_uint32_t	chunk_id;
			lsf_uint32_t	size;
		};
		void *next_ptr;
	};
};

struct RIFF_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	format;
};

struct FMT_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint16_t	sound_format;
	lsf_uint16_t	num_channels;
	lsf_uint32_t	sample_rate;
	lsf_uint32_t	byte_rate;
	lsf_uint16_t	block_align;
	lsf_uint16_t	bits_per_sample;
	lsf_uint16_t	extra_bytes;
};

struct ALL_WAVE_HEAD{
	RIFF_CHUNK	RIFF;
	FMT_CHUNK	FMT;
};

struct FACT_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	samples_num;
};

struct DATA_CHUNK:UNIVERSAL_CHUNK{
};

struct CUE_TBL{
	lsf_uint32_t	Id;
	lsf_uint32_t	position;
	lsf_uint32_t	fcc_chunk;
	lsf_uint32_t	chunk_start;
	lsf_uint32_t	block_start;
	lsf_uint32_t	sample_offset;
};

struct CUE_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	table_size;
//	CUE_TBL			table[table_size];
};

struct LIST_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	type;
};

struct LTXT_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	Id;
	lsf_uint32_t	length;
	lsf_uint32_t	purpose;
	lsf_uint16_t	country;
	lsf_uint16_t	language;
	lsf_uint16_t	dialect;
	lsf_uint16_t	code_page;
};

struct LABL_CHUNK:UNIVERSAL_CHUNK{
	lsf_uint32_t	Id;
	char			name[1];
};

enum CHUNK_IDs{
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

lsf_uint64_t chunk_search(lsf_uint32_t ch_id, FILE *fh, lsf_uint64_t file_sz, lsf_uint64_t start_pos=sizeof(RIFF_CHUNK)){
	if(fseek(fh, (long)start_pos, SEEK_SET))
		throw std::runtime_error("File seek error.");
	lsf_uint64_t cur_pos=start_pos;
	UNIVERSAL_CHUNK cur_chunk;
	cur_chunk.size=0;

	while(cur_pos+cur_chunk.size+sizeof(cur_chunk)<=file_sz) {
		cur_pos+=cur_chunk.size;
		if(fseek(fh, cur_chunk.size, SEEK_CUR))
			throw std::runtime_error("File seek error.");

		if(fread(&cur_chunk, sizeof(cur_chunk), 1, fh)!=1)
			throw std::runtime_error("Read data from file error.");

		if(cur_chunk.chunk_id==ch_id)
			return cur_pos;

		cur_pos+=sizeof(cur_chunk);
		cur_chunk.size = (cur_chunk.size + 1) & (lsf_uint32_t)-2;
	}
	return (lsf_uint64_t)-1;
}

struct FILE_HANDLE {
	FILE *fh;
	FILE_HANDLE(FILE *fh_=NULL) : fh(fh_) {}
	~FILE_HANDLE() {
		if(fh)
			fclose(fh);
	}
	FILE_HANDLE & operator = (FILE * &fh_) {
		fh = fh_;
		return *this;
	}
	operator bool () const {
		return fh!=NULL;
	}
	operator FILE *() {
		return fh;
	}
};

struct REGION_INFO {
	REGION_INFO() {}
	REGION_INFO(lsf_uint32_t position_,
				lsf_uint32_t length_,
				const char *name_) :
		position(position_), length(length_), name(name_) {
	}

	lsf_uint32_t position;
	lsf_uint32_t length;
	const char *name;
};

void parse_riff_wav(const char *file_name, mxArray * &info) {
	FILE_HANDLE fh(fopen(file_name, "rb"));
	if(!fh)
		throw std::runtime_error("Can't open file.");

	// Determine file size in bytes
	if(fseek(fh, 0, SEEK_END))
		throw std::runtime_error("File seek error.");
	lsf_uint64_t file_sz = ftell(fh);
	if(file_sz == (lsf_uint64_t)-1)
		throw std::runtime_error("Get file size error.");
	if(fseek(fh, 0, SEEK_SET))
		throw std::runtime_error("File seek error.");

	// Not a RIFF - WAVE file
	if(file_sz < sizeof(RIFF_CHUNK))
		return;

	RIFF_CHUNK riff_ch;
	if(fread(&riff_ch, sizeof(riff_ch), 1, fh)!=1)
		throw std::runtime_error("Can't read RIFF header.");

	// Not a RIFF - WAVE file
	if(riff_ch.chunk_id!=id_RIFF || riff_ch.format!=id_WAVE || chunk_search(id_fmt, fh, file_sz)==(lsf_uint64_t)-1)
		return;

	if(fseek(fh, -(long)(sizeof(UNIVERSAL_CHUNK)), SEEK_CUR))
		throw std::runtime_error("File seek error.");
	FMT_CHUNK fmt_ch;
	if(fread(&fmt_ch, sizeof(fmt_ch), 1, fh)!=1)
		throw std::runtime_error("Can't read fmt chunk.");

	mxGetPr(mxGetField(info, 0, "BitsPerSample"))[0] = fmt_ch.bits_per_sample;

	mxGetPr(mxGetField(info, 0, "BitRate"))[0] = fmt_ch.byte_rate*8;

	if(chunk_search(id_cue, fh, file_sz)==(lsf_uint64_t)-1)
		return;
	if(fseek(fh, -(long)(sizeof(UNIVERSAL_CHUNK)), SEEK_CUR))
		throw std::runtime_error("File seek error.");
	CUE_CHUNK cue_ch;
	if(fread(&cue_ch, sizeof(cue_ch), 1, fh)!=1)
		throw std::runtime_error("Can't read cue chunk.");

	if(!cue_ch.table_size)
		return;
	std::vector<CUE_TBL> cue_table(cue_ch.table_size);
	if(fread(&cue_table[0], sizeof(cue_table[0]), cue_table.size(), fh)!=cue_table.size())
		throw std::runtime_error("Can't read cue table.");

	LIST_CHUNK LIST_ch;
	lsf_uint64_t list_pos=sizeof(RIFF_CHUNK);
	do {
		list_pos=chunk_search(id_LIST, fh, file_sz, list_pos);
		if(list_pos==(lsf_uint64_t)-1)
			return;
		if(fseek(fh, -(long)(sizeof(UNIVERSAL_CHUNK)), SEEK_CUR))
			throw std::runtime_error("File seek error.");
		if(fread(&LIST_ch, sizeof(LIST_ch), 1, fh)!=1)
			throw std::runtime_error("Can't read LIST chunk.");
		list_pos+=LIST_ch.size+sizeof(UNIVERSAL_CHUNK);
	} while(LIST_ch.type!=id_adtl);

	std::vector<char> LIST_data(LIST_ch.size-4);
	if(fread(&LIST_data[0], sizeof(LIST_data[0]), LIST_data.size(), fh)!=LIST_data.size())
		throw std::runtime_error("Can't read LIST chunk data.");

	LTXT_CHUNK *ltxt_head=NULL, *ltxt_last=NULL;
	LABL_CHUNK *labl_head=NULL, *labl_last=NULL;

	UNIVERSAL_CHUNK *chunk=(UNIVERSAL_CHUNK *)&LIST_data[0];
	for(size_t i=0; i<LIST_data.size(); i+=(chunk->size+sizeof(UNIVERSAL_CHUNK)+1)&-2, chunk=(UNIVERSAL_CHUNK *)&LIST_data[i]) {
		switch(chunk->chunk_id){
		case id_ltxt:
			if(!ltxt_head){
				ltxt_head=ltxt_last=(LTXT_CHUNK *)chunk;
			}
			else{
				ltxt_last->next_ptr=chunk;
				ltxt_last=(LTXT_CHUNK *)chunk;
			}
			break;
		case id_labl:
			if(!labl_head){
				labl_head=labl_last=(LABL_CHUNK *)chunk;
			}
			else{
				labl_last->next_ptr=chunk;
				labl_last=(LABL_CHUNK *)chunk;
			}
			break;
		}
	}
	if(ltxt_last)
		ltxt_last->next_ptr=NULL;
	if(labl_last)
		labl_last->next_ptr=NULL;

	std::vector<REGION_INFO> reg_collector;

	ltxt_last=ltxt_head;
	while(ltxt_last){
		LABL_CHUNK *labl_cur=labl_head;
		labl_last=NULL;
		while((labl_cur)&&(ltxt_last->Id!=labl_cur->Id)){
			labl_last=labl_cur;
			labl_cur=(LABL_CHUNK *)labl_cur->next_ptr;
		}
		if(labl_cur){
			size_t i=0;
			while((i<cue_table.size())&&(ltxt_last->Id!=cue_table[i].Id))
				i++;
			if(i<cue_table.size()){
				reg_collector.push_back(REGION_INFO(cue_table[i].position, ltxt_last->length, labl_cur->name));
				if(!labl_last)
					labl_head=(LABL_CHUNK *)labl_head->next_ptr;
				else
					labl_last->next_ptr=labl_cur->next_ptr;
				cue_table[i].fcc_chunk=0;
			}
		}
		ltxt_last=(LTXT_CHUNK *)ltxt_last->next_ptr;
	}

	// Convert regions to MATLAB format
	if(reg_collector.size()) {
		mxDestroyArray(mxGetField(info, 0, "Regions"));
		mxArray *reg = mxCreateStructMatrix(reg_collector.size(), 1, sizeof(region_names)/sizeof(region_names[0]), region_names);
		mxSetField(info, 0, "Regions", reg);

		std::vector<REGION_INFO>::const_iterator reg_it=reg_collector.begin();
		for(size_t i=0, ie=reg_collector.size(); i<ie; ++i, ++reg_it) {
			mxArray *val = mxCreateDoubleMatrix(1, 1, mxREAL);
			mxGetPr(val)[0] = (double)reg_it->position+1;
			mxSetField(reg, i, "Position", val);

			val = mxCreateDoubleMatrix(1, 1, mxREAL);
			mxGetPr(val)[0] = reg_it->length;
			mxSetField(reg, i, "Length", val);

			mxSetField(reg, i, "Name", mxCreateString(reg_it->name));
		}
	}

	size_t marks_num=0;
	for(std::vector<CUE_TBL>::const_iterator cue_it=cue_table.begin(), cue_ie=cue_table.end(); cue_it!=cue_ie; ++cue_it)
		if(cue_it->fcc_chunk==id_data)
			++marks_num;

	if(marks_num) {
		mxDestroyArray(mxGetField(info, 0, "Markers"));
		mxArray *marker = mxCreateStructMatrix(marks_num, 1, sizeof(marker_names)/sizeof(marker_names[0]), marker_names);
		mxSetField(info, 0, "Markers", marker);

		std::vector<CUE_TBL>::const_iterator cue_it=cue_table.begin();
		for(size_t i=0, ie=cue_table.size(), mark_ind=0; i<ie; ++i, ++cue_it) {
			if(cue_it->fcc_chunk!=id_data)
				continue;

			mxArray *val = mxCreateDoubleMatrix(1, 1, mxREAL);
			mxGetPr(val)[0] = (double)cue_it->position+1;
			mxSetField(marker, mark_ind, "Position", val);

			LABL_CHUNK *labl_cur=labl_head;
			labl_last=NULL;
			while((labl_cur)&&(cue_it->Id!=labl_cur->Id)){
				labl_last=labl_cur;
				labl_cur=(LABL_CHUNK *)labl_cur->next_ptr;
			}
			if(labl_cur){
				mxSetField(marker, mark_ind, "Name", mxCreateString(labl_cur->name));
				if(!labl_last)
					labl_head=(LABL_CHUNK *)labl_head->next_ptr;
				else
					labl_last->next_ptr=labl_cur->next_ptr;
			}
			else
				mxSetField(marker, mark_ind, "Name", mxCreateString(""));

			++mark_ind;
		}
	}
};
