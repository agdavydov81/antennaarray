function slsauto_parameterization(snd_pathname, lab_pathname, pitch_pathname, prosody_pathname)
	if nargin<2 || isempty(lab_pathname)
		lab_pathname = slsauto_makepath(snd_pathname, 'lab');
	end
	if nargin<3 || isempty(pitch_pathname)
		pitch_pathname = slsauto_makepath(snd_pathname, 'pitch');
	end
	if nargin<4 || isempty(prosody_pathname)
		prosody_pathname = slsauto_makepath(snd_pathname, 'prosody');
	end
	
	% Загрузка звукового файла
	[x,x_info] = libsndfile_read(snd_pathname);
	if ~isempty(x_info.Error)
		error(x_info.Error);
	end
	x(:,2:end) = [];
	fs = x_info.SampleRate;
	
	%% Выравнивание ЧОТ - получение монотонной речи
	% Разделение на ЧОТ и огибающую
	[e lpc_a] = elpc(x, round(0.020*fs), round(1.5*fs/1000), false);

	% Передискретизация ошибки предсказания в 2 раза, что бы избежать
	% наложения спектров при интерполяции
	e = resample(e,2,1);
	fs = fs*2;

	% Загрузка и подготовка данных ЧОТ
	pitch_data = load(pitch_pathname);
	pitch_data(:,2) = median(pitch_data(:,2))./pitch_data(:,2);
	pitch_data = [pitch_data(1,:); pitch_data; pitch_data(end,:)];
	pitch_data(1,1) = 0;
	pitch_data(end,1) = size(e,1)/fs+10;

	% Формирование новой временной шкалы с выравненной ЧОТ
	t_pos = 0;
	t_end = (size(e,1)-1)/fs;
	t_line = nan(round(size(e,1)*1.3),1);
	t_ind = 1;
	while t_pos<t_end
		t_line(t_ind) = t_pos;
		t_pos = t_pos + interp1q(pitch_data(:,1),pitch_data(:,2),t_pos)/fs;
		t_ind = t_ind + 1;
	end
	t_line(isnan(t_line)) = [];

	% Интерполяция ошибки предсказанитя для выравнивания кривой ЧОТ
	e = interp1q((0:size(e,1)-1)'/fs, e, t_line);

	% Передискретизация ошибки предсказания на исходную ЧОТ
	e = resample(e,1,2);
	fs = fs/2;
	
	% Синхронизация спектральных переметров и выравненной по ЧОТ ошибки предсказания
	lsf = zeros(size(lpc_a,1),size(lpc_a,2)-1);
	parfor ii = 1:size(lpc_a,1)
		lsf(ii,:) = poly2lsf(lpc_a(ii,:)).';
	end
	lsf = interp1q((0:size(lsf,1)-1)'/fs, lsf, t_line(1:2:end));
	assert(size(lsf,1) == size(e,1));
	lpc_a = zeros(size(lsf,1), size(lsf,2)+1);
	parfor ii = 1:size(lpc_a,1)
		lpc_a(ii,:) = lsf2poly(lsf(ii,:));
	end

	% Синтез нового сигнала
	y = elpc_synth(e, lpc_a, ones(size(lpc_a,1),1));
	wavwrite(y,fs,'tmp_y.wav');
end

function [e lpc_a lpc_b] = elpc(x, fr_sz, lpc_ord, is_power_norm)
	fr_sz_l=fix(fr_sz/2-1);

	e=zeros(size(x));
	x=[zeros(fr_sz_l,1); x; zeros(fr_sz-1-fr_sz_l,1)];
	safe_lpc_a = nargout>1;
	safe_lpc_b = nargout>2;
	if safe_lpc_a
		lpc_a = cell(size(e));
	end
	if safe_lpc_b
		lpc_b = zeros(size(e));
	end

	cur_win=hann(fr_sz);
	parfor i=1:size(e,1) % parfor
		cur_x=x(i:i+fr_sz-1).*cur_win; %#ok<PFBNS>

		[cur_a, cur_ep]=safe_lpc(cur_x, lpc_ord);
		cur_b = sqrt(cur_ep);
		if is_power_norm
			cur_a = cur_a/cur_b;
		end
		if safe_lpc_a
			lpc_a{i} = cur_a;
		end
		if safe_lpc_b
			lpc_b(i) = cur_b;
		end

		e(i)=cur_a*cur_x(fr_sz_l:-1:fr_sz_l-lpc_ord);
	end

	if nargout>1
		lpc_a = cell2mat(lpc_a);
	end
end

function [a,E]=safe_lpc(x, N)
	[a,E]=lpc(x,N);
	fix_ind=isnan(E);
	E(fix_ind)=0;
	a(fix_ind,:)=0;
	a(fix_ind,1)=1;
end

function y = elpc_synth(e, a, b)
	y = zeros(size(e));
	if isempty(e)
		return
	end

	[~,Z] = filter(b(1,:),a(1,:),0);
	for ii = 1:size(e,1)
		[y(ii),Z] = filter(b(ii,:),a(ii,:),e(ii),Z);
	end
end
