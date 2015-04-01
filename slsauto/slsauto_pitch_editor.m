function slsauto_pitch_editor(snd_pathname)
	if nargin<1
		[dlg_name,dlg_path] = uigetfile({'*.wav;*.flac;*.ogg','Sound files';'*.*','All files'},'Select input sound file');
		if dlg_name==0
			return
		end
		snd_pathname = fullfile(dlg_path,dlg_name);
	end

	list = dir([snd_pathname '.pitch_*.txt']);
	[~,si] = sort({list.name});
	list = list(si);
	if isempty(list)
		error(['Can''t find any pitch file for sound file ''' snd_pathname '''.']);
	end
	if nargin<1
		[dlg_sel,dlg_ok] = listdlg('Name','Pitch select', 'PromptString','Select a pitch data file:', 'ListSize',[300 300], ...
								'SelectionMode','single', 'ListString',{list.name}, 'InitialValue',numel(list));
		if ~dlg_ok
			return
		end
		list = [list; list(dlg_sel)];
		list(dlg_sel) = [];
	end

	[x,x_info] = libsndfile_read(snd_pathname);
	if ~isempty(x_info.Error)
		error(x_info.Error);
	end
	x(:,2:end) = [];
	if x_info.SampleRate~=8000
		x = resample(x, 8000, x_info.SampleRate);
		x_info.SampleRate = 8000;
	end
	fs = x_info.SampleRate;

	frame_size = round(0.040*fs);
	frame_shift= round(0.010*fs);
	[X,X_freq,X_time]=spectrogram(x, frame_size, frame_size-frame_shift, pow2(2+ceil(log2(frame_size))), fs);
	X=10*log10(X.*conj(X));
	X_time=X_time(:);

	[snd_path,snd_name,snd_ext] = fileparts(snd_pathname);
	fig = figure('ToolBar','figure', 'NumberTitle','off', 'Name',[snd_name snd_ext], ...
				 'Units','normalized', 'Position',[0 0 1 1], ...
				 'WindowButtonDownFcn',@on_mouse_down, 'KeyPressFcn',@on_key_press);

	signal_subplot=axes('Units','normalized', 'Position',[0.06 0.65 0.92 0.30]);
	plot((0:size(x,1)-1)'/fs, x);
	x_lim=[0 size(x,1)-1]/fs;
	axis([x_lim max(abs(x))*1.1*[-1 1]]);
	grid('on');
	ylabel('Oscillogram');
	title(snd_pathname,'Interpreter','none');
	caret=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	
	spectrum_subplot=axes('Units','normalized', 'Position',[0.06 0.05 0.92 0.55]);
	imagesc(X_time,X_freq,X);
	setcolormap('hsl');
	axis('xy');
	axis([x_lim 0 1000]); % fs/2
	ylabel('Spectrogram, Hz');
	xlabel('Time, sec');

	hold('on');

	for li = 1:numel(list)
		data = load(fullfile(snd_path,list(li).name));
		cur_name = list(li).name;
		cur_name(1:numel([snd_name snd_ext])) = [];
		cur_name(1:numel('.pitch_')) = [];
		cur_name(end-numel('.txt')+1:end) = [];
		cur_label = regexp(cur_name,'\(.*\)$','match','once');
		cur_name(end-numel(cur_label)+1:end) = [];
		list(li).legend = cur_name;
		if isempty(cur_label)
			rand_clr = 'bgrcmyk';
			rand_mrk = '.ox+*sdv^<>ph';
			cur_label = [rand_clr(randi(numel(rand_clr))) rand_mrk(randi(numel(rand_mrk)))];
		else
			cur_label([1 end]) = [];
		end

		dt = diff(data(:,1));
		voc_reg = find(dt>=min(dt)*1.5);
		for vi = numel(voc_reg):-1:1
			data = [data(1:voc_reg(vi),:); nan nan; data(voc_reg(vi)+1:end,:)];
		end

		data_plot = plot(data(:,1), data(:,2), cur_label, 'LineWidth',2);
	end
	legend({list.legend}, 'Interpreter','none', 'Location','NW');

	caret(end+1)=line([0 0], ylim(), 0.1+[0 0], 'Color','r', 'LineWidth',2);

	ctrl_pos=get(signal_subplot,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_play);
	btn_save=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Save changes', 'Units','normalized', ...
			'Position',[ctrl_pos(1) ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_save);

	set(zoom,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@on_play_callback, 'StopFcn',@on_playstop_callback, ...
				'TimerFcn',@on_play_callback, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	fig_data = guihandles(fig);
	fig_data.user_data = struct('player',player, 'frame_size',frame_size, 'frame_shift',frame_shift, ...
							'signal',x, 'x_len',x_lim(2), ...
							'signal_subplot',signal_subplot, 'spectrum_subplot',spectrum_subplot, 'btn_play',btn_play, 'btn_save',btn_save, ...
							'f0_data',struct('data',data, 'min_dt',min(dt), 'plot',data_plot, 'pathnamme',fullfile(snd_path,list(end).name)) );
	guidata(fig,fig_data);
end

function on_zoom_pan(hObject, eventdata) %#ok<*INUSD>
%	Usage example:
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	set(pan ,'ActionPostCallback',@on_zoom_pan);
%	zoom('xon');
%	set(pan, 'Motion', 'horizontal');

	x_lim=xlim();

	fig_data = guidata(hObject);
	if isfield(fig_data,'user_data') && isfield(fig_data.user_data,'x_len')
		rg=x_lim(2)-x_lim(1);
		if x_lim(1)<0
			x_lim=[0 rg];
		end
		if x_lim(2)>fig_data.user_data.x_len
			x_lim=[max(0, fig_data.user_data.x_len-rg) fig_data.user_data.x_len];
		end
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end

function on_play(hObject, eventdata)
	fig_data = guidata(hObject);
	if not(isplaying(fig_data.user_data.player))
		x_lim=min(fig_data.user_data.player.TotalSamples,max(1,round( xlim()*fig_data.user_data.player.SampleRate+1 )));
		play(fig_data.user_data.player, x_lim);
		set(fig_data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(fig_data.user_data.player);
	end
end

function on_play_callback(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end
end

function on_playstop_callback(obj, event, string_arg)
	on_play_callback(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');
end

function on_mouse_down(hObject, eventdata)
	fig_data = guidata(hObject);

	mouse_pos = get(hObject, 'CurrentPoint');
	spec_pos = get(fig_data.user_data.spectrum_subplot,'Position');
	if	mouse_pos(1)<spec_pos(1) || mouse_pos(1)>spec_pos(1)+spec_pos(3) || ...
		mouse_pos(2)<spec_pos(2) || mouse_pos(2)>spec_pos(2)+spec_pos(4)
		return
	end

	x_lim = get(fig_data.user_data.spectrum_subplot, 'XLim');
	y_lim = get(fig_data.user_data.spectrum_subplot, 'YLim');
	mouse_pos = [(mouse_pos(1)-spec_pos(1))*diff(x_lim)/spec_pos(3) + x_lim(1) ...
				 (mouse_pos(2)-spec_pos(2))*diff(y_lim)/spec_pos(4) + y_lim(1)];

	f0_data = fig_data.user_data.f0_data;
	xdata = get(f0_data.plot, 'XData');
	ydata = get(f0_data.plot, 'YData');
	[mv,mi] = min(abs(xdata-mouse_pos(1)));

	action_type = [{get(hObject,'SelectionType')} get(hObject,'CurrentModifier')];
%	disp(action_type);
	if isequal(action_type,{'normal'})	% Left button down
		if mv<f0_data.min_dt/2
			ydata(mi) = ydata(mi)*2;
		end
	elseif isequal(action_type,{'alt'})	% Right button down
		if mv<f0_data.min_dt/2
			ydata(mi) = ydata(mi)/2;
		end
	elseif isequal(action_type,{'open'})% Left or Right double-click
		if mv<f0_data.min_dt/2
			ydata(mi) = mouse_pos(2);
		end
	elseif isequal(action_type,{'extend' 'shift'}) % Shift + Left button down
		if mv<f0_data.min_dt/2
			ydata(mi) = mouse_pos(2);
		else
			% Rounding position to grid
			dt0 = rem(min(xdata),f0_data.min_dt);
			mouse_pos(1) = round((mouse_pos(1)-dt0)/f0_data.min_dt)*f0_data.min_dt+dt0;
			% Inserting new value
			ii = find(xdata>mouse_pos(1)-f0_data.min_dt/2,1);
			xdata = [xdata(1:ii-1) nan mouse_pos(1) nan xdata(ii:end)];
			ydata = [ydata(1:ii-1) nan mouse_pos(2) nan ydata(ii:end)];
			% Merge NAN values
			ii = [isnan(xdata(1:end-1)) & isnan(xdata(2:end)), false];
			xdata(ii) = [];
			ydata(ii) = [];
			% Merge vocal region - remove extra NANs
			ii = [false, xdata(3:end)-xdata(1:end-2) < (f0_data.min_dt*1.5), false];
			xdata(ii) = [];
			ydata(ii) = [];
			set(f0_data.plot, 'XData',xdata);
		end
	elseif isequal(action_type,{'alt' 'control'}) % Ctrl + Left button down
		if mv<f0_data.min_dt/2
			xdata(mi) = nan;
			ydata(mi) = nan;
			ii = [isnan(xdata(1:end-1)) & isnan(xdata(2:end)), false]; % Merge NAN values
			xdata(ii) = [];
			ydata(ii) = [];
			set(f0_data.plot, 'XData',xdata);
		end
	else
		return
	end

	set(f0_data.plot, 'YData',ydata);
end

function on_key_press(hObject, eventdata)
%{
	shift_steps=0;
	switch eventdata.Key
		case 'space'
			OnPlaySignal(hObject);
		case 'leftarrow'
			shift_steps=-1;
		case 'rightarrow'
			shift_steps=1;
		case 'pageup'
			shift_steps=-10;
		case 'pagedown'
			shift_steps=10;
		case 'home'
			shift_steps=-inf;
		case 'end'
			shift_steps=inf;
	end
	if any(strcmp(eventdata.Modifier,'shift'))
		shift_steps=shift_steps*5;
	end
	if any(strcmp(eventdata.Modifier,'control'))
		shift_steps=shift_steps*20;
	end
	if shift_steps
		data = guidata(hObject);
		stat_caret_x=get(data.user_data.stat_caret(1), 'XData');
		UpdateFrameStat(data, mean(stat_caret_x([2 3]))+data.user_data.frame_shift*shift_steps/data.user_data.player.SampleRate);
	end
%}
end

function on_save(hObject, eventdata)
	fig_data = guidata(hObject);

	f0_data = fig_data.user_data.f0_data;
	[~,~,rep_ext] = fileparts(f0_data.pathnamme);

	[dlg_name,dlg_path] = uiputfile({['*' rep_ext],['Report files (' rep_ext ')']}, 'Select report save file', f0_data.pathnamme);
	if dlg_name==0
		return
	end
	rep_pathname = fullfile(dlg_path, dlg_name);
	[~,~,rep_ext] = fileparts(rep_pathname);

	data_x = get(f0_data.plot, 'XData');
	data_y = get(f0_data.plot, 'YData');
	data = [data_x(:) data_y(:)];
	data(any(isnan(data),2),:) = [];
	save_arg = {rep_pathname, 'data'};
	if strcmpi(rep_ext,'.txt')
		save_arg{end+1} = '-ascii';
	end
	save(save_arg{:});
end