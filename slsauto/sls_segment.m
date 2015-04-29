function borders=sls_segment(file_name_or_x, fs, alg)
	%% Prepare signal
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		file_name_or_x=fullfile(dlg_path,dlg_name);
	end

	if isa(file_name_or_x,'char')
		[x,fs]=wavread(file_name_or_x);
		file_name=file_name_or_x;
	else
		x=file_name_or_x;
		file_name='signal';
	end

	x(:,2:end)=[];
	x_t=(0:size(x,1)-1)'/fs;

	%% Configure algorithm
	if nargin<3
		alg.obs.general=	struct(	'frame_size',0.020, 'frame_step',0.005, 'fs',fs);
		alg.obs.power=		struct(	'is_db',true, 'is_normalize',false);

		alg.meta.vad=		struct(	'min_db_range',40, 'db_range_part',0.5, 'min_pause',0.200, 'min_speech',0.300);

		alg.obs.tone=		struct(	'window','hamming', 'do_lpc',false, 'f0_range',[80 500], ...
									'median',0.040, 'threshold',0.5, 'min_vocal_sz',0.100, 'min_unvocal_sz',0.060);

		alg.obs.pirogov=	struct(	'avr',0.020,	'diff',0.040,	'max_threshold',0.7,	'max_neighborhood',0.070,	'reg_sz',[0.055 0.250]);

		alg.segmentation=	struct(	'min_phone_sz',0.090);
	end

	%% Calculate power
	obs.power=sls_seg_obs_power(x, alg);
	obs.time=(0:size(obs.power,1)-1)'*alg.obs.general.frame_step+alg.obs.general.frame_size/2;

	%% VAD and speech regions
	power_val_rg=[min(obs.power) max(obs.power)];
	power_thresh=max(power_val_rg(2)-power_val_rg(1), alg.meta.vad.min_db_range) * alg.meta.vad.db_range_part + power_val_rg(1);
	obs.reg_vad=find_regions(obs.power > power_thresh, ...
							 round(alg.meta.vad.min_pause/alg.obs.general.frame_step), ...
							 round(alg.meta.vad.min_speech/alg.obs.general.frame_step));

	obs.vad=false(size(obs.time));
	for i=1:size(obs.reg_vad,1)
		obs.vad(obs.reg_vad(i,1):obs.reg_vad(i,2))=true;
	end

	borders=struct('val',obs.reg_vad(:), 'style',{{'Color','r', 'LineWidth',2}}, 'name','VAD');

	%% Calculate tone
	obs.tone=sls_seg_obs_tone(x, alg);
	i=round(alg.obs.tone.median/alg.obs.general.frame_step);
	if i>1
		obs.tone=medfilt1(obs.tone, i, [], 1);
	end
	obs.tone(not(obs.vad))=0;

	obs.reg_tone=find_regions(obs.tone > alg.obs.tone.threshold, ...
							  round(alg.obs.tone.min_unvocal_sz/alg.obs.general.frame_step), ...
							  round(alg.obs.tone.min_vocal_sz  /alg.obs.general.frame_step));

	obs.is_vocal=false(size(obs.time));
	for i=1:size(obs.reg_tone,1)
		obs.is_vocal(obs.reg_tone(i,1):obs.reg_tone(i,2))=true;
	end

	% Take only maximum valued extremums
	min_phone_sz=round(alg.segmentation.min_phone_sz/alg.obs.general.frame_step);
	borders(end+1,1)=struct('val',merge_borders(borders, obs.reg_tone, min_phone_sz), ...
							'style',{{'Color','m'}}, 'name','d_tone boundaries');

	%% Pirogov function borders
	[~,obs.pirogov.bord, obs.pirogov.bord_ind, obs.pirogov.obs]=sls_seg_obs_pirogov(x, alg);

	%% Merge Pirogov and other borders
	[~,si]=sort(abs(obs.pirogov.obs(obs.pirogov.bord_ind)),1,'descend');
	borders(end+1,1)=struct('val',merge_borders(borders, obs.pirogov.bord_ind(si), min_phone_sz), ...
							'style',{{'Color','b'}}, 'name','Pirogov function');

	%% Save borders to file
%	wav_markers_write(file_name, round(obs.phones_borders*fs)+1);
%	wav_regions_write(file_name, round([obs.time(obs.reg_vad(:,1)), obs.time(obs.reg_vad(:,2))-obs.time(obs.reg_vad(:,1))]*fs)+1, 'VAD');

	%% Display results
	if nargout<1
		[cur_dir,cur_name]=fileparts(file_name);
		fig=figure('NumberTitle','off', 'Name',cur_name, 'Toolbar','figure', 'Units','normalized', 'Position',[0 0 1 1]);
		sub_plot1=subplot(5,1,1);
		plot(x_t,x);
		x_lim=x_t([1 end])';
		axis([x_lim max(abs(x))*1.1*[-1 1]]);
		grid on;
		ylabel('Signal');
		disp_borders(borders, obs.time);
		caret=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
		title(file_name, 'Interpreter','none');
		
		subplot(5,1,2);
		plot(obs.time,obs.power,'b');
		y_lim=ylim();
		hold('on');
		plot(obs.time,obs.vad*0.8*diff(y_lim)+y_lim(1)+diff(y_lim)*0.1,'k');
		grid('on');
		axis([x_lim y_lim]);
		line(x_lim, power_thresh+[0 0], 'Color','r');
		text(x_lim(1), power_thresh, num2str(power_thresh), 'HorizontalAlignment','left', 'VerticalAlignment','bottom');
		ylabel('Power, dB');
		disp_borders(borders, obs.time);
		caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

		subplot(5,1,3);
		[sp_s, sp_f, sp_t, sp_p]=spectrogram(x, round(alg.obs.general.frame_size*fs), round((alg.obs.general.frame_size-alg.obs.general.frame_step)*fs), 512, fs); %#ok<*ASGLU>
		surf(sp_t,sp_f,10*log10(abs(sp_p)),'EdgeColor','none');
		setcolormap('hsl');
		view(0,90);
		axis([x_lim sp_f(1) min(sp_f(end),4000)]);
		ylabel('Spectrogram');
		disp_borders(borders, obs.time);
		caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

		subplot(5,1,4);
		plot(obs.time,obs.tone);
		y_lim=[-0.1 1.1];
		hold('on');
		plot(obs.time,obs.is_vocal,'k');
		grid('on');
		line(x_lim, alg.obs.tone.threshold+[0 0], 'Color','r');
		axis([x_lim y_lim]);
		ylabel('Tone');
		disp_borders(borders, obs.time);
		caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

		subplot(5,1,5);
		plot(obs.time(1:length(obs.pirogov.obs)), obs.pirogov.obs);
		line(x_lim, alg.obs.pirogov.max_threshold+[0 0], 'Color','r');
		line(x_lim, -alg.obs.pirogov.max_threshold+[0 0], 'Color','r');
		grid on;
		xlim(x_lim);
		ylabel('Pirogov function');
		disp_borders(borders, obs.time);
		caret(end+1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);

		ctrl_pos=get(sub_plot1,'Position');
		btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
			'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);

		set(zoom,'ActionPostCallback',@OnZoomPan);
		set(pan ,'ActionPostCallback',@OnZoomPan);
		zoom xon;
		set(pan, 'Motion', 'horizontal');

		player = audioplayer(x, fs);
		set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
					'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

		data = guihandles(fig);
		data.user_data = struct('player',player, 'btn_play',btn_play);
		guidata(fig,data);

		clear borders;
	else
		for bi=1:length(borders)
			borders(bi).val=obs.time(borders(bi).val);
		end
	end
end

function obs=sls_seg_obs_power(x, alg)
	fr_sz=round([alg.obs.general.frame_step alg.obs.general.frame_size]*alg.obs.general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);
	obs=zeros(obs_sz,1);

	obs_ind=0;
	for i=1:fr_sz(1):size(x,1)-fr_sz(2)+1
		cur_x=x(i:i+fr_sz(2)-1);
		obs_ind=obs_ind+1;
		obs(obs_ind)=mean(cur_x.*cur_x);
	end
	if obs_ind~=size(obs,1)
		error('Observation length mismatch.');
	end

	if isfield(alg.obs.power,'is_db') && alg.obs.power.is_db
		obs=10*log10(obs + 1e-100);
	end

	if isfield(alg.obs.power,'is_normalize') && alg.obs.power.is_normalize
		if isfield(alg.obs.power,'is_db') && alg.obs.power.is_db
			obs=obs-max(obs);
		else
			obs=obs/max(obs);
		end
	end
end

function obs=sls_seg_obs_tone(x, alg)
	fr_sz=round([alg.obs.general.frame_step alg.obs.general.frame_size]*alg.obs.general.fs);
	t0_rg=fr_sz(2)+min(fr_sz(2), round(alg.obs.general.fs./alg.obs.tone.f0_range));

	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);
	obs=zeros(obs_sz,1);

	obs_ind=0;
	x_ord=round(alg.obs.general.fs/1000)+2;

	for i=1:fr_sz(1):size(x,1)-fr_sz(2)+1
		cur_x=x(i:i+fr_sz(2)-1);
		if alg.obs.tone.do_lpc
			cur_a=safe_lpc(cur_x, x_ord);
			cur_x=filter(cur_a, 1, cur_x);
		end
		cur_xc=xcorr(cur_x);
		cur_xc=cur_xc./sqrt(triang(length(cur_xc)));

		obs_ind=obs_ind+1;
		obs(obs_ind)=max(cur_xc(t0_rg(2):t0_rg(1)))/cur_xc(fr_sz(2));
	end
end

function [dborders, borders, borders_ind, obs]=sls_seg_obs_pirogov(x, alg)
	fr_sz=round([alg.obs.general.frame_step alg.obs.general.frame_size]*alg.obs.general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);

	if obs_sz<1
		dborders=[];
		borders=[];
		borders_ind=[];
		obs=[];
		return
	end

	lpc_ord=round(alg.obs.general.fs/1000+2);
	spec=zeros(obs_sz, 128);
	powr=zeros(obs_sz, 1);

	obs_ind=0;
	for i=1:fr_sz(1):size(x,1)-fr_sz(2)+1
		obs_ind=obs_ind+1;
		cur_x=x(i:i+fr_sz(2)-1).*gausswin(fr_sz(2));
		[cur_a,cur_e]=safe_lpc(cur_x, lpc_ord);
		spec(obs_ind,:)=20*log10(abs( freqz( sqrt(cur_e), cur_a, size(spec,2) ) + 10^(-90/20) ));
		powr(obs_ind)=cur_x'*cur_x;
	end
	
	not_powr=powr<quantile(powr, 0.25);
	spec(not_powr,:)=repmat(mean(spec(not_powr,:)), sum(not_powr), 1);

	avr_sz=max(1, round(alg.obs.pirogov.avr / alg.obs.general.frame_step));
	if avr_sz>1
		avr_delay=fix(avr_sz/2);
		spec_avr=zeros(size(spec));
		sp_sz1=size(spec,1);
		for i=(1:avr_sz)-avr_delay
			spec_avr=spec_avr+[repmat(spec(1,:),min(i,size(spec_avr,1)),1); spec(max(1,1-i):min(sp_sz1,sp_sz1-i),:); repmat(spec(end,:),min(-i,size(spec_avr,1)),1)];
		end
		spec=spec_avr/avr_sz;
	end

	delay_sz=max(1, round(alg.obs.pirogov.diff / alg.obs.general.frame_step));
	delay_sz_l=fix(delay_sz/2);
	delay_sz_r=delay_sz-delay_sz_l;
	obs=sum([spec(delay_sz_l+1:end,:); repmat(spec(end,:),delay_sz_l,1)] - ...
			[repmat(spec(1,:),delay_sz_r,1); spec(1:end-delay_sz_r,:)], 2);
	obs=obs/(std(obs)+eps);

	maxneigh=max(1,round(alg.obs.pirogov.max_neighborhood/alg.obs.general.frame_step));
	obs_max=[obs zeros(size(obs,1),maxneigh*2)];
	for i=1:maxneigh
		obs_max(i+1:end,i*2)=  obs(1:end-i);
		obs_max(1:end-i,i*2+1)=obs(i+1:end);
	end
	[mxv,mxi]=max(obs_max,[],2);
	[mnv,mni]=min(obs_max,[],2);
	borders_ind=sort([find(mxi==1 & mxv>alg.obs.pirogov.max_threshold); ...
			 find(mni==1 & mnv<-alg.obs.pirogov.max_threshold)]);

	min_reg_sz=alg.obs.pirogov.reg_sz(1)/alg.obs.general.frame_step;
	check_ok=false;
	while not(check_ok)
		check_ok=true;
		for i=1:numel(borders_ind)-1
			if borders_ind(i+1)-borders_ind(i)<min_reg_sz
				[~,mi]=min(abs(obs(borders_ind([i i+1]))));
				borders_ind(i+mi-1)=[];
				check_ok=false;
				break;
			end
		end
	end

	borders=((borders_ind-1)*fr_sz(1)+fr_sz(2)/2)/alg.obs.general.fs;
	dborders=diff(borders);
	dborders(dborders<alg.obs.pirogov.reg_sz(1) | dborders>alg.obs.pirogov.reg_sz(2))=[];
end

function extr=find_local_extremums(x, extr_fn, extr_neigh)
	extr=[];
	for i=1:length(x)
		rgn=min(length(x),max(1,[i-extr_neigh, i+extr_neigh]));
		[~,mi]=feval(extr_fn, x(rgn(1):rgn(2)));
		if i==mi+rgn(1)-1
			extr(end+1,1)=i; %#ok<AGROW>
		end
	end
end

function speech_reg=find_regions(x, min_pause, min_speech)
	dx=diff([0; x; 0]);
	regs_beg=find(dx==1);
	regs_end=find(dx==-1);

	small_pause = regs_beg(2:end)-regs_end(1:end-1) < min_pause;
	regs_beg([false; small_pause])=[];
	regs_end([small_pause; false])=[];

	small_speech= regs_end-regs_beg < min_speech;
	regs_beg(small_speech)=[];
	regs_end(small_speech)=[];
	speech_reg=[regs_beg regs_end-1];
	if isempty(speech_reg)
		speech_reg=zeros(0,2);
	end
	if size(speech_reg,2)==1
		speech_reg=speech_reg';
	end
end

function extr_new=merge_borders(borders, extr, min_reg_sz)
	vad_regs=reshape(borders(1).val,[],2);
	extr_ok=vertcat(borders.val);
	extr_new=[];

	for i=1:numel(extr)
		if any(vad_regs(:,1)<extr(i) & extr(i)<vad_regs(:,2)) && not(any(abs(extr_ok-extr(i))<min_reg_sz))
			extr_ok(end+1,1)=extr(i); %#ok<AGROW>
			extr_new(end+1,1)=extr(i); %#ok<AGROW>
		end
	end

	extr_new=sort(extr_new);
end

function setcolormap(palette)
    if ischar(palette)
        palette=getcolormap(palette);
    end
    colormap(palette);
end

function map=getcolormap(colormaptype)
    switch lower(colormaptype)
        case 'antigray'
            map=makecolormap([    0      1   1   1;...
                                  1      0   0   0]);
        case 'speech'
            map=makecolormap([    0      0   0   1;...
                                1/3      0   1   0;...
                                2/3      1   0   0;...
                                  1      1   1   0]);
        case 'fire'
            map=makecolormap([    0      0   0   0;...
                              0.113    0.5   0   0;...
                              0.315      1   0   0;...
                              0.450      1 0.5   0;...
                              0.585      1   1   0;...
                              0.765      1   1 0.5;...
                                  1      1   1   1]);
        case 'hsl'
            map=makecolormap([    0      0   0   0;...
                                1/7      1   0   1;...
                                2/7      0   0   1;...
                                3/7      0   1   1;...
                                4/7      0 0.5   0;...
                                5/7      1   1   0;...
                                6/7      1   0   0;...
                                  1      1   1   1]);
        otherwise
            map=colormaptype;
    end
end

function map=makecolormap(map_info)
    map=zeros(64,3);
    map(1,:)=map_info(1,2:4);
    index=1;
    for i=2:63
        pos=(i-1)/63;
        while map_info(index,1)<=pos
            index=index+1;
        end
        map(i,:)=map_info(index-1,2:4)+(map_info(index,2:4)-map_info(index-1,2:4))*(pos-map_info(index-1,1))/(map_info(index,1)-map_info(index-1,1));
    end
    map(64,:)=map_info(end,2:4);
end

function disp_borders(borders, time)
	y_lim=ylim();
	for bi=1:numel(borders)
		for i=1:numel(borders(bi).val)
			line(time(borders(bi).val(i)+[0 0]), y_lim, borders(bi).style{:});
		end
	end
end

function OnPlaySignal(hObject, eventdata) %#ok<*INUSD>
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples,max(1,round( xlim()*data.user_data.player.SampleRate+1 )));
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

function OnZoomPan(hObject, eventdata)
	data = guidata(hObject);
	x_len= data.user_data.player.TotalSamples/data.user_data.player.SampleRate;

	x_lim=xlim();
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>x_len
		x_lim=[max(0, x_len-rg) x_len];
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end

function [a,E]=safe_lpc(x, N)
	[a,E]=lpc(x,N);
	fix_ind=isnan(E);
	E(fix_ind)=0;
	a(fix_ind,:)=0;
	a(fix_ind,1)=1;

	r=roots(a);
	r_l=abs(r);
	if any(r_l>0.999)
		r_a=angle(r);
		r_l(r_l>0.999)=0.999;
		r=r_l.*exp(r_a*1i);
		a=real(poly(r));
	end
end
