if strcmp(computer, 'PCWIN')
	bin_dir='bin_win32';
else
	bin_dir='bin_win64';
end

mex('-largeArrayDims', ['-L' bin_dir], '-llibsndfile-1', '-outdir',bin_dir, 'libsndfile_info.cpp');
mex('-largeArrayDims', ['-L' bin_dir], '-llibsndfile-1', '-outdir',bin_dir, 'libsndfile_read.cpp');
