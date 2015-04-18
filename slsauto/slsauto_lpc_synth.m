function slsauto_lpc_synth(cfg, synth_t, border_type)
	if nargin<3
		border_type = 'v'; % 'v' - split to V+U regions; 'u' - split to U+V regions; 'vu' or 'uv' - split to U and V regions
	end

	%% Загрузка данных
	lpc_cache = load(slsauto_getpath(cfg,'lpc'));

	pitch_vu = load(slsauto_getpath(cfg,'pitch_vu'));
	pitch_dt = diff(pitch_vu(:,1));
	vocal_ind = [0; find(pitch_dt>=min(pitch_dt)*1.5); size(pitch_vu,1)];
	vocal_pos = [pitch_vu(vocal_ind(1:end-1)+1,1) pitch_vu(vocal_ind(2:end),1)];
	vocal_pos = round(vocal_pos*lpc_cache.fs)+1;

	lab = lab_read(slsauto_getpath(cfg,'lab'));
	syntagm_pos = [round([lab.begin lab.end]*lpc_cache.fs)+1 0 size(lpc_cache.lpc_e,1)];
	syntagm_pos = sort(unique(syntagm_pos));

	prosody = xml_read(slsauto_getpath(cfg,'prosody'));
	
	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	fs = x_info.SampleRate;
	[power.obs power.time] = obs_power(x, fs, 0.020, 0.001);
	
	figure('Units','normalized', 'Position',[0 0 1 1]);
	x_lim = [0 (size(x,1)-1)/fs];
	subplot(4,1,1);
	plot((0:size(x,1)-1)/fs,x);
	axis([x_lim [-1 1]*1.1*max(abs(x))]);
	grid('on');
	subplot(4,1,2);
	plot(pitch_vu(:,1), pitch_vu(:,2), 'b.');
	xlim(x_lim);
	grid('on');
	subplot(4,1,3);
	plot(power.time, power.obs);
	xlim(x_lim);
	grid('on');
	subplot(4,1,4);
	hold('on');
	p_fs = 1/min(diff(power.time));
	b = conv( fir1(round(p_fs*0.5), 33*2/p_fs), [1 -1]);
	ord2 = fix(numel(b)/2);
	power.obs = filter(b,1,[power.obs; zeros(ord2,1)]);
	power.obs(1:ord2) = [];
	plot(power.time, power.obs);
	xlim(x_lim);
	grid('on');
	
 	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
 	set(zoom,'ActionPostCallback',@on_zoom_pan);
 	zoom('xon');

	for si = 1:numel(syntagm_pos)-1
	end

%	regions.start = [];
%{
	%% Основной цикл синтеза речеподобных сигналов
	synth_y = zeros(0,1);
	while size(synth_y,1)/lpc_cache.fs < synth_t
		%% Синтез очередной синтагмы
		cur_y = randn(1000,1);
		
		
		synth_y = [synth_y; cur_y];
	end
	
	wavwrite(synth_y, lpc_cache.fs, slsauto_getpath(cfg,'synth'));
%}
%	y = lpc_synth(lpc_cache.fs, lpc_cache.lpc_e, lpc_cache.lpc_e_t, lpc_cache.lpc_lsf, lpc_cache.lpc_lsf_t);
%	wavwrite(y, lpc_cache.fs, 'tmp.wav');
end

function y = lpc_synth(fs, e, e_t, lsf, lsf_t)
	resample_factor = ceil(1/(fs*min(diff(e_t)))+0.5);

	% Передискретизация ошибки предсказания вверх, что бы избежать
	% наложения спектров при интерполяции
	e = resample(e,resample_factor,1);
	e(end-resample_factor+2:end) = [];
	fs = fs*resample_factor;
	e_t = interp1q((0:size(e_t,1)-1)', e_t, (0:size(e,1)-1)'/resample_factor);

	e = spline(e_t, e, (0:fix(e_t(end)*fs))'/fs);

	% Передискретизация ошибки предсказания на исходную ЧОТ
	e = resample(e,1,resample_factor);
	fs = fs/resample_factor;

	lsf = interp1q([0; lsf_t; max(lsf_t(end),(size(e,1)-1)/fs)], [lsf(1,:); lsf; lsf(end,:)], (0:size(e,1)-1)'/fs);

	y = zeros(size(e));
	[~,Z] = filter(1,lsf2poly(lsf(1,:)),0);
	for ii = 1:size(e,1)
		[y(ii),Z] = filter(1,lsf2poly(lsf(ii,:)),e(ii),Z);
	end
end
