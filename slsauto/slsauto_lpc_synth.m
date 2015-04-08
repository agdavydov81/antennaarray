function slsauto_lpc_synth(cfg)
	cache = load(slsauto_getpath(cfg,'lpc'));
	y = lpc_synth(cache.fs, cache.lpc_e, cache.lpc_e_t, cache.lpc_lsf, cache.lpc_lsf_t);
	wavwrite(y, cache.fs, 'tmp.wav');
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
