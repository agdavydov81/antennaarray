#include "libsndfile_func.h"

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {

	mxArray * &info=plhs[0];
	init_info(info);

	try {
		if(nrhs != 1 || !mxIsChar(prhs[0])) {
			mexPrintf("Usage: info = libsndfile_info('file_name');\n");
			throw std::runtime_error("Not enough input arguments.");
		}

		std::vector<char> file_name(mxGetN(prhs[0])+1);
		mxGetString(prhs[0], &file_name[0], file_name.size());
		
		SndfileHandle snd_file(&file_name[0]);
		if(snd_file.error())
			throw std::runtime_error(snd_file.strError());

		fill_info(&file_name[0], snd_file, info);
	}
	catch(const std::exception &err) {
		mxDestroyArray(mxGetField(info, 0, "Error"));
		mxSetField(info, 0, "Error", mxCreateString(err.what()));
		return;
	}
}
