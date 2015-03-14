function base=vnm_meta_intonogram(base, alg, algs)
	win_sz=round(alg.win_sz/algs.obs_general.frame_step);
	pause_sz=round(alg.pause_sz/algs.obs_general.frame_step);

	for ai=1:numel(alg.obs)
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
%				obj=base(bi).data{fi};  disp_obj(obj);
				base(bi).data{fi}.(['i_' alg.obs{ai}])=feval(algs.obs_general.precision, medfilt1(double(base(bi).data{fi}.(alg.obs{ai})), win_sz));
			end
		end
	end
end

function disp_obj(obj)
	[x,fs]=vb_readwav(obj.file_name);
	x(:,2:end)=[];
	x_lim=[0 (size(x,1)-1)/fs];
	fig=figure('Toolbar','figure', 'Units','normalized', 'Position',[0 0 1 1]);

	sub_plot1=subplot(3,1,1); plot((0:size(x,1)-1)/fs, x);	grid on;	axis([x_lim -1 1]);	title(obj.file_name,'Interpreter','none');
	caret(1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

	subplot(3,1,2); plot(obj.time,obj.power,'b+-');		grid on;	axis([x_lim ylim()]);
	caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

	subplot(3,1,3); plot(obj.time,obj.pitch,'b+-', obj.time,medfilt1(obj.pitch,10),'r');		grid on;	axis([x_lim ylim()]);
	caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

	ctrl_pos=get(sub_plot1,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
		'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);
	set(fig,'Position',[0 0 1 1]);

	set(zoom,'ActionPostCallback',@on_zoom_pan);
	set(pan ,'ActionPostCallback',@on_zoom_pan);
	zoom('xon');
	set(pan, 'Motion', 'horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	data.user_data = struct('player',player, 'btn_play',btn_play, 'x_len',x_lim(2));
	guidata(fig,data);
end

function OnPlaySignal(hObject, eventdata) %#ok<*INUSD>
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples, max(1, round( xlim()*data.user_data.player.SampleRate+1 ) ) );
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
	end
end

function CallbackPlay(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end
end

function CallbackPlayStop(obj, event, string_arg)
	CallbackPlay(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');
end
