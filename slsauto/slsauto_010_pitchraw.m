function slsauto_010_pitchraw(snd_pathname)
	[f0_pr.freq, f0_pr.time]   = pitchrapt(snd_pathname);
	f0_pr.freq = octave_fix(f0_pr.freq, f0_pr.time);
	save_pitchraw(snd_pathname, f0_pr, 'pr');

	[f0_sfs.freq, f0_sfs.time] = sfs_rapt(snd_pathname);
	f0_sfs.freq = octave_fix(medfilt1(f0_sfs.freq,5), f0_sfs.time);
	save_pitchraw(snd_pathname, f0_sfs, 'sfs');


end

function f0_freq = octave_fix(f0_freq, f0_time)
	while true
		df = calc_df(f0_freq, f0_time);
		fi = find(abs(df)>0.7);
		if isempty(fi)
			break
		end
		f0_ind = [max([0 find(f0_freq(1:fi(1))==0,1,'last')]) fi(1) numel(f0_freq)];
		if numel(fi)>1
			f0_ind(3) = fi(2);
		end
		f0_ind(3) = min([f0_ind(3) find(f0_freq(fi(1):end)==0,1,'first')-1+fi(1)-1]);
%		f0_freq_before = f0_freq(1:f0_ind(1));
%		f0_freq_before(1:end-50) = [];
%		f0_freq_after  = f0_freq(f0_ind(3):end);
%		f0_freq_after(51:end) = [];
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

function save_pitchraw(snd_pathname, f0, ext)
	save_data = [f0.time(:) f0.freq(:)];
	save([snd_pathname '.pitchraw_' ext '.txt'],'save_data','-ascii');
end
