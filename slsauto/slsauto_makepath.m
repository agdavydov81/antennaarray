function file_pathname = slsauto_makepath(snd_pathname, filetype)
	[snd_path, snd_name] = fileparts(snd_pathname);
	switch filetype
		case 'lab'
			file_pathname = fullfile(snd_path, [snd_name '.lab']);
		case 'pitch'
			file_pathname = dir([snd_pathname '.pitch_pitchrapt*.txt']);
			if numel(file_pathname)~=1
				error('Can''t deduce pitch file name for sound file ''%s''.',snd_pathname);
			end
			file_pathname = fullfile(snd_path, file_pathname.name);
		case 'prosody'
			file_pathname = [snd_pathname '.prosody.xml'];
		otherwise
			error('Unsupported auto type identification.');
	end
end
