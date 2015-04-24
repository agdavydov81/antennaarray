function slsauto_lpc_analyse(cfg, frame_size, frame_shift)
	% Загрузка звукового файла
	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	if ~isempty(x_info.Error)
		error(x_info.Error);
	end
	x = x(:,1);
	fs = x_info.SampleRate;
	
	if nargin<2 || isempty(frame_size)
		frame_size = 0.020;
	end
	if nargin<3 || isempty(frame_shift)
		frame_shift = 0.001;
	end

	%% Выравнивание ЧОТ - получение монотонной речи
	% Разделение на ЧОТ и огибающую
	[lpc_e lpc_lsf_ind lpc_lsf lpc_b] = lpc_analyse_signal(x, fs, frame_size, frame_shift); %#ok<*NASGU,*ASGLU>

	% Загрузка и подготовка данных ЧОТ
	pitch_data = load(slsauto_getpath(cfg,'pitch'));
	pitch_data(:,2) = pitch_data(:,2)/median(pitch_data(:,2));
	pitch_data = [pitch_data(1,:); pitch_data; pitch_data(end,:)];
	pitch_data(1,1) = -1;
	pitch_data(end,1) = size(lpc_e,1)/fs+10;

	% Формирование новой временной шкалы с выравненной ЧОТ
	pitch_interp = interp1q(pitch_data(:,1), pitch_data(:,2), (0:size(lpc_e,1)-1)'/fs);
	lpc_e_t = cumsum(pitch_interp)/fs;
	lpc_e_t = [0; lpc_e_t(1:end-1)];
%	lpc_lsf_t = lpc_e_t(lpc_lsf_ind);

	% Сохранение параметров для будущего синтеза с параметрами выравненной ЧОТ
	save(slsauto_getpath(cfg,'lpc'),'fs','lpc_e','lpc_e_t','lpc_lsf','lpc_lsf_ind','lpc_b');
end

function [lpc_e lpc_ind lpc_lsf lpc_b] = lpc_analyse_signal(x, fs, frame_size, frame_shift, lpc_order, is_power_norm)
	x_size =      size(x,1);
	frame_size =  round(frame_size*fs);
	frame_shift = max(1,round(frame_shift*fs));
	if nargin<5
		lpc_order = round(1.5*fs/2000)*2; % Использование четного порядка модели предсказания позволяет значительно ускорить lsf2poly
	end
	if nargin<6
		is_power_norm = true;
	end

	frame_size2 =  fix(frame_size/2);
	frame_shift2 = fix(frame_shift/2);
	if frame_shift2+lpc_order > frame_size2
		frame_shift2 = frame_size2-lpc_order;
		frame_shift  = frame_shift2*2;
	end

	lpc_ind = (1+frame_shift2:frame_shift:x_size)';

	lpc_e = cell(size(lpc_ind));

	is_calc_lsf = false;
	if nargout>=3
		lpc_lsf = zeros(size(lpc_ind,1),lpc_order);
		is_calc_lsf = true;
	end
	is_calc_b = false;
	if nargout>=4
		lpc_b = zeros(size(lpc_ind));
		is_calc_b = true;
	end

	cur_win = hann(frame_size);

	parfor i=1:size(lpc_e,1) % parfor
		cur_rg = lpc_ind(i) + [0 frame_size-1] - frame_size2;
		cur_rgx = min(x_size,max(1,cur_rg));
		cur_x = [zeros(cur_rgx(1)-cur_rg(1),1); x(cur_rgx(1):cur_rgx(2)); zeros(cur_rg(2)-cur_rgx(2),1)]; %#ok<PFBNS>

		[cur_a, cur_ep] = lpc(cur_x.*cur_win, lpc_order);
		if isnan(cur_ep)
			cur_a = [1 zeros(1,lpc_order)];
			cur_ep = 0;
		end

		if is_calc_lsf
			lpc_lsf(i,:) = poly2lsf(cur_a);
		end
		if is_calc_b
			lpc_b(i) = sqrt(cur_ep);
		end

		if is_power_norm
			cur_a = cur_a/sqrt(cur_ep);
		end
		cur_e = filter(cur_a, 1, cur_x(frame_size2-frame_shift2-lpc_order+1 : frame_size2+frame_shift-frame_shift2));
		lpc_e{i} = cur_e(lpc_order+1:end);
	end

	lpc_e = cell2mat(lpc_e);
end
