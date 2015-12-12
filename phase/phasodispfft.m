function phasodispfft1(wav_filename)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		wav_filename = fullfile(dlg_path,dlg_name);
	end

	% Загрузкв звукового файла
	[x,fs] = wavread(wav_filename);

	% Параметры обработки сигнала
	frame_size = round(0.025 * fs);
	frame_shift = max(1,round(0.001 * fs));
	median_order = round(fs*0.050/frame_shift/2)*2+1;
	freq_high = 2000; % Обрезка по частоте

	fft_size = pow2(nextpow2(frame_size)) * 2;

	% Вычисление спектрограммы обычным способом
	[spectrum, spectrum_freq, spectrum_time] = spectrogram(x, frame_size, frame_size-frame_shift, fft_size, fs);

	% Удаление ВЧ части спектра
	if freq_high<spectrum_freq(end)
		ii = spectrum_freq>freq_high;
		spectrum(ii,:) = [];
		spectrum_freq(ii) = [];
	end
	
	% Вычисление амплитудного и фазового спектров
	specrum_amp = 20*log10(abs(spectrum));
	specrum_phase = angle(spectrum);
	
	% Обработка фазового спектра
	specrum_phase = specrum_phase - pi; % Преобразование диапазона [-pi,pi] в [-2*pi,0]
	specrum_phase = specrum_phase -  (0:size(spectrum,1)-1)'*(0:size(spectrum,2)-1)*frame_shift*2*pi/fft_size; % Приведение фазы к единому времени
	specrum_phase = rem(specrum_phase, 2*pi) + pi; % Вычитание целого количества 2*pi в приведение к диапазону [-pi,pi]

	specrum_phase = unwrap(specrum_phase, [], 2); % Сшивка фазы
	specrum_phase = filter([1 -1]/frame_shift, 1, specrum_phase, [], 2); % Дифференцирование по времени
	specrum_phase = medfilt1(specrum_phase, median_order, [], 2); % Сглаживание медианным фильтром
	
	% Отображение результатов
	[wav_path, wav_name, wav_ext] = fileparts(wav_filename);
	figure('NumberTitle','off', 'Name',[wav_name wav_ext], 'Units','normalized', 'Position',[0 0 1 1]);

	subplot(5,1,1);
	plot((0:size(x,1)-1)/fs, x);
	grid('on');
	title(wav_filename, 'Interpreter','none');
	ylabel('Осцилограмма');
	x_lim =[0 (size(x,1)-1)/fs];
	xlim(x_lim);
	colorbar;
	
	subplot(5,1,[2 3]);
	imagesc(spectrum_time, spectrum_freq, specrum_amp);
	axis('xy');
	ylabel('Амплитудный спектр, Гц');
	colorbar;

	subplot(5,1,[4 5]);
	imagesc(spectrum_time, spectrum_freq, specrum_phase);
	axis('xy');
	ylabel('Преобразованный фазовый спектр, Гц');
	xlabel('Время, с');
	colorbar;
	
	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
	set(zoom,'ActionPostCallback',@on_zoom_pan);
	zoom('xon');
end

function on_zoom_pan(hObject, eventdata) %#ok<INUSD>
%	Usage example:
%	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	zoom('xon');

	x_lim=xlim();

	data=guidata(hObject);
	if isfield(data,'user_data') && isfield(data.user_data,'x_len')
		rg=x_lim(2)-x_lim(1);
		if x_lim(1)<0
			x_lim=[0 rg];
		end
		if x_lim(2)>data.user_data.x_len
			x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
		end
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end
