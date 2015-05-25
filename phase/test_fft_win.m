function test_fft_win
	cfg = struct('N_win',1024, 'N_fft',64*1024, 'db_lvl',-6);

	ref = win_analyse('rectwin', cfg);

	win_name = {'barthannwin','bartlett','blackman','blackmanharris','bohmanwin','chebwin','flattopwin','gausswin','hamming','hann','kaiser','nuttallwin','parzenwin','rectwin','taylorwin','triang','tukeywin'};
	name_blank = repmat(' ',1,ceil((max(cellfun(@numel,win_name))+1)/4)*4);

	for wi=1:numel(win_name)
		cur = win_analyse(win_name{wi}, cfg);
		cur_name = name_blank;
		cur_name(1:length(win_name{wi})) = win_name{wi};
		cur_name(length(win_name{wi})+1) = ':';

		fprintf('%s%f\t\t%f\t\t%f\t\t%f\n', cur_name, cur.w_lvl/ref.w_lvl, cur.w_p05/ref.w_p05, cur.w_main/ref.w_main, 10*log10(1-cur.p_main));
	end
end


function res = win_analyse(win_name, cfg)
	win_func = str2func(win_name);

	[H,w]=freqz(win_func(cfg.N_win),1,cfg.N_fft);

	H = H.*conj(H);
	Hc = cumsum(H);
	Hc = Hc / Hc(end);
	[~,mi]=min(abs(Hc-0.5));
	res.w_p05 = w(mi);

	Hd=10*log10(H);
	Hd=Hd-max(Hd);
	[~,mi]=min(abs(Hd-cfg.db_lvl));
	res.w_lvl = w(mi);
	
	mi = find(diff(Hd)>0.1,1);
	res.w_main = w(mi);
	res.p_main = Hc(mi);
end

