function file_pathname = slsauto_makepath(snd_pathname, filetype)
	[snd_path, snd_name] = fileparts(snd_pathname);
	switch filetype
		case 'lab'
			file_pathname = fullfile(snd_path, [snd_name '.lab']);
		case 'pitch'
			list = dir([snd_pathname '.pitch_*.txt']);
			[~,si] = sort({list.name});
			list = list(si);
			if isempty(list)
				error('Can''t deduce pitch file name for sound file ''%s''.',snd_pathname);
			end
			file_pathname = fullfile(snd_path, list(end).name);
		case 'prosody'
			file_pathname = [snd_pathname '.prosody.xml'];
		otherwise
			error('Unsupported auto type identification.');
	end
end
