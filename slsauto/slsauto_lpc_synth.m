function slsauto_lpc_synth(cfg, synth_t, border_type)
	if nargin<3
		border_type = 'v'; % 'v' - split to V+U regions; 'u' - split to U+V regions; 'vu' or 'uv' - split to U and V regions
	end
	border_type = lower(border_type);

	%% Загрузка данных
	lpc_cache = load(slsauto_getpath(cfg,'lpc'));
	lab = lab_read(slsauto_getpath(cfg,'lab'));
	prosody = xml_read(slsauto_getpath(cfg,'prosody'));
	pitch_vu = load(slsauto_getpath(cfg,'pitch_vu'));

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

	% КИХ НЧ фильтр Гаусса для сглаживания треков LSF на стыках блоков синтеза
	lsf_fs = lpc_cache.fs / (lpc_cache.lpc_lsf_ind(2)-lpc_cache.lpc_lsf_ind(1));
	lsf_fc = 20*2/lsf_fs;
	if lsf_fc>0.5
		lsf_b = [];
	else
		lsf_b = gaussfilter(lsf_fc, 1);
	end

	%% Основной цикл синтеза речеподобных сигналов
	synth_y = zeros(0,1);
	while size(synth_y,1)/lpc_cache.fs < synth_t
		%% Синтез очередной синтагмы
		% Определение требуемой длительности
		cur_length = interp1q(prosody.syntagm_length.cdf, prosody.syntagm_length.arg, rand()) + ...
					 interp1q(prosody.pause_length.cdf, prosody.pause_length.arg, 0.5);

		% Составление списка регионов
		reg_list = [get_region(lpc_cache, regions.start (randi(size(regions.start, 1)),:)); ...
					get_region(lpc_cache, regions.finish(randi(size(regions.finish,1)),:))];

		while sum(arrayfun(@(x) diff(x.lpc_e_t([1 end])), reg_list)) < cur_length*0.9
			reg_list = [reg_list(1:end-1); get_region(lpc_cache, regions.middle(randi(size(regions.middle,1)),:)); reg_list(end)];
		end

		% Формирование единой шкалы времени у смежных регионов синтеза
		e_t_val = 0;
		e_ind_val = 1;
		lsf_ind_val  = 1;
		for ri = 1:numel(reg_list)
			reg_list(ri).lpc_e_t = reg_list(ri).lpc_e_t - reg_list(ri).lpc_e_t(1) + e_t_val;
			e_t_val = reg_list(ri).lpc_e_t(end)*2-reg_list(ri).lpc_e_t(end-1);
			reg_list(ri).lpc_e_ind_lin = reg_list(ri).lpc_e_ind - reg_list(ri).lpc_e_ind(1) + e_ind_val;
			e_ind_val = e_ind_val + diff(reg_list(ri).lpc_e_ind) + 1;
			reg_list(ri).lpc_lsf_ind = reg_list(ri).lpc_lsf_ind - reg_list(ri).lpc_e_ind(1) + lsf_ind_val;
			lsf_ind_val = lsf_ind_val + size(reg_list(ri).lpc_e,1);
		end

		% Сглаживание переходов параметров на стыках регионов синтеза
		if ~isempty(lsf_b)
			lsf_bn = numel(lsf_b);
			lsf_bn2 = fix(numel(lsf_b)/2);
			for ri = 1:numel(reg_list)-1
				% Сглаживание LSF треков
				cur_obs = [reg_list(ri).lpc_lsf(end-lsf_bn+2:end,:); reg_list(ri+1).lpc_lsf(1:lsf_bn-1,:)];
				cur_obs = filter(lsf_b,1,cur_obs);
				reg_list(ri).lpc_lsf(end-lsf_bn2+1:end,:) = cur_obs(end-lsf_bn2+1-lsf_bn2:end-lsf_bn2,:);
				reg_list(ri+1).lpc_lsf(1:lsf_bn2,:) =       cur_obs(end-lsf_bn2+1        :end        ,:);

				% Сглаживание коэффициента усиления
				cur_obs = [reg_list(ri).lpc_b(end-lsf_bn+2:end); reg_list(ri+1).lpc_b(1:lsf_bn-1)];
				cur_obs = filter(lsf_b,1,cur_obs);
				reg_list(ri).lpc_b(end-lsf_bn2+1:end) = cur_obs(end-lsf_bn2+1-lsf_bn2:end-lsf_bn2);
				reg_list(ri+1).lpc_b(1:lsf_bn2) =       cur_obs(end-lsf_bn2+1        :end        );
			end
		end

		% Формирование контура ЧОТ
		cur_lpc_e_t = vertcat(reg_list.lpc_e_t);
		v_beg = find((reg_list(1).lpc_e_ind(1)-1)/lpc_cache.fs<=pitch_vu(:,1) & pitch_vu(:,1)<=(reg_list(1).lpc_e_ind(2)-1)/lpc_cache.fs,1);
		if isempty(v_beg)
			v_beg = size(reg_list(1).lpc_e,1);
		else
			v_beg = round(pitch_vu(v_beg,1)*lpc_cache.fs)+1 - reg_list(1).lpc_e_ind(1) + reg_list(1).lpc_e_ind_lin(1);
		end
		v_end = find((reg_list(end).lpc_e_ind(1)-1)/lpc_cache.fs<=pitch_vu(:,1) & pitch_vu(:,1)<=(reg_list(end).lpc_e_ind(2)-1)/lpc_cache.fs,1,'last');
		if isempty(v_beg)
			v_end = size(cur_lpc_e_t,1)-size(reg_list(end).lpc_e_t,1);
		else
			v_end = round(pitch_vu(v_end,1)*lpc_cache.fs)+1 - reg_list(end).lpc_e_ind(1) + reg_list(end).lpc_e_ind_lin(1);
		end
		if v_end-v_beg>=lpc_cache.fs/2
			cur_lpc_e_dt =	diff(cur_lpc_e_t) .* ...
							interp1q([0; v_beg; v_beg+prosody.intonogram.arg*(v_end-v_beg); v_end; size(cur_lpc_e_t,1)], ...
									 [1; 1; 1./(1*(prosody.intonogram.val-1)+1); 1; 1], (0:size(cur_lpc_e_t,1)-2)' );
			cur_lpc_e_t = cumsum([cur_lpc_e_t(1); cur_lpc_e_dt]);
		end

		% Синтез
		cur_y = lpc_synth(lpc_cache.fs, vertcat(reg_list.lpc_e), cur_lpc_e_t, vertcat(reg_list.lpc_lsf), vertcat(reg_list.lpc_lsf_ind), vertcat(reg_list.lpc_b));

		synth_y = [synth_y; cur_y]; %#ok<AGROW>
	end

	wav_filename = slsauto_getpath(cfg,'synth');
	if exist(wav_filename,'file')
		movefile(wav_filename, [wav_filename '.bak']);
	end
	wavwrite(synth_y, lpc_cache.fs, wav_filename);

%	y = lpc_synth(lpc_cache.fs, lpc_cache.lpc_e, lpc_cache.lpc_e_t, lpc_cache.lpc_lsf, lpc_cache.lpc_lsf_t);
%	wavwrite(y, lpc_cache.fs, 'tmp.wav');
end

function y = filter_fir_nodelay(b,x)
	n = numel(b);
	n2 = fix(n/2);
	y = filter(b,1,[repmat(x(1,:),n-1,1); x; repmat(x(end,:),n2,1)]);
	y(1:n2+n-1,:) = [];
end

function cur_reg = get_region(lpc_cache, ind)
	cur_reg = struct('lpc_e_ind',ind, 'lpc_e',lpc_cache.lpc_e(ind(1):ind(2)), 'lpc_e_t',lpc_cache.lpc_e_t(ind(1):ind(2)));
	ind_lsf = ind(1)<=lpc_cache.lpc_lsf_ind & lpc_cache.lpc_lsf_ind<=ind(2);
	cur_reg.lpc_lsf = lpc_cache.lpc_lsf(ind_lsf,:);
	cur_reg.lpc_lsf_ind = lpc_cache.lpc_lsf_ind(ind_lsf,:);
	cur_reg.lpc_b = lpc_cache.lpc_b(ind_lsf);
end

function y = lpc_synth(fs, e, e_t, lsf, lsf_ind, b)
	lsf_t = e_t(lsf_ind);

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
	b   = interp1q([0; lsf_t; max(lsf_t(end),(size(e,1)-1)/fs)], [b(1,:);   b;   b(end,:)  ], (0:size(e,1)-1)'/fs);

	a = lsf2poly_even(lsf);

	y = zeros(size(e));
	[~,Z] = filter(b(1),a(1,:),0);
	for ii = 1:size(e,1)
		[y(ii),Z] = filter(b(ii),a(ii,:),e(ii),Z);
	end
end
