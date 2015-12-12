function [file_filename is_auto] = slsauto_getpath(cfg, filetype)
	if ischar(cfg)
		cfg = struct('snd_filename',cfg);
	end

	if isfield(cfg, [filetype '_filename'])
		file_filename = cfg.([filetype '_filename']);
		is_auto = false;
		return
	end

	[snd_path, snd_name] = fileparts(cfg.snd_filename);
	switch filetype
		case 'lab'
			file_filename = fullfile(snd_path, [snd_name '.lab']);
		case 'pitch'
			list = dir([cfg.snd_filename '.pitch_*.txt']);
			[~,si] = sort({list.name});
			list = list(si);
			if isempty(list)
				error('Can''t deduce pitch file name for sound file ''%s''.',cfg.snd_filename);
			end
			file_filename = fullfile(snd_path, list(end).name);
		case 'pitch_vu'
			list = dir([cfg.snd_filename '.pitch_*_pitchrapt*.txt']);
			if isempty(list)
				file_filename = slsauto_getpath(cfg, 'pitch');
			else
				[~,si] = sort({list.name});
				list = list(si);
				file_filename = fullfile(snd_path, list(end).name);
			end
		case 'prosody'
			file_filename = [cfg.snd_filename '.prosody.xml'];
		case 'lpc'
			file_filename = [cfg.snd_filename '.lpc.mat'];
		case 'synth'
			file_filename = [cfg.snd_filename '.synth.wav'];
		otherwise
			error('Unsupported auto type identification.');
	end
	is_auto = true;
end
