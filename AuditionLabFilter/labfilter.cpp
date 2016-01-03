/*
LAB File Filter for Cool Edit/Adobe Audition
Copyright © 2014 Andrei Davydov
*/

#include <windows.h>
#include "api/filters.h"
#include <sndfile.hh>
#include <fstream>
#include <sstream>
#include <iterator>
#include <vector>
#include <string>
#include <memory>
#include <limits>
#include <cmath>
#include <cstdint>
/*
#include <commctrl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <flac/all.h>
#include "resource.h"
*/
#define CHUNKSIZE	(256*1024)

std::string find_signal_file(LPSTR filename);
std::string find_labels_file(LPSTR filename);
struct FILTER_IO {
	bool open_read(LPSTR filename) {
		labels_fh.open(labels_fname=find_labels_file(filename), std::ios::in);
		signal_fh = SndfileHandle(find_signal_file(filename));
		return signal_fh && signal_fh.frames();
	}

	bool open_write(LPSTR filename, int chans, int srate) {
		labels_fh.open(labels_fname=find_labels_file(filename), std::ios::out | std::ios::trunc);
		if(!labels_fh)
			return false;

		int format=0;
		std::string signal_fname = find_signal_file(filename);
		{
			SndfileHandle tmp_fh(signal_fname);
			format = tmp_fh.format();
			if(!format) {
				char cur_path[_MAX_PATH], cur_drv[_MAX_DRIVE], cur_dir[_MAX_DIR], cur_name[_MAX_FNAME];
				_splitpath(filename, cur_drv, cur_dir, cur_name, NULL);
				_makepath(cur_path, cur_drv, cur_dir, cur_name, "flac");
				signal_fname = cur_path;
				format = SF_FORMAT_FLAC | SF_FORMAT_PCM_16;
			}
		}

		if(!(signal_fh = SndfileHandle(signal_fname, SFM_WRITE, format, chans, srate)))
			return false;

		if((format&SF_FORMAT_TYPEMASK) == SF_FORMAT_FLAC) {
			double compression_level = 8;
			signal_fh.command(SFC_SET_COMPRESSION_LEVEL, &compression_level, sizeof(compression_level));
		}
		return true;
	}

	struct REGION {
		REGION(uint32_t	pos_=0, uint32_t len_=0, uint32_t name_id_=0, const char *name_str_="") : pos(pos_), len(len_), name_id(name_id_), name_str(name_str_) {}
		uint32_t	pos;
		uint32_t	len;
		uint32_t	name_id;
		std::string	name_str;
	};
	std::fstream  labels_fh;
	std::string   labels_fname;
	std::vector<REGION> lab_data;

	SndfileHandle signal_fh;
	std::string   signal_fname;
	WORD wrBPS;
};

std::string ANSItoUTF8(const char *ansi);
std::string UTF8toANSI(const char *utf8);

DWORD fill_cue_info (const FILTER_IO *filter, SPECIALDATA *psp);
DWORD fill_ltxt_info(const FILTER_IO *filter, SPECIALDATA *psp);
DWORD fill_labl_info(const FILTER_IO *filter, SPECIALDATA *psp);

DWORD proc_cue_info (FILTER_IO *filter, const char *data, size_t data_size);
DWORD proc_ltxt_info(FILTER_IO *filter, const char *data, size_t data_size);
DWORD proc_labl_info(FILTER_IO *filter, const char *data, size_t data_size);

//////////////////////////////////////////////////////////////////////
// REQUIRED COOL EDIT FILTER FUNCTIONS
//////////////////////////////////////////////////////////////////////

__declspec(dllexport) short FAR PASCAL QueryCoolFilter(COOLQUERY* cq)
{
	memset(cq,0,sizeof(*cq));
	strcpy(cq->szName,"LAB");		
	strcpy(cq->szCopyright,"Labeling filter 1.0.2");
	strcpy(cq->szExt,"LAB");
	strcpy(cq->szExt2,"FLA");
	strcpy(cq->szExt3,"FL*");
	cq->lChunkSize=CHUNKSIZE; 
	cq->dwFlags=QF_CANLOAD|QF_CANSAVE|QF_RATEADJUSTABLE/*|QF_HASOPTIONSBOX*/|QF_CANDO32BITFLOATS|QF_READSPECIALLAST|QF_WRITESPECIALLAST;
	cq->Stereo8=0xFF;
	cq->Stereo16=0xFF;
	cq->Stereo32=0xFF;
	cq->Mono8=0xFF;
	cq->Mono16=0xFF;
	cq->Mono32=0xFF;
	return C_VALIDLIBRARY;
}

__declspec(dllexport) BOOL FAR PASCAL FilterUnderstandsFormat(LPSTR filename)
{
	FILTER_IO filter;
	return filter.open_read(filename);
}


//////////////////////////////////////////////////////////////////////
// REQUIRED COOL EDIT FILTER FUNCTIONS - READING
//////////////////////////////////////////////////////////////////////
__declspec(dllexport) HANDLE FAR PASCAL OpenFilterInput(LPSTR filename,long* lRate,WORD* wBPS,WORD* wChannels,HWND hWnd,long* lChunkSize)
{
	std::unique_ptr<FILTER_IO> filter(new FILTER_IO);
	if(!filter->open_read(filename))
		return 0;

	*lRate = filter->signal_fh.samplerate();
	*wBPS = 16;
	*wChannels = filter->signal_fh.channels();
	*lChunkSize= CHUNKSIZE;

	FILTER_IO *ret = filter.release();
	return ret;
}

__declspec(dllexport) DWORD FAR PASCAL FilterGetFileSize(HANDLE hInput)
{
	FILTER_IO *filter=(FILTER_IO *)hInput;
	__int64 size=(__int64)filter->signal_fh.frames()*2*filter->signal_fh.channels();
	if(size>std::numeric_limits<DWORD>::max())
		size &= -(long)(2*filter->signal_fh.channels());
	return (DWORD)size;
}

__declspec(dllexport) DWORD FAR PASCAL ReadFilterInput(HANDLE hInput, unsigned char* buf, long lBytes)
{
	FILTER_IO *filter=(FILTER_IO *)hInput;
	if(!filter)
		return 0;
	return (DWORD)(filter->signal_fh.read((short *)buf, lBytes/2)*2);
}

__declspec(dllexport) void FAR PASCAL CloseFilterInput(HANDLE hInput)
{
	FILTER_IO *filter=(FILTER_IO *)hInput;
	if(!filter)
		return;
	delete filter;
}

//////////////////////////////////////////////////////////////////////
// REQUIRED COOL EDIT FILTER FUNCTIONS - WRITING
//////////////////////////////////////////////////////////////////////

__declspec(dllexport) void FAR PASCAL GetSuggestedSampleType(long* lRate, WORD* wBPS, WORD *wChannels)
{
	*wBPS=0;
	*lRate=0;
	*wChannels=0;
}

__declspec(dllexport) HANDLE FAR PASCAL OpenFilterOutput(LPSTR filename,
														 long samprate,
														 WORD BPS,
														 WORD channels,
														 DWORD lSize,
														 long* lChunkSize,
														 DWORD options)
{
	std::unique_ptr<FILTER_IO> filter(new FILTER_IO);

	if(!filter->open_write(filename, channels, samprate))
		return 0;
	filter->wrBPS = BPS;
	*lChunkSize= CHUNKSIZE;

	return filter.release();
}

__declspec(dllexport) DWORD FAR PASCAL WriteFilterOutput(HANDLE hOutput, BYTE* pBuf, long lBytes)
{
	FILTER_IO *filter=(FILTER_IO *)hOutput;
	if(!filter || !lBytes)
		return 0;

	switch(filter->wrBPS) {
	case 8: {
		std::vector<short>	tmp_buf(lBytes);
		short *out_it = &tmp_buf[0];
		for(const BYTE *it=pBuf, *ie=(const BYTE *)(char *)(pBuf+lBytes); it!=ie; ++it, ++out_it)
			*out_it = ((short)(*it)-128)<<8;

		return (DWORD)filter->signal_fh.write(&tmp_buf[0], tmp_buf.size());
			}
	case 16:
		return (DWORD)(filter->signal_fh.write((const short *)pBuf, lBytes/2)*2);
	case 32: {
		std::vector<float>	tmp_buf(lBytes/4);
		float *out_it = &tmp_buf[0];
		for(const float *it=(const float *)pBuf, *ie=(const float *)(char *)(pBuf+lBytes); it!=ie; ++it, ++out_it)
			*out_it = *it/32768;

		return (DWORD)(filter->signal_fh.write(&tmp_buf[0], tmp_buf.size())*4);
			 }
	}
	return 0;
}

__declspec(dllexport) void FAR PASCAL CloseFilterOutput(HANDLE hOutput)
{
	FILTER_IO *filter=(FILTER_IO *)hOutput;
	if(!filter)
		return;
	delete filter;
}

//////////////////////////////////////////////////////////////////////
// OPTIONAL COOL EDIT FILTER FUNCTIONS
//////////////////////////////////////////////////////////////////////

__declspec(dllexport) DWORD FAR PASCAL FilterOptionsString(HANDLE hInput, LPSTR lpszString)
{
	FILTER_IO *filter=(FILTER_IO*)hInput;
	if(!filter)
		return 0;

	strcpy(lpszString, filter->signal_fname.c_str());
	return 0;
}

__declspec(dllexport) DWORD FAR PASCAL FilterGetOptions(HWND hWnd,
														HINSTANCE hInst,
														long lSamprate,
														WORD wChannels,
														WORD wBPS,
 														DWORD dwOptions)
{
/*	FARPROC lpfnDialogMsgProc=GetProcAddress(hInst,(LPCSTR)"DIALOGMsgProc");
	DWORD nDialogReturn=(DWORD)DialogBoxParam((HINSTANCE)hInst,(LPCSTR)MAKEINTRESOURCE(IDD_CONFIG),hWnd,(DLGPROC)lpfnDialogMsgProc,dwOptions);
	if(nDialogReturn>0)
		return nDialogReturn;
	else
		return dwOptions;*/
	return 0;
}

__declspec(dllexport) DWORD FAR PASCAL FilterOptions(HANDLE hInput)
{
	return 0;
}

__declspec(dllexport) DWORD FAR PASCAL FilterWriteSpecialData(HANDLE hOutput, LPCSTR szListType, LPCSTR szType, char * pData, DWORD dwSize)
{
	FILTER_IO *filter=(FILTER_IO*)hOutput;
	if(!filter)
		return 0;

	if(!strcmp(szListType,"WAVE") && !strcmp(szType,"cue "))
		return proc_cue_info(filter, pData, dwSize);

	if(!strcmp(szListType,"adtl") && !strcmp(szType,"ltxt"))
		return proc_ltxt_info(filter, pData, dwSize);

	if(!strcmp(szListType,"adtl") && !strcmp(szType,"labl"))
		return proc_labl_info(filter, pData, dwSize);

	return 0;
}

void read_seg(FILTER_IO *filter);
void read_lab(FILTER_IO *filter);

__declspec(dllexport) DWORD FAR PASCAL FilterGetFirstSpecialData(HANDLE hInput,	SPECIALDATA * psp)
{
	FILTER_IO *filter=(FILTER_IO *)hInput;
	if(!filter)
		return 0;


	char cur_ext[_MAX_EXT];
	_splitpath(filter->labels_fname.c_str(), NULL, NULL, NULL, cur_ext);

	if(!stricmp(cur_ext,".seg"))
		read_seg(filter);
	else
		read_lab(filter);

	if(filter->lab_data.empty())
		return 0;

	return fill_cue_info(filter, psp);
}

void read_seg(FILTER_IO *filter) {
	std::fstream &fh = filter->labels_fh;

	enum {unknown, parameters, labels} section_type = unknown;
	size_t BYTE_PER_SAMPLE = 2;
	size_t N_CHANNEL = filter->signal_fh.channels();

	struct SEG_LABEL {
		SEG_LABEL() : pos(0), lvl(0) {}
		SEG_LABEL(uint32_t pos_, uint32_t lvl_, char const * name_) : pos(pos_), lvl(lvl_), name(name_) {}
		uint32_t	pos;
		uint32_t	lvl;
		std::string	name;
	};
	std::vector<SEG_LABEL> seg_labels;

	while(fh) {
		std::string cur_line;
		std::getline(fh, cur_line);

		if(cur_line.empty())
			continue;
		if(cur_line.front()=='[' && cur_line.back()==']') {
			if(!cur_line.compare("[PARAMETERS]"))
				section_type = parameters;
			else if(!cur_line.compare("[LABELS]"))
				section_type = labels;
			else
				section_type = unknown;
			continue;
		}
		if(section_type==unknown)
			continue;

		char const str_param_fs[] = "SAMPLING_FREQ=";
		char const str_param_bps[]= "BYTE_PER_SAMPLE=";
		char const str_param_ch[] = "N_CHANNEL=";
		if(section_type==parameters) {
			if(!cur_line.compare(0, sizeof(str_param_fs)-1, str_param_fs)) {
				cur_line.erase(cur_line.begin(), cur_line.begin()+sizeof(str_param_fs)-1);
				if(std::stol(cur_line) != filter->signal_fh.samplerate())
					return; // Error -- wrong sampling frequency
			}
			if(!cur_line.compare(0, sizeof(str_param_bps)-1, str_param_bps)) {
				cur_line.erase(cur_line.begin(), cur_line.begin()+sizeof(str_param_bps)-1);
				BYTE_PER_SAMPLE = std::stol(cur_line);
				if(BYTE_PER_SAMPLE<1 || BYTE_PER_SAMPLE>8)
					return; // Error -- wrong bytes per sample value
			}
			if(!cur_line.compare(0, sizeof(str_param_ch)-1, str_param_ch)) {
				cur_line.erase(cur_line.begin(), cur_line.begin()+sizeof(str_param_ch)-1);
				if(std::stol(cur_line) != N_CHANNEL)
					return; // Error -- wrong sampling frequency
			}
		}

		if(section_type==labels) {
			char *cur_str = (char *)cur_line.c_str();

			long long cur_pos = strtol(cur_str, &cur_str, 10);
			if(!*cur_str)
				continue;

			cur_str = strpbrk(cur_str, "0123456789");
			if(!cur_str)
				continue;

			long cur_lvl = strtol(cur_str, &cur_str, 10);
			if(*cur_str)
				++cur_str;

			seg_labels.push_back(SEG_LABEL((uint32_t)(cur_pos/(BYTE_PER_SAMPLE*N_CHANNEL)), cur_lvl, cur_str));
		}
	}

	if(seg_labels.empty())
		return;

	for(std::vector<SEG_LABEL>::const_iterator si=seg_labels.begin(), se=seg_labels.end(); si!=se-1; ++si) {
		std::vector<SEG_LABEL>::const_iterator sj=si+1;
		for(; (sj!=se) && (si->lvl!=sj->lvl); ++sj)
			;
		if(sj==se)
			continue;
		if(si->name.empty() && !sj->name.empty())
			continue;
		std::string cur_name = "L";
		cur_name += std::to_string((unsigned long long)(si->lvl));
		cur_name += "_";
		cur_name += si->name;
		filter->lab_data.push_back(FILTER_IO::REGION(si->pos, sj->pos-si->pos, filter->lab_data.size()+1, cur_name.c_str()));
	}
}

void read_lab(FILTER_IO *filter) {
	std::fstream &fh = filter->labels_fh;

	long fs = filter->signal_fh.samplerate();
	enum {unknown, HTK, sec, msec} time_format;

	bool is_first_line = true;
	time_format = HTK;
	while(fh) {
		std::string cur_line;
		std::getline(fh, cur_line);
		std::istringstream sstr(cur_line);

		std::string	pos_beg_str, pos_end_str;
		sstr >> pos_beg_str >> pos_end_str >> std::ws;
		if(is_first_line && !pos_beg_str.compare("MillisecondsPerFrame:")) {
			time_format = msec;
			break;
		}
		if (pos_beg_str.find_first_of('.')!=std::string::npos ||
			pos_end_str.find_first_of('.')!=std::string::npos) {
			time_format = sec;
			break;
		}

		is_first_line = false;
	}

	fh.clear();
	fh.seekg(0, fh.beg);
	while(fh) {
		std::string cur_line;
		std::getline(fh, cur_line);
		std::istringstream sstr(cur_line);
		uint32_t pos_smpl_beg, pos_smpl_end;

		switch(time_format) {
		case HTK: { // STEL format
			uint64_t	pos_max=std::numeric_limits<uint64_t>::max();
			uint64_t	pos_htk_beg=pos_max, pos_htk_end=pos_max;
			sstr >> pos_htk_beg >> pos_htk_end >> std::ws;

			if(pos_htk_beg==pos_max || pos_htk_end==pos_max)
				continue;

			pos_smpl_beg = (uint32_t)((pos_htk_beg*fs+5000000)/10000000);
			pos_smpl_end = (uint32_t)((pos_htk_end*fs+5000000)/10000000);
				  }
			break;

		case sec: { // ATR_BLIZZARD2007 format
			double		pos_max = std::numeric_limits<double>::max();
			double		pos_sec_beg=pos_max, pos_sec_end=pos_max;
			sstr >> pos_sec_beg >> pos_sec_end >> std::ws;

			if(pos_sec_beg==pos_max || pos_sec_end==pos_max)
				continue;

			pos_smpl_beg = (uint32_t)(pos_sec_beg*fs+0.5);
			pos_smpl_end = (uint32_t)(pos_sec_end*fs+0.5);
				  }
			break;

		case msec: { // Ruslana format
			double		pos_max = std::numeric_limits<double>::max();
			double		pos_msec_beg=pos_max, pos_msec_end=pos_max;
			sstr >> pos_msec_beg >> pos_msec_end >> std::ws;

			if(pos_msec_beg==pos_max || pos_msec_end==pos_max)
				continue;

			pos_smpl_beg = (uint32_t)(pos_msec_beg*fs/1000.0+0.5);
			pos_smpl_end = (uint32_t)(pos_msec_end*fs/1000.0+0.5);
				   }
			break;
		}

		std::getline(sstr, cur_line);
		filter->lab_data.push_back(FILTER_IO::REGION(pos_smpl_beg, pos_smpl_end-pos_smpl_beg, filter->lab_data.size()+1, UTF8toANSI(cur_line.c_str()).c_str()));
	}
}

__declspec(dllexport) DWORD FAR PASCAL FilterGetNextSpecialData(HANDLE hInput, SPECIALDATA * psp)
{
	FILTER_IO *filter = (FILTER_IO *)hInput;
	if(!filter)
		return 0;

	if(psp->hSpecialData == (HANDLE)1)
		return fill_ltxt_info(filter,psp);

	if(psp->hSpecialData == (HANDLE)2)
		return fill_labl_info(filter,psp);

	return 0;
}

__declspec(dllexport) BOOL FAR PASCAL DIALOGMsgProc(HWND hWndDlg, UINT Message, WPARAM wParam, LPARAM lParam)
{
/*	switch(Message)
	{
	case WM_INITDIALOG:
		{
			SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETRANGEMIN,0,0);
			SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETRANGEMAX,0,8);
			SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETTICFREQ,1,0);
			SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETPAGESIZE,0,1);
			WORD mode=lParam-1;
			if(mode>8)
				SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETPOS,1,DEFAULTMODE);
			else
				SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_SETPOS,1,mode);
		}
		return 1;
	case WM_CLOSE:
		PostMessage(hWndDlg,WM_COMMAND,IDCANCEL,0);
		return 1;
	case WM_NOTIFY:
		{
			LPNMHDR pnmh=(LPNMHDR)lParam;
			if(pnmh->idFrom==IDC_QUALITYSLIDER)
			{
				char buffer[2]="";
				int pos=SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_GETPOS,0,0);
				itoa(pos,buffer,10);
				SetDlgItemText(hWndDlg,IDC_QUALITY,buffer);
				return 1;
			}
		}
		break;
	case WM_COMMAND:
		switch(LOWORD(wParam))
		{
		case IDOK:
			EndDialog(hWndDlg,SendDlgItemMessage(hWndDlg,IDC_QUALITYSLIDER,TBM_GETPOS,0,0)+1);
			return 1;
		case IDCANCEL:
			EndDialog(hWndDlg,0);
			return 1;
		}
 	} */
	return 0;
}


//////////////////////////////////////////////////////////////////////////
// IO functions
//////////////////////////////////////////////////////////////////////////
std::string find_signal_file(LPSTR filename) {
	{
		SndfileHandle file(filename);
		if(file && file.frames())
			return std::string(filename);
	}

	char cur_path[_MAX_PATH], cur_drv[_MAX_DRIVE], cur_dir[_MAX_DIR], cur_name[_MAX_FNAME], cur_ext[_MAX_EXT];
	_splitpath(filename, cur_drv, cur_dir, cur_name, NULL);

	{
		_makepath(cur_path, cur_drv, cur_dir, cur_name, "flac");
		SndfileHandle file(cur_path);
		if(file && file.frames())
			return std::string(cur_path);
	}

	{
		_makepath(cur_path, cur_drv, cur_dir, cur_name, "fla");
		SndfileHandle file(cur_path);
		if(file && file.frames())
			return std::string(cur_path);
	}

	{
		_makepath(cur_path, cur_drv, cur_dir, cur_name, "wav");
		SndfileHandle file(cur_path);
		if(file && file.frames())
			return std::string(cur_path);
	}

	WIN32_FIND_DATAA find_data;
	size_t name_len = strlen(cur_name);
	cur_name[name_len]='*';
	cur_name[name_len+1]='\0';
	_makepath(cur_path, cur_drv, cur_dir, cur_name, "*");
	HANDLE hFind = FindFirstFileA(cur_path, &find_data);
	if(hFind==INVALID_HANDLE_VALUE)
		return std::string();

	do {
		_splitpath(find_data.cFileName, NULL, NULL, cur_name, cur_ext);
		_makepath(cur_path, cur_drv, cur_dir, cur_name, cur_ext);
		SndfileHandle file(cur_path);
		if(file && file.frames())
			break;
	}
	while(FindNextFileA(hFind, &find_data));
	FindClose(hFind);

	return std::string(cur_path);
}

std::string find_labels_file(LPSTR filename) {
	SndfileHandle file(filename);
	if(!(file && file.frames()))
		return std::string(filename);

	char cur_path[_MAX_PATH], cur_drv[_MAX_DRIVE], cur_dir[_MAX_DIR], cur_name[_MAX_FNAME]/*, cur_ext[_MAX_EXT]*/;
	_splitpath(filename, cur_drv, cur_dir, cur_name, NULL);

	{
		_makepath(cur_path, cur_drv, cur_dir, cur_name, "lab");
		std::ifstream fh(cur_path);
		if(fh)
			return std::string(cur_path);
	}

	{
		_makepath(cur_path, cur_drv, cur_dir, cur_name, "seg");
		std::ifstream fh(cur_path);
		if(fh)
			return std::string(cur_path);
	}

	return std::string();
}

//////////////////////////////////////////////////////////////////////
// String functions
//////////////////////////////////////////////////////////////////////

std::string ANSItoUTF8(const char *ansi) {
	int i=MultiByteToWideChar(CP_ACP,MB_PRECOMPOSED,ansi,-1,0,0);
	if(!i)
		return std::string();

	std::vector<WCHAR> wBuf(i+1);
	MultiByteToWideChar(CP_ACP,MB_PRECOMPOSED,ansi,-1,&wBuf[0],i);

	if(!(i=WideCharToMultiByte(CP_UTF8,0,&wBuf[0],-1,0,0,0,0)))
		return std::string();

	std::vector<char> buf(i+1);
	WideCharToMultiByte(CP_UTF8,0,&wBuf[0],-1,&buf[0],i,0,0);

	std::string ret(&buf[0]);
	return ret;
}

std::string UTF8toANSI(const char *utf8) {
	int i=MultiByteToWideChar(CP_UTF8,0,utf8,-1,0,0);
	if(!i)
		return std::string();

	std::vector<WCHAR> wBuf(i+1);
	MultiByteToWideChar(CP_UTF8,0,utf8,-1,&wBuf[0],i);

	if(!(i=WideCharToMultiByte(CP_ACP,0,&wBuf[0],-1,0,0,0,0)))
		return std::string();

	std::vector<char> buf(i+1);
	WideCharToMultiByte(CP_ACP,0,&wBuf[0],-1,&buf[0],i,0,0);

	std::string ret(&buf[0]);
	return ret;
}


//////////////////////////////////////////////////////////////////////////
// Segmentation parsing functions
//////////////////////////////////////////////////////////////////////////
#pragma pack(push, 1)
struct CUEPOINT {
	uint32_t	name_id;
	uint32_t	position;
};

struct LTXTPOINT {
	uint32_t	ltxt_len;
	uint32_t	name_id;
	uint32_t	cue_length;
	uint32_t	purpose;
};

struct LABLPOINT {
	uint32_t	name_id;
	char		name_str[1];
};
#pragma pack(pop)

DWORD fill_cue_info (const FILTER_IO *filter, SPECIALDATA *psp){
	try {
		memset(psp, 0, sizeof(*psp));

		psp->hSpecialData = (HANDLE)1;

		const std::vector<FILTER_IO::REGION> &lab=filter->lab_data;
		psp->dwExtra= lab.size();
		psp->dwSize = lab.size()*sizeof(CUEPOINT);
		strcpy(psp->szListType,"WAVE");
		strcpy(psp->szType,    "cue ");

		if(!(psp->hData = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT, psp->dwSize)))
			throw std::runtime_error("GlobalAlloc");

		CUEPOINT *pData=(CUEPOINT *)GlobalLock(psp->hData);
		if(!pData)
			throw std::runtime_error("GlobalLock");

		for(size_t i=0; i<lab.size(); ++i) {
			pData[i].name_id =	lab[i].name_id;
			pData[i].position =	lab[i].pos;
		}

		GlobalUnlock(pData);
	}
	catch(const std::runtime_error &) {
		if(psp->hData)
			GlobalFree(psp->hData);
		return 0;
	}
	return 1;
}

DWORD fill_ltxt_info(const FILTER_IO *filter, SPECIALDATA *psp) {
	try {
		memset(psp, 0, sizeof(*psp));

		psp->hSpecialData = (HANDLE)2;

		const std::vector<FILTER_IO::REGION> &lab=filter->lab_data;
		psp->dwExtra= lab.size();
		psp->dwSize = lab.size()*sizeof(LTXTPOINT);
		strcpy(psp->szListType,"adtl");
		strcpy(psp->szType,    "ltxt");

		if(!(psp->hData = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT, psp->dwSize)))
			throw std::runtime_error("GlobalAlloc");

		LTXTPOINT *pData=(LTXTPOINT *)GlobalLock(psp->hData);
		if(!pData)
			throw std::runtime_error("GlobalLock");

		for(size_t i=0; i<lab.size(); ++i) {
			pData[i].ltxt_len =	sizeof(*pData);
			pData[i].name_id =	lab[i].name_id;
			pData[i].cue_length=lab[i].len;
			pData[i].purpose =	0x206E6772; // "rgn "
		}

		GlobalUnlock(pData);
	}
	catch(const std::runtime_error &) {
		if(psp->hData)
			GlobalFree(psp->hData);
		return 0;
	}
	return 1;
}

DWORD fill_labl_info(const FILTER_IO *filter, SPECIALDATA *psp) {
	try {
		memset(psp, 0, sizeof(*psp));

		psp->hSpecialData = (void *)0;

		const std::vector<FILTER_IO::REGION> &lab=filter->lab_data;
		psp->dwExtra= lab.size();
		for(size_t i=0; i<lab.size(); ++i)
			psp->dwSize += sizeof(LABLPOINT) + lab[i].name_str.length();
		strcpy(psp->szListType,"adtl");
		strcpy(psp->szType,    "labl");

		if(!(psp->hData = GlobalAlloc(GMEM_MOVEABLE|GMEM_ZEROINIT, psp->dwSize)))
			throw std::runtime_error("GlobalAlloc");

		LABLPOINT *pData=(LABLPOINT *)GlobalLock(psp->hData);
		if(!pData)
			throw std::runtime_error("GlobalLock");

		LABLPOINT *pData_it = pData;
		for(size_t i=0; i<lab.size(); ++i) {
			pData_it->name_id =	lab[i].name_id;
			strcpy(pData_it->name_str, lab[i].name_str.c_str());
			pData_it=(LABLPOINT *)((char *)pData_it+sizeof(LABLPOINT)+lab[i].name_str.length());
		}

		GlobalUnlock(pData);
	}
	catch(const std::runtime_error &) {
		if(psp->hData)
			GlobalFree(psp->hData);
		return 0;
	}
	return 1;
}

DWORD proc_cue_info (FILTER_IO *filter, const char *data, size_t data_size) {
	std::vector<FILTER_IO::REGION> &lab=filter->lab_data;

	const CUEPOINT *cue=(const CUEPOINT *)data;
	lab.resize(data_size/sizeof(*cue));

	std::vector<FILTER_IO::REGION>::iterator out_it=lab.begin();
	for(const CUEPOINT *it=cue, *ie=cue+lab.size(); it!=ie; ++it, ++out_it) {
		out_it->name_id = it->name_id;
		out_it->pos		= it->position;
	}

	return 1;
}

DWORD proc_ltxt_info(FILTER_IO *filter, const char *data, size_t data_size) {
	std::vector<FILTER_IO::REGION> &lab=filter->lab_data;

	const LTXTPOINT *ltxt=(const LTXTPOINT *)data;
	while((uintptr_t)ltxt<(uintptr_t)(data+data_size)) {
		std::vector<FILTER_IO::REGION>::iterator lab_it;
		if(ltxt->name_id-1<lab.size() && lab[ltxt->name_id-1].name_id==ltxt->name_id)
			lab_it = lab.begin() + (ltxt->name_id-1);
		else {
			for(; lab_it!=lab.end() && lab_it->name_id!=ltxt->name_id; ++lab_it)
				;
			if(lab_it==lab.end())
				continue;
		}
		lab_it->len = ltxt->cue_length;

		ltxt = (const LTXTPOINT *)((uintptr_t)ltxt + ltxt->ltxt_len);
	}

	return 1;
}

DWORD proc_labl_info(FILTER_IO *filter, const char *data, size_t data_size) {
	std::vector<FILTER_IO::REGION> &lab=filter->lab_data;

	uint64_t fs = filter->signal_fh.samplerate();
	const LABLPOINT *labl=(const LABLPOINT *)data;
	while((uintptr_t)labl<(uintptr_t)(data+data_size)) {
		std::vector<FILTER_IO::REGION>::iterator lab_it;
		if(labl->name_id-1<lab.size() && lab[labl->name_id-1].name_id==labl->name_id)
			lab_it = lab.begin() + (labl->name_id-1);
		else {
			for(; lab_it!=lab.end() && lab_it->name_id!=labl->name_id; ++lab_it)
				;
			if(lab_it==lab.end())
				continue;
		}
		uint64_t pos_beg =  (uint64_t)(lab_it->pos)				*10000000/fs;
		uint64_t pos_end = ((uint64_t)(lab_it->pos)+lab_it->len)*10000000/fs;
		filter->labels_fh << pos_beg << " " << pos_end << " " << ANSItoUTF8(labl->name_str).c_str() << std::endl;

		labl = (const LABLPOINT *)((uintptr_t)labl + sizeof(LABLPOINT) + strlen(labl->name_str));
	}

	return 1;
}
