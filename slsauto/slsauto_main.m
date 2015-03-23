function slsauto_main()
	addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'@.*' '\.svn' 'private' 'html'});

	snd_pathname = 'd:\Matlab work\kaz\snd\cut1.flac';

	slsauto_pitch_raw(snd_pathname);
	
%	slsauto_
end
