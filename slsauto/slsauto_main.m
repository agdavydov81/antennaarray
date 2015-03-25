function slsauto_main()
	addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'@.*' '\.svn' 'private' 'html'});

	slsauto_pitch_raw('kaz\snd\cut.flac');

%	slsauto_
end
