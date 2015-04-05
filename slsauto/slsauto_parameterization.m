function slsauto_parameterization(cfg)
	% Загрузка звукового файла
	[x,x_info] = libsndfile_read(cfg.snd_pathname);
	if ~isempty(x_info.Error)
		error(x_info.Error);
	end
	x = x(:,1);
	x = single(x);
	fs = x_info.SampleRate;
	
	%% Выравнивание ЧОТ - получение монотонной речи
	% Разделение на ЧОТ и огибающую
	[lpc_e lpc_lsf_ind lpc_lsf] = lpc_analyse(x, fs, 0.020, 0.001);
	
	% Передискретизация ошибки предсказания в 2 раза, что бы избежать
	% наложения спектров при интерполяции
	lpc_e = resample(lpc_e,2,1);
	fs = fs*2;

	% Загрузка и подготовка данных ЧОТ
	pitch_data = load(slsauto_getpath(cfg,'pitch'));
	pitch_data(:,2) = median(pitch_data(:,2))./pitch_data(:,2);
	pitch_data = [pitch_data(1,:); pitch_data; pitch_data(end,:)];
	pitch_data(1,1) = 0;
	pitch_data(end,1) = size(lpc_e,1)/fs+10;

	% Формирование новой временной шкалы с выравненной ЧОТ
	t_pos = 0;
	t_end = (size(lpc_e,1)-1)/fs;
	t_line = nan(round(size(lpc_e,1)*1.3),1);
	t_ind = 1;
	while t_pos<t_end
		t_line(t_ind) = t_pos;
		t_pos = t_pos + interp1q(pitch_data(:,1),pitch_data(:,2),t_pos)/fs;
		t_ind = t_ind + 1;
	end
	t_line(isnan(t_line)) = [];
	mono_time = t_line(1:2:end);
	save(slsauto_getpath(cfg,'mono_time'),'mono_time','-ascii');

	% Интерполяция ошибки предсказанитя для выравнивания кривой ЧОТ
	lpc_e = interp1q((0:size(lpc_e,1)-1)'/fs, lpc_e, t_line);

	% Передискретизация ошибки предсказания на исходную ЧОТ
	lpc_e = resample(lpc_e,1,2);
	fs = fs/2;

	% Синхронизация спектральных параметров и выравненной по ЧОТ ошибки предсказания
	lpc_lsf = interp1q((lpc_lsf_ind-1)/fs, lpc_lsf, mono_time);
	assert(size(lpc_lsf,1) == size(lpc_e,1));
	
	% Сохранение параметров для будущего синтеза
	save(slsauto_getpath(cfg,'mono_lpc'),'lpc_e','lpc_lsf_ind','lpc_lsf');

	% Синтез нового сигнала
	y = lpc_synth(lpc_e, lpc_pos, lpc_lsf);
	wavwrite(y,fs,'tmp_y.wav');
end

function [lpc_e lpc_ind lpc_lsf lpc_b] = lpc_analyse(x, fs, frame_size, frame_shift, lpc_order)
	x_size =      size(x,1);
	frame_size =  round(frame_size*fs);
	frame_shift = max(1,round(frame_shift*fs));
	if nargin<5
		lpc_order = round(1.5*fs/1000);
	end

	frame_size2 =  fix(frame_size/2);
	frame_shift2 = fix(frame_shift/2);
	if frame_shift2+lpc_order > frame_size2
		frame_shift2 = frame_size2-lpc_order;
		frame_shift  = frame_shift2*2;
	end

	lpc_ind = (1+frame_shift2:frame_shift:x_size)';

	lpc_e = cell(size(lpc_ind));
	lpc_lsf = zeros(size(lpc_ind,1),lpc_order,'single');
	lpc_b = zeros(size(lpc_ind),'single');

	cur_win = hann(frame_size);

	parfor i=1:size(lpc_e,1) % parfor
		cur_rg = lpc_ind(i) + [0 frame_size-1] - frame_size2;
		cur_rgx = min(x_size,max(1,cur_rg));
		cur_x = double([zeros(cur_rgx(1)-cur_rg(1),1); x(cur_rgx(1):cur_rgx(2)); zeros(cur_rg(2)-cur_rgx(2),1)]);

		[cur_a, cur_ep] = lpc(cur_x.*cur_win, lpc_order);
		if isnan(cur_ep)
			cur_a = [1 zeros(1,lpc_order)];
			cur_ep = 0;
		end
		lpc_lsf(i,:) = poly2lsf(cur_a);
		lpc_b(i) = sqrt(cur_ep);

		cur_e = filter(cur_a, 1, cur_x(frame_size2-frame_shift2-lpc_order+1 : frame_size2+frame_shift-frame_shift2));
		lpc_e{i} = cur_e(lpc_order+1:end);
	end

	lpc_e = cell2mat(lpc_e);
end

function y = lpc_synth(e, a, b)
	y = zeros(size(e));
	if isempty(e)
		return
	end

	[~,Z] = filter(b(1,:),a(1,:),0);
	for ii = 1:size(e,1)
		[y(ii),Z] = filter(b(ii,:),a(ii,:),e(ii),Z);
	end
end
