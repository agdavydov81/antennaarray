function slsauto_lpc_synth(cfg, synth_t, border_type)
	if nargin<3
		border_type = 'v'; % 'v' - split to V+U regions; 'u' - split to U+V regions; 'vu' or 'uv' - split to U and V regions
	end

	%% Загрузка данных
	lpc_cache = load(slsauto_getpath(cfg,'lpc'));
	pitch_uv = load(slsauto_getpath(cfg,'pitch_uv'));
	lab = lab_read(slsauto_getpath(cfg,'lab'));
	syntagm_pos = [round([lab.begin lab.end]*lpc_cache.fs)+1 0 size(lpc_cache.lpc_e,1)];
	syntagm_pos = sort(unique(syntagm_pos));
	prosody = xml_read(slsauto_getpath(cfg,'prosody'));

	regions.start = [];

	%% Основной цикл синтеза речеподобных сигналов
	synth_y = zeros(0,1);
	while size(synth_y,1)/lpc_cache.fs < synth_t
		%% Синтез очередной синтагмы
		cur_y = randn(1000,1);
		
		
		synth_y = [synth_y; cur_y];
	end
	
	wavwrite(synth_y, lpc_cache.fs, slsauto_getpath(cfg,'synth'));

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
