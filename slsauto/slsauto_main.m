function slsauto_main()
	addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'@.*' '\.svn' 'private' 'html'});

	snd_pathname = 'd:\Matlab work\kaz\snd\cut8000_01.flac';

	slsauto_pitchraw(snd_pathname);
end
