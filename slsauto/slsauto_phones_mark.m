function slsauto_phones_mark(cfg)
	if nargin<1
		if exist('libsndfile_read','file')
			dlg_filter = {'*.wav;*.flac;*.ogg','Sound files';'*.*','All files'};
		else
			dlg_filter = {'*.wav','Wave files (*.wav)';'*.*','All files'};
		end
		[dlg_name,dlg_path] = uigetfile(dlg_filter,'Select file for processing');
		if dlg_name==0
			return
		end
		cfg = fullfile(dlg_path,dlg_name);
	end

	load(slsauto_getpath(cfg,'lpc'));
	lpc_b = lpc_b; %#ok<ASGSL>
	lpc_lsf = lpc_lsf; %#ok<ASGSL>
	lab = lab_read(slsauto_getpath(cfg,'lab'));
	ind = strcmp('#syntagm',{lab.string});
	lab_syntagm = lab(ind);
	lab(ind) = [];
	lpc_t = (lpc_lsf_ind-1)/fs;
	lpc_fs = 1/(lpc_t(2)-lpc_t(1));

	pitch = load(slsauto_getpath(cfg,'pitch_vu'));
	pitch(:,2) = [];
	pitch_dt = diff(pitch(:,1));
	pitch_reg = find(pitch_dt>=min(pitch_dt)*1.5);
	lab_v = [struct('begin',num2cell(pitch(1)));			struct('begin',num2cell(pitch(pitch_reg+1)))];
	lab_u = [struct('begin',num2cell(pitch(pitch_reg)));	struct('begin',num2cell(pitch(end)))];
	lab = [lab_v; lab_u];

	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	fs = x_info.SampleRate;
	[power.obs power.time] = obs_power(x, fs, 0.020, 0.001);
	power.noise_lvl = mean(quantile(power.obs, [0.03 0.97]));
	power.obs(power.obs<power.noise_lvl) = power.noise_lvl;

	power_fs = 1/min(diff(power.time));
	b = conv( fir1(round(power_fs*0.5), [10 50]*2/power_fs), [1 -1]);
	gauss_b =  gaussfilter(100/(lpc_fs/2));
	gauss_bd = conv(gauss_b, [1 -1]);
% 	gauss_b = b;
	power.diff = filter_fir_nodelay(b,power.obs);


	freqz_sz = pow2(round(log2( (fs/2) / 10 )));
	[~,freqz_f] = freqz(lpc_b(1), lsf2poly_even(lpc_lsf(1,:)), freqz_sz);
	freqz_f = freqz_f*fs/(2*pi);
	[~,freqz_ind] = arrayfun(@(x) min(abs(freqz_f-x)), [100 4000]);
	freqz_ind = freqz_ind(1):freqz_ind(2);
	freqz_band = zeros(size(lpc_lsf,1), numel(freqz_ind));
	parfor li = 1:size(lpc_lsf,1)
		cur_h = freqz(lpc_b(li), lsf2poly_even(lpc_lsf(li,:)), freqz_sz);
		cur_h = cur_h(freqz_ind);
		cur_h = cur_h.*conj(cur_h);
		freqz_band(li,:) = cur_h';
	end
	power_band = mean(freqz_band,2);
	[~,freqz_F1_ind] = min(abs(freqz_f-1000));
	power_low =  mean(freqz_band(:,1:freqz_F1_ind),2);
	[~,freqz_F3_ind] = min(abs(freqz_f-2000));
	power_high = mean(freqz_band(:,freqz_F3_ind:end),2);

	% Преобразование мощности в дБ
	freqz_band = 10*log10(freqz_band);
	power_band = 10*log10(power_band);
	power_low =  10*log10(power_low);
	power_high = 10*log10(power_high);
	lpc_b = 20*log10(lpc_b);

	% Удаление маломощных пульсаций
%	low_powr = power_band < quantile(power_band, 0.25);
%	freqz_band(low_powr,:) = repmat(mean(freqz_band(low_powr,:),1), sum(low_powr), 1);

	% Сглаживание спектра по времени
	freqz_diff = mean(filter_fir_nodelay(gauss_bd, freqz_band),2);
	power_band = filter_fir_nodelay(gauss_bd, power_band);
	power_low =  filter_fir_nodelay(gauss_bd, power_low);
	power_low_high = filter_fir_nodelay(conv(gauss_b, fir1(round(lpc_fs/2), 10*2/lpc_fs, 'high')), zscore(power_low) - zscore(power_high));
	lpc_b = filter_fir_nodelay(gauss_bd, lpc_b);

	fig = figure('NumberTitle','off', 'Name',slsauto_getpath(cfg,'snd'), 'Units','normalized', 'Position',[0 0 1 1]);
	subplot(3,1,1);
	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	x(:,2:end) = [];
	plot((0:size(x,1)-1)/x_info.SampleRate, x);
	x_lim = [0 (size(x,1)-1)/x_info.SampleRate];
	axis([x_lim max(abs(x))*1.1*[-1 1]]);
	grid('on');
	lab_x =	[[lab.begin]; [lab.begin]; nan(1,numel(lab))];
	lab_x = lab_x(:);
	lab_y = repmat([ylim nan]', numel(lab), 1);
	hold('on');
	plot(lab_x, lab_y, 'k');

	subplot(3,1,2);
	imagesc(lpc_t, freqz_f(freqz_ind), freqz_band.');
	axis('xy');
	xlim(x_lim);
	lab_y = repmat([ylim nan]', numel(lab), 1);
	hold('on');
	plot(lab_x, lab_y, 'k');

	subplot(3,1,3);
	plot(lpc_t,lpc_b,'b'); % , lpc_t,zscore(power_band),'r', lpc_t,zscore(power_low),'k', lpc_t,zscore(freqz_diff),'m', lpc_t,zscore(power_low_high),'b--');
	hold('on');
	plot(power.time, power.diff,'k');
	legend({'lpc_b' 'power_band' 'power_F1' 'freqz_diff' 'power.diff'}, 'Location','NE', 'Interpreter','none');
	xlim(x_lim);
	grid('on');
	lab_y = repmat([ylim nan]', numel(lab), 1);
	plot(lab_x, lab_y, 'k');


	data = guihandles(fig);
	data.user_data.x_len = x_lim(2);
	guidata(fig,data);
 	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
 	set(zoom,'ActionPostCallback',@on_zoom_pan);
 	zoom('xon');

% 	if exist('libsndfile_read','file')
% 		[x,fs] = libsndfile_read(cfg.snd_filename);
% 		fs = fs.SampleRate;
% 	else
% 		[x,fs] = wavread(cfg.snd_filename);
% 	end
% 	x(:,2:end) = [];
% 	if isfield(cfg,'fs')
% 		x = resample(x,cfg.fs,fs);
% 		fs = cfg.fs;
% 	end
% 	cfg.fs = fs;
% 
% 
% 	frame_size = round(cfg.frame_size*fs);
% 	frame_shift= round(cfg.frame_shift*fs);
% 	obs_ind = (1:frame_shift:size(x,1)-frame_size+1)';
% 	obs = zeros(size(obs_ind,1), size(calc_obs(cfg,randn(frame_size,1)),2));
% 
% 	parfor oi = 1:size(obs_ind,1) % parfor
% 		obs(oi,:) = calc_obs(cfg, x(obs_ind(oi)+(0:frame_size-1)));
% 	end
% 	yy = dist_func(cfg, obs);
% 
% 
% 	figure('Units','normalized', 'Position',[0 0 1 1]);
% 	x_lim=[0 size(x,1)-1]/cfg.fs;
% 	subplot(3,1,1);
% 	plot((0:size(x,1)-1)/fs, x);
% 	axis([x_lim max(abs(x))*1.1*[-1 1]]);
% 	grid('on');
% 
% 	[X,X_freq,X_time] = spectrogram(x, hann(frame_size), frame_size-frame_shift, pow2(2+ceil(log2(frame_size))), cfg.fs);
% 	X=10*log10(X.*conj(X));
% 	X_time=X_time(:);
% 
% 	subplot(3,1,2);
% 	imagesc(X_time,X_freq,X);
% 	axis([x_lim 0 cfg.fs/2]);
% 	axis('xy');
% 	
% 	subplot(3,1,3);
% 	xx = (mean([obs_ind(2:end) obs_ind(1:end-1)],2)-1+frame_shift/2)/cfg.fs;
% 	plot(xx, yy);
% 	xlim(x_lim);
% 
%  	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
%  	set(zoom,'ActionPostCallback',@on_zoom_pan);
%  	zoom('xon');
end

% function y = calc_obs(cfg, x)
% 	y = rceps(x)';
% 	y = y(1:fix(cfg.fs/600)); % 600 Гц - максимальное значение ЧОТ
% end
% 
% function d = dist_func(cfg, obs)
% 	x = obs(1:end-1,:);
% 	y = obs(2:end,:);
% 	switch cfg.dist_func
% 		case 'euclidean'
% 			d = x - y;
% 			d = sqrt(sum(d.*d,2));
% 		case 'seuclidean'
% 			v = var(obs,[],1);
% 			d = (x - y) .* repmat(sqrt(1./v),size(x,1),1);
% 			d = sqrt(sum(d.*d,2));
% 		otherwise
% 			error(['The ' cfg.dist_func ' distance is unimplemented.']);
% 	end
% end

function [obs_power, obs_time] = obs_power(x, fs, frame_size, frame_shift)
	frame_size  = round(frame_size*fs);
	frame_shift = round(frame_shift*fs);

	obs_sz = fix((size(x,1)-frame_size)/frame_shift+1);

	obs_time  = ((0:obs_sz-1)'*frame_shift+frame_size/2)/fs;
	obs_power = zeros(obs_sz,1);

	obs_ind=0;
	for i=1:frame_shift:size(x,1)-frame_size+1
		cur_x = x(i:i+frame_size-1);
		obs_ind = obs_ind+1;
		obs_power(obs_ind) = mean(cur_x.*cur_x);
	end
	if obs_ind~=size(obs_power,1)
		error('Observation length mismatch.');
	end

	obs_power = 10*log10(obs_power + 1e-100);
end
