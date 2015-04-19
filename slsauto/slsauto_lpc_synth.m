function slsauto_lpc_synth(cfg, synth_t, border_type)
	if nargin<3
		border_type = 'v'; % 'v' - split to V+U regions; 'u' - split to U+V regions; 'vu' or 'uv' - split to U and V regions
	end
	border_type = lower(border_type);

	%% Загрузка данных
	lpc_cache = load(slsauto_getpath(cfg,'lpc'));
	lab = lab_read(slsauto_getpath(cfg,'lab'));
	prosody = xml_read(slsauto_getpath(cfg,'prosody'));

	% Поиск границ синтагм
	ii = strcmp('#syntagm',{lab.string});
	syntagm_pos = [round([lab(ii).begin]'*lpc_cache.fs)+1; 0; size(lpc_cache.lpc_e,1)];
	syntagm_pos = sort(unique(syntagm_pos));

	% Поиск границ элементов синтеза
	ii = false(size(lab));
	for bi = 1:numel(border_type)
		ii = ii | strcmp(['#pitch_' border_type(bi)],{lab.string}');
	end
	block_pos = sort(unique( round([lab(ii).begin]'*lpc_cache.fs)+1 ));

	% Формирование списков начальных, промежуточных и конечных элементов синтеза
	regions = struct('start',zeros(0,2), 'middle',zeros(0,2), 'finish',zeros(0,2));
	for si = 1:numel(syntagm_pos)-1
		cur_syntagm = [syntagm_pos(si) syntagm_pos(si+1)];
		cur_block   = block_pos( cur_syntagm(1)<block_pos & block_pos<cur_syntagm(2) );
		regions.start(end+1,:)  = [cur_syntagm(1)+1 cur_block(1)];
		regions.finish(end+1,:) = [cur_block(end)+1 cur_syntagm(2)];
		regions.middle = [regions.middle; [cur_block(1:end-1)+1 cur_block(2:end)]];
	end

	%% Основной цикл синтеза речеподобных сигналов
	synth_y = zeros(0,1);
	while size(synth_y,1)/lpc_cache.fs < synth_t
		%% Синтез очередной синтагмы
		cur_length = interp1q(prosody.syntagm_length.cdf, prosody.syntagm_length.arg, rand()) + ...
					 interp1q(prosody.pause_length.cdf, prosody.pause_length.arg, 0.5);

		reg_list = [get_region(lpc_cache, regions.start (randi(size(regions.start, 1)),:)); ...
					get_region(lpc_cache, regions.finish(randi(size(regions.finish,1)),:))];

		while sum(arrayfun(@(x) diff(x.lpc_e_t([1 end])), reg_list)) < cur_length*0.9
			reg_list = [reg_list(1:end-1); get_region(lpc_cache, regions.middle(randi(size(regions.middle,1)),:)); reg_list(end)];
		end
		
		time_val = 0;
		for ri = 1:numel(reg_list)
			reg_list(ri).lpc_lsf_t = reg_list(ri).lpc_lsf_t - reg_list(ri).lpc_e_t(1) + time_val;
			reg_list(ri).lpc_e_t = reg_list(ri).lpc_e_t - reg_list(ri).lpc_e_t(1) + time_val;
			time_val = reg_list(ri).lpc_e_t(end)*2-reg_list(ri).lpc_e_t(end-1);
		end

		cur_y = lpc_synth(lpc_cache.fs, vertcat(reg_list.lpc_e), vertcat(reg_list.lpc_e_t), vertcat(reg_list.lpc_lsf), vertcat(reg_list.lpc_lsf_t));

		synth_y = [synth_y; cur_y]; %#ok<AGROW>
	end

	wavwrite(synth_y, lpc_cache.fs, slsauto_getpath(cfg,'synth'));

%	y = lpc_synth(lpc_cache.fs, lpc_cache.lpc_e, lpc_cache.lpc_e_t, lpc_cache.lpc_lsf, lpc_cache.lpc_lsf_t);
%	wavwrite(y, lpc_cache.fs, 'tmp.wav');
end

function cur_reg = get_region(lpc_cache, ind)
	cur_reg = struct('lpc_e',lpc_cache.lpc_e(ind(1):ind(2)), 'lpc_e_t',lpc_cache.lpc_e_t(ind(1):ind(2)));
	ind_lsf = cur_reg.lpc_e_t(1)<=lpc_cache.lpc_lsf_t & lpc_cache.lpc_lsf_t<=cur_reg.lpc_e_t(end);
	cur_reg.lpc_lsf = lpc_cache.lpc_lsf(ind_lsf,:);
	cur_reg.lpc_lsf_t = lpc_cache.lpc_lsf_t(ind_lsf,:);
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
