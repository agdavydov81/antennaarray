function [file_pathname is_auto] = slsauto_getpath(cfg, filetype)
	if isfield(cfg, [filetype '_pathname'])
		file_pathname = cfg.([filetype '_pathname']);
		is_auto = false;
		return
	end

	[snd_path, snd_name] = fileparts(cfg.snd_pathname);
	switch filetype
		case 'lab'
			file_pathname = fullfile(snd_path, [snd_name '.lab']);
		case 'pitch'
			list = dir([cfg.snd_pathname '.pitch_*.txt']);
			[~,si] = sort({list.name});
			list = list(si);
			if isempty(list)
				error('Can''t deduce pitch file name for sound file ''%s''.',cfg.snd_pathname);
			end
			file_pathname = fullfile(snd_path, list(end).name);
		case 'prosody'
			file_pathname = [cfg.snd_pathname '.prosody.xml'];
		case 'mono_time'
			file_pathname = [cfg.snd_pathname '.mono_time.txt'];
		case 'mono_lpc'
			file_pathname = [cfg.snd_pathname '.mono_lpc.mat'];
		otherwise
			error('Unsupported auto type identification.');
	end
	is_auto = true;
end
