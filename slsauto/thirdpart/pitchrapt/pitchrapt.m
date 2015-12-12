function [f0_freq, f0_time, f0_tone] = pitchrapt(x_or_filename, fs)
	tmp_dir = tempname();
	mkdir(tmp_dir);

	if (nargin<2 || isempty(fs)) && ischar(x_or_filename)
		[x, x_info] = libsndfile_read(x_or_filename);
		fs = x_info.SampleRate;
	else
		x = x_or_filename;
	end
	x(:,2:end) = [];
	if fs~=8000
		x = resample(x, 8000, fs);
	end
	wavwrite(x, 8000, fullfile(tmp_dir, 'signal.wav'));

	tmp_do = fullfile(tmp_dir, 'do.bat');
	fh = fopen(tmp_do, 'w');
	fprintf(fh, '%s\n', tmp_dir(1:2));
	fprintf(fh, 'cd "%s"\n', tmp_dir(3:end));
	fprintf(fh, '"%s" signal.wav -c "%s" -b 65536 -ch 1', which('PitchRAPT_cmd.exe'), which('PitchRAPT_cfg_080.xml'));
	fclose(fh);
	[dos_status, dos_result]=dos(tmp_do); %#ok<*NASGU,*ASGLU>

	pr_data = load(fullfile(tmp_dir, 'signal.wav_PitchRAPT.txt'));

	f0_freq = pr_data(:,end);
	f0_time = pr_data(:,1)/8000;
	f0_tone = pr_data(:,end-1);
	
	try
		rmdir(tmp_dir,'s');
	catch ME
	end
end
