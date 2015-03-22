function slsauto_plotpitch(snd_pathname)
	list = dir([snd_pathname '.pitch_*.txt']);
	[~,si] = sort({list.name});
	list = list(si);

	[x,x_info] = libsndfile_read(snd_pathname);
	x(:,2:end) = [];
	if x_info.SampleRate~=8000
		x = resample(x, 8000, x_info.SampleRate);
		x_info.SampleRate = 8000;
	end
	fs = x_info.SampleRate;

	frame_size = round(0.025*fs);
	frame_shift= round(0.010*fs);
	[X,X_freq,X_time]=spectrogram(x, frame_size, frame_size-frame_shift, pow2(2+ceil(log2(frame_size))), fs);
	X=10*log10(X.*conj(X));
	X_time=X_time(:);

	[snd_path,snd_name,snd_ext] = fileparts(snd_pathname);
	fig = figure('ToolBar','figure', 'NumberTitle','off', 'Name',[snd_name snd_ext], 'Units','normalized', 'Position',[0 0 1 1]);
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
		data((data(:,2)==0),2) = nan;
		plot(data(:,1), data(:,2), cur_label, 'LineWidth',2);
	end
	legend({list.legend}, 'Interpreter','none', 'Location','NW');
	
	caret(end+1)=line([0 0], ylim(), 0.1+[0 0], 'Color','r', 'LineWidth',2);

	ctrl_pos=get(signal_subplot,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @on_play);

	set(zoom,'ActionPostCallback',@on_zoom_pan);
	set(pan ,'ActionPostCallback',@on_zoom_pan);
	zoom('xon');
	set(pan, 'Motion', 'horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@on_play_callback, 'StopFcn',@on_playstop_callback, ...
				'TimerFcn',@on_play_callback, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	data.user_data = struct('player',player, 'frame_size',frame_size, 'frame_shift',frame_shift, ...
		'signal',x, 'x_len',x_lim(2), 'signal_subplot',signal_subplot, 'spectrum_subplot',spectrum_subplot, 'btn_play',btn_play);
	guidata(fig,data);
end

function on_zoom_pan(hObject, eventdata) %#ok<INUSD>
%	Usage example:
%	set(zoom,'ActionPostCallback',@on_zoom_pan);
%	set(pan ,'ActionPostCallback',@on_zoom_pan);
%	zoom('xon');
%	set(pan, 'Motion', 'horizontal');

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

function on_play(hObject, eventdata)
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples,max(1,round( xlim()*data.user_data.player.SampleRate+1 )));
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
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

