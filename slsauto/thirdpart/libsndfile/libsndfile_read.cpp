#include "libsndfile_func.h"

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	mxArray * &signal = plhs[0];
	mxArray * &info = plhs[1];
	init_info(info);
	signal = mxCreateDoubleMatrix(0, 0, mxREAL);

	try {
		if(nrhs != 1 || !mxIsChar(prhs[0])) {
			mexPrintf("Usage: [signal info] = libsndfile_read('file_name');\n");
			throw std::runtime_error("Not enough input arguments.");
		}

		std::vector<char> file_name(mxGetN(prhs[0])+1);
		mxGetString(prhs[0], &file_name[0], file_name.size());

		SndfileHandle snd_file(&file_name[0]);
		if(snd_file.error())
			throw std::runtime_error(snd_file.strError());

		fill_info(&file_name[0], snd_file, info);
		
		size_t frames_num = snd_file.frames();
		size_t channels_num = snd_file.channels();
		mxDestroyArray(signal);
		signal = mxCreateDoubleMatrix(frames_num, channels_num, mxREAL);
		double *signal_ptr = mxGetPr(signal);
		
		if(channels_num==1) {
			snd_file.readf(signal_ptr, frames_num);
		}
		else {
			size_t frames_buf_max_sz = (65536+channels_num-1)/channels_num;
			std::vector<double> sgnl_buf(frames_buf_max_sz * channels_num);
			size_t frames_num_all = frames_num;
			while(frames_num) {
				size_t frames_cur = std::min(frames_num, frames_buf_max_sz);
				double *buf_frame = &sgnl_buf[0];
				snd_file.readf(buf_frame, frames_cur);

				for(size_t fr_i=0; fr_i<frames_cur; ++fr_i, ++signal_ptr) {
					double *signal_frame = signal_ptr;
					for(size_t ch_i=0; ch_i<channels_num; ++ch_i, signal_frame+=frames_num_all, ++buf_frame)
						*signal_frame = *buf_frame;
				}

				frames_num-=frames_cur;
			}
		}
	}
	catch(const std::exception &err) {
		mxDestroyArray(mxGetField(info, 0, "Error"));
		mxSetField(info, 0, "Error", mxCreateString(err.what()));
		return;
	}
}
