function slsauto_parameterization(snd_pathname, lab_pathname, pitch_pathname, prosody_pathname)
	if nargin<2 || isempty(lab_pathname)
		lab_pathname = slsauto_makepath(snd_pathname, 'lab');
	end
	if nargin<3 || isempty(pitch_pathname)
		pitch_pathname = slsauto_makepath(snd_pathname, 'pitch');
	end
	if nargin<4 || isempty(prosody_pathname)
		prosody_pathname = slsauto_makepath(snd_pathname, 'prosody');
	end

%	[x,x_info] = libsndfile_

end
