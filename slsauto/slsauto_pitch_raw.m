function slsauto_pitch_raw(cfg, methods)
	if nargin < 2
		methods = {'pitchrapt' 'irapt'}; % 'sfs_rapt'
	end
	
	for m = methods
		switch(m{1})
			case 'sfs_rapt'
				[f0_sfs.freq, f0_sfs.time] = sfs_rapt(slsauto_getpath(cfg,'snd'));
				f0_sfs = remove_zeros(f0_sfs);
				save_pitch_raw(slsauto_getpath(cfg,'snd'), f0_sfs, '010_sfs_rapt(k.-)');

			case 'pitchrapt'
				[f0_pr.freq, f0_pr.time]   = pitchrapt(slsauto_getpath(cfg,'snd'));
				f0_pr = remove_zeros(f0_pr);
				save_pitch_raw(slsauto_getpath(cfg,'snd'), f0_pr, '020_pitchrapt(bd-)');
				f0_pr.freq = octave_fix(f0_pr.freq, f0_pr.time, 0.5);
				f0_pr.freq = median_fix(f0_pr.freq, f0_pr.time, 5);
				save_pitch_raw(slsauto_getpath(cfg,'snd'), f0_pr, '021_pitchrapt(bd-)');

			case 'irapt'
				[x, x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
				[f0_irapt.freq, f0_irapt.time, f0_irapt.isvocal] = irapt(x, x_info.SampleRate, 'irapt2');
				f0_irapt = remove_zeros(f0_irapt);
				save_pitch_raw(slsauto_getpath(cfg,'snd'), f0_irapt, '030_irapt(ko-)');
				f0_irapt = irapt_voiced_fix(f0_irapt, 8, 0.041);
				f0_irapt.freq = octave_fix(f0_irapt.freq, f0_irapt.time, 0.5);
				save_pitch_raw(slsauto_getpath(cfg,'snd'), f0_irapt, '031_irapt(ko-)');
		end
	end
end

function f0_irapt = irapt_voiced_fix(f0_irapt, lodf2dt_max, voc_sz_min)
	dt = diff(f0_irapt.time);
	logdf = diff(log2(f0_irapt.freq));
	frame_shift = min(dt);

	ii = abs(logdf/frame_shift)>=lodf2dt_max;
	ii(dt>frame_shift*1.5) = false;
	ii = any([[ii; false] [false; ii]],2);
	f0_irapt.time(ii) = [];
	f0_irapt.freq(ii) = [];
	f0_irapt.isvocal(ii) = [];

	ii = false(size(f0_irapt.time));
	dt = diff(f0_irapt.time);
	voc_reg = [0; find(dt>=frame_shift*1.5); numel(f0_irapt.time)];
	for vi = 1:numel(voc_reg)-1
		if f0_irapt.time(voc_reg(vi+1)) - f0_irapt.time(voc_reg(vi)+1) < voc_sz_min
			ii(voc_reg(vi)+1:voc_reg(vi+1)) = true;
		end
	end
	f0_irapt.time(ii) = [];
	f0_irapt.freq(ii) = [];
	f0_irapt.isvocal(ii) = [];
end

function f0_freq = median_fix(f0_freq, f0_time, med_sz)
	dt = diff(f0_time);
	voc_reg = [0; find(dt>=min(dt)*1.5); numel(f0_time)];

	for vi = 1:numel(voc_reg)-1
		ii = voc_reg(vi)+1:voc_reg(vi+1);
		f0_freq(ii) = medfilt1(f0_freq(ii), med_sz);
	end
end

function f0_freq = octave_fix(f0_freq, f0_time, octave_threshold)
	dt = diff(f0_time);
	voc_reg = [0; find(dt>=min(dt)*1.5); numel(f0_time)];

	while true
		df = calc_df(f0_freq, f0_time);
		fi = find(abs(df)>octave_threshold);
		if isempty(fi)
			break
		end
		f0_ind(2) = fi(1);
		f0_ind(1) = voc_reg(find(voc_reg<f0_ind(2),1,'last'));
		f0_ind(3) = voc_reg(find(voc_reg>=f0_ind(2),1));
		if numel(fi)>1
			f0_ind(3) = min(f0_ind(3), fi(2));
		end
		ad = log2([median(f0_freq(f0_ind(1)+1:f0_ind(2))) median(f0_freq(f0_ind(2)+1:f0_ind(3)))]/median(f0_freq));
		[~,mi]=max(abs(ad));
		if mi==2
			mul_sgn = -1;
		else
			mul_sgn = 1;
		end
		f0_freq(f0_ind(mi)+1:f0_ind(mi+1)) = f0_freq(f0_ind(mi)+1:f0_ind(mi+1)) * pow2(mul_sgn*round(df(fi(1))));
	end
end

function df = calc_df(f0_freq, f0_time)
	df = log2(f0_freq(2:end)./f0_freq(1:end-1));
	df(f0_freq(2:end)==0) = 0;
	df(f0_freq(1:end-1)==0) = 0;
	dt = diff(f0_time);
	df(dt>=min(dt)*1.1) = 0;
end

function save_pitch_raw(snd_filename, f0, ext)
	save_data = [f0.time(:) f0.freq(:)]; %#ok<NASGU>
%	if isfield(f0,'isvocal')
%		save_data = [save_data f0.isvocal];
%	end
	out_filename = [snd_filename '.pitch_' ext '.txt'];
	if exist(out_filename,'file')
		movefile(out_filename,[out_filename '.bak']);
	end
	save(out_filename,'save_data','-ascii');
end

function f0 = remove_zeros(f0)
	ind = f0.freq>0;
	f0.freq = f0.freq(ind);
	f0.time = f0.time(ind);
	if isfield(f0,'isvocal')
		f0.isvocal = f0.isvocal(ind);
	end
end
