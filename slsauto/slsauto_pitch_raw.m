function slsauto_pitch_raw(snd_pathname)
	[f0_sfs.freq, f0_sfs.time] = sfs_rapt(snd_pathname);
	[f0_sfs.freq, f0_sfs.time] = remove_zeros(f0_sfs.freq, f0_sfs.time);
	save_pitch_raw(snd_pathname, f0_sfs, '010_sfs_rapt(k.-)');

	[f0_pr.freq, f0_pr.time]   = pitchrapt(snd_pathname);
	[f0_pr.freq, f0_pr.time]   = remove_zeros(f0_pr.freq, f0_pr.time);
	f0_pr.freq = octave_fix(f0_pr.freq, f0_pr.time, 0.5);
	f0_pr.freq = median_fix(f0_pr.freq, f0_pr.time, 5);
	save_pitch_raw(snd_pathname, f0_pr, '020_pitchrapt(bd-)');

	slsauto_pitch_editor(snd_pathname);
end

function f0_freq = median_fix(f0_freq, f0_time, med_sz)
	dt = diff(f0_time);
	voc_reg = [0; find(dt>=min(dt)*1.1); numel(f0_time)];

	for vi = 1:numel(voc_reg)-1
		ii = voc_reg(vi)+1:voc_reg(vi+1);
		f0_freq(ii) = medfilt1(f0_freq(ii), med_sz);
	end
end

function f0_freq = octave_fix(f0_freq, f0_time, octave_threshold)
	dt = diff(f0_time);
	voc_reg = [0; find(dt>=min(dt)*1.1); numel(f0_time)];

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

function save_pitch_raw(snd_pathname, f0, ext)
	save_data = [f0.time(:) f0.freq(:)]; %#ok<NASGU>
	save([snd_pathname '.pitch_' ext '.txt'],'save_data','-ascii');
end

function [f0_freq, f0_time] = remove_zeros(f0_freq, f0_time)
	ind = f0_freq>0;
	f0_freq = f0_freq(ind);
	f0_time = f0_time(ind);
end
