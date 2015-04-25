function slsauto_pitch_editor(cfg)
	if nargin<1
		[dlg_name,dlg_path] = uigetfile({'*.wav;*.flac;*.ogg','Sound files';'*.*','All files'},'Select input sound file');
		if dlg_name==0
			return
		end
		cfg.snd_filename = fullfile(dlg_path,dlg_name);
	end
	if ischar(cfg)
		cfg = struct('snd_filename',cfg);
	end
	[snd_path,snd_name,snd_ext] = fileparts(slsauto_getpath(cfg,'snd'));
	snd_nameext = [snd_name snd_ext];
	
	[pitch_filename, is_auto] = slsauto_getpath(cfg,'pitch');
	if is_auto
		list = dir([slsauto_getpath(cfg,'snd') '.pitch_*.txt']);
		[~,si] = sort({list.name});
		list = list(si);
		if isempty(list)
			error(['Can''t find any pitch file for sound file ''' slsauto_getpath(cfg,'snd') '''.']);
		end
		if numel(list)>1
			[dlg_sel,dlg_ok] = listdlg('Name','Pitch select', 'PromptString','Select (multiple) pitch data files:', 'ListSize',[300 300], ...
									'SelectionMode','multiple', 'ListString',{list.name}, 'InitialValue',numel(list));
			if ~dlg_ok
				return
			end
			list = list(dlg_sel);
		end
		for li = 1:numel(list)
			list(li).name = fullfile(snd_path, list(li).name);
		end
	else
		list.name = pitch_filename;
	end

	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
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

	fig = figure('ToolBar','figure', 'NumberTitle','off', 'Name',snd_nameext, ...
				 'Units','normalized', 'Position',[0 0 1 1], ...
				 'WindowButtonDownFcn',@on_mouse_down, 'KeyPressFcn',@on_key_press);

	subplot.signal = axes('Units','normalized', 'Position',[0.06 0.65 0.92 0.30]);
	plot((0:size(x,1)-1)'/fs, x);
	x_lim=[0 size(x,1)-1]/fs;
	axis([x_lim max(abs(x))*1.1*[-1 1]]);
	grid('on');
	ylabel('Oscillogram');
	title(slsauto_getpath(cfg,'snd'),'Interpreter','none');
	caret=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	
	subplot.position = axes('Units','normalized', 'Position',[0.06 0.61 0.92 0.02], ...
							'XLim',x_lim, 'XTick',[], 'YLim',[0 1], 'YTick',[]);
	subplot.position_patch = patch('Vertices',[0 0 0; 0 1 0; x_lim(2) 1 0; x_lim(2) 0 0], 'Faces',[1 2 3; 1 3 4], 'FaceVertexCData',repmat([0 0 1],4,1), 'FaceColor','flat', 'EdgeColor','none');

	subplot.spectrum = axes('Units','normalized', 'Position',[0.06 0.05 0.92 0.55]);
	imagesc(X_time,X_freq,X);
	setcolormap('hsl');
	axis('xy');
	axis([x_lim 0 1000]); % fs/2
	ylabel('Spectrogram, Hz');
	xlabel('Time, sec');

	hold('on');

	for li = 1:numel(list)
		data = load(list(li).name);

		[~,cur_name] = fileparts(list(li).name);
		if strncmpi(cur_name,snd_nameext,numel(snd_nameext))
			cur_name(1:numel(snd_nameext)) = [];

			pitch_prefix = '.pitch_';
			if strncmpi(cur_name,pitch_prefix,numel(pitch_prefix))
				cur_name(1:numel(pitch_prefix)) = [];
			end
		end

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

	ctrl_pos=get(subplot.signal,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_play, 'KeyPressFcn',@on_key_press);
	uicontrol('Parent',fig, 'Style','pushbutton', 'String','Save changes', 'Units','normalized', ...
			'Position',[ctrl_pos(1) ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_save, 'KeyPressFcn',@on_key_press);
	uicontrol('Parent',fig, 'Style','pushbutton', 'String','Help', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_help, 'KeyPressFcn',@on_key_press);

	set(zoom,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@on_play_callback, 'StopFcn',@on_playstop_callback, ...
				'TimerFcn',@on_play_callback, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	fig_data = guihandles(fig);
	fig_data.user_data = struct('figure',fig, 'player',player, 'signal',x, 'x_len',x_lim(2), ...
							'subplot',subplot, 'btn_play',btn_play, ...
							'f0_data',struct('min_dt',min(dt), 'plot',data_plot, 'pathnamme',list(end).name) );
	guidata(fig,fig_data);
end

function on_zoom_pan(hObject, eventdata) %#ok<*INUSD>
%	Usage example:
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
%	zoom('xon');

	fig_data = guidata(hObject);

	x_lim = xlim();
	rg = x_lim(2)-x_lim(1);
	if isstruct(eventdata)
		if eventdata.Axes == fig_data.user_data.subplot.position % Scroll on position axes
			pv = get(fig_data.user_data.subplot.position_patch, 'Vertices');
			x_lim = (pv([1 3],1) - x_lim(1))*fig_data.user_data.x_len/rg;
		end
	else
		x_lim = eventdata;
	end

	% Fix borders
	if isfield(fig_data,'user_data') && isfield(fig_data.user_data,'x_len')
		rg = x_lim(2)-x_lim(1);
		if x_lim(1)<0
			x_lim = [0 rg];
		end
		if x_lim(2)>fig_data.user_data.x_len
			x_lim = [max(0, fig_data.user_data.x_len-rg) fig_data.user_data.x_len];
		end
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim',x_lim);

	pv = get(fig_data.user_data.subplot.position_patch, 'Vertices');
	rg = x_lim(2)-x_lim(1);
	pv([1 2],1) = x_lim(1) + x_lim(1)*rg/fig_data.user_data.x_len;
	pv([3 4],1) = x_lim(1) + x_lim(2)*rg/fig_data.user_data.x_len;
	set(fig_data.user_data.subplot.position_patch, 'Vertices',pv);
end

function on_play(hObject, eventdata)
	fig_data = guidata(hObject);
	if not(isplaying(fig_data.user_data.player))
		x_lim=min(fig_data.user_data.player.TotalSamples,max(1,round( xlim(fig_data.user_data.subplot.signal)*fig_data.user_data.player.SampleRate+1 )));
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
	posn_pos = get(fig_data.user_data.subplot.position, 'Position');
	if	mouse_pos(1)>=posn_pos(1) && mouse_pos(1)<=posn_pos(1)+posn_pos(3) && ...
		mouse_pos(2)>=posn_pos(2) && mouse_pos(2)<=posn_pos(2)+posn_pos(4)
			on_mouse_down_position(hObject, fig_data, mouse_pos, posn_pos);
	end

	spec_pos = get(fig_data.user_data.subplot.spectrum, 'Position');
	if	mouse_pos(1)>=spec_pos(1) && mouse_pos(1)<=spec_pos(1)+spec_pos(3) && ...
		mouse_pos(2)>=spec_pos(2) && mouse_pos(2)<=spec_pos(2)+spec_pos(4)
			on_mouse_down_spectrum(hObject, fig_data, mouse_pos, spec_pos);
	end
end

function on_mouse_down_position(hObject, fig_data, mouse_pos, posn_pos) %#ok<*INUSL>
	x_lim = get(fig_data.user_data.subplot.position, 'XLim');
	rg = x_lim(2)-x_lim(1);

	x_lim = fig_data.user_data.x_len*(mouse_pos(1)-posn_pos(1))/posn_pos(3) + [-0.5 0.5]*rg;

	on_zoom_pan(fig_data.user_data.figure,x_lim);
end

function on_mouse_down_spectrum(hObject, fig_data, mouse_pos, spec_pos)
	scr_sz = get(0,'ScreenSize');
	pix_mouse_pos = round(mouse_pos.*scr_sz([3 4]));

	x_lim = get(fig_data.user_data.subplot.spectrum, 'XLim');
	y_lim = get(fig_data.user_data.subplot.spectrum, 'YLim');
	mouse_pos = [(mouse_pos(1)-spec_pos(1))*diff(x_lim)/spec_pos(3) + x_lim(1) ...
				 (mouse_pos(2)-spec_pos(2))*diff(y_lim)/spec_pos(4) + y_lim(1)];

	f0_data = fig_data.user_data.f0_data;
	xdata = get(f0_data.plot, 'XData');
	ydata = get(f0_data.plot, 'YData');
	[time_mv,time_mi] = min(abs(xdata-mouse_pos(1)));

	spec_pos = get(fig_data.user_data.subplot.spectrum, 'Position');
	pix_xdata = ((xdata-x_lim(1))*spec_pos(3)/(x_lim(2)-x_lim(1))+spec_pos(1)) * scr_sz(3);
	pix_ydata = ((ydata-y_lim(1))*spec_pos(4)/(y_lim(2)-y_lim(1))+spec_pos(2)) * scr_sz(4);
	pix_dist = pdist2([pix_xdata(:) pix_ydata(:)],pix_mouse_pos);
	[pix_mv,pix_mi] = min(pix_dist);
	pix_radius = 10;
	
	action_type = [{get(hObject,'SelectionType')} get(hObject,'CurrentModifier')];
%	disp(action_type);
	if isequal(action_type,{'normal'})	% Left button
		if pix_mv<pix_radius
			ydata(pix_mi) = ydata(pix_mi)*2;
		end
	elseif isequal(action_type,{'alt'})	% Right button
		if pix_mv<pix_radius
			ydata(pix_mi) = ydata(pix_mi)/2;
		end
	elseif isequal(action_type,{'extend' 'shift'}) % Shift + Left button
		if time_mv<f0_data.min_dt/2
			ydata(time_mi) = mouse_pos(2);
		else
			% Rounding position to grid
			dt0 = rem(min(xdata),f0_data.min_dt);
			mouse_pos(1) = round((mouse_pos(1)-dt0)/f0_data.min_dt)*f0_data.min_dt+dt0;
			% Inserting new value
			ii = min([find(xdata>mouse_pos(1)-f0_data.min_dt/2,1) numel(xdata)+1]);
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
	elseif isequal(action_type,{'alt' 'control'}) % Ctrl + Left button
		if pix_mv<pix_radius
			xdata(pix_mi) = nan;
			ydata(pix_mi) = nan;
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
	fig_data = guidata(hObject);
	x_lim = get(fig_data.user_data.subplot.signal, 'XLim');
	rg = x_lim(2)-x_lim(1);
	switch eventdata.Key
		case 'f1'
			on_help(fig_data.user_data.figure);
			return
		case 'space'
			on_play(fig_data.user_data.figure);
			return
		case {'leftarrow' 'z'}
			x_lim = x_lim - rg*0.25;
		case {'rightarrow' 'x'}
			x_lim = x_lim + rg*0.25;
		case {'pageup' 'a'}
			x_lim = x_lim - rg*0.90;
		case {'pagedown' 's'}
			x_lim = x_lim + rg*0.90;
		case {'home' 'q'}
			x_lim = [0 rg];
		case {'end' 'w'}
			x_lim = fig_data.user_data.x_len + [-rg 0];
		case 'uparrow'
			x_lim = mean(x_lim) + 1/1.6180339887498948482*[-0.5 0.5]*rg;
		case 'downarrow'
			x_lim = mean(x_lim) +   1.6180339887498948482*[-0.5 0.5]*rg;
	end
	on_zoom_pan(fig_data.user_data.figure,x_lim);
end

function on_save(hObject, eventdata)
	fig_data = guidata(hObject);

	f0_data = fig_data.user_data.f0_data;
	[~,~,rep_ext] = fileparts(f0_data.pathnamme);

	[dlg_name,dlg_path] = uiputfile({['*' rep_ext],['Report files (' rep_ext ')']}, 'Select report save file', f0_data.pathnamme);
	if dlg_name==0
		return
	end
	rep_filename = fullfile(dlg_path, dlg_name);
	[~,~,rep_ext] = fileparts(rep_filename);

	data_x = get(f0_data.plot, 'XData');
	data_y = get(f0_data.plot, 'YData');
	data = [data_x(:) data_y(:)];
	data(any(isnan(data),2),:) = []; %#ok<NASGU>
	save_arg = {rep_filename, 'data'};
	if strcmpi(rep_ext,'.txt')
		save_arg{end+1} = '-ascii';
	end
	save(save_arg{:});
end

function on_help(hObject, eventdata)
	helpdlg({	'Mouse hotkeys:'
				'   LeftButton -            Double F0 estimation at this position'
				'   RightButton -         Half F0 estimation at this position'
				'   Shift + LeftButton - Add/Set F0 estimation at this position'
				'   Ctrl + LeftButton -   Delete F0 estimation at this position'
				''
				'Keyboard hotkeys:'
				'   F1 -                        Display this help'
				'   Space -                  Play signal in the view'
				'   Z or LeftArrow -      Scroll to the Left  on 25% of the view'
				'   X or RightArrow -   Scroll to the Right on 25% of the view'
				'   A or PageDown -   Scroll to the Left  on 90% of the view'
				'   S or PageUp -        Scroll to the Right on 90% of the view'
				'   Q or Home -           Scroll to the Beginning of the signal'
				'   W or End -             Scroll to the End of the signal'
				'   UpArrow -               ZoomIn'
				'   DownArrow -          ZoomOut'
				},'Keys help');
end
