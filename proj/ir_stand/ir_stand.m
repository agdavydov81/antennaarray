function varargout = ir_stand(varargin)
% IR_STAND MATLAB code for ir_stand.fig
%      IR_STAND, by itself, creates a new IR_STAND or raises the existing
%      singleton*.
%
%      H = IR_STAND returns the handle to a new IR_STAND or the handle to
%      the existing singleton*.
%
%      IR_STAND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_STAND.M with the given input arguments.
%
%      IR_STAND('Property','Value',...) creates a new IR_STAND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_stand_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_stand_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_stand

% Last Modified by GUIDE v2.5 06-Oct-2013 16:18:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_stand_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_stand_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ir_stand is made visible.
function ir_stand_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_stand (see VARARGIN)

% Choose default command line output for ir_stand
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_stand wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Show BSUIR logo
imshow([fileparts(mfilename('fullpath')) filesep 'bsuir_logo.png'], 'Parent',handles.logo_axes);

% Position to center of screen
old_units = get(hObject,'Units');
scr_sz = get(0,'ScreenSize');
set(hObject,'Units',get(0,'Units'));
cur_pos = get(hObject,'Position');
set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
set(hObject,'Units',old_units);

% Load configuration
[cur_path, cur_name]= fileparts(mfilename('fullpath'));
handles.config_file = fullfile(cur_path, [cur_name '_config.xml']);
addpath([fileparts(mfilename('fullpath')) filesep 'xml_io_tools']);
try
	handles.config = xml_read(handles.config_file);
catch ME
	handles.config = struct();
end

imshow(ones(10,10,3), 'Parent',handles.work_img_orig);
imshow(ones(10,10,3), 'Parent',handles.work_img_bw);
set(handles.work_graph_pix_num, 'XTickLabel',{});

set(handles.work_abort_btn, 'Enable','off');

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ir_stand_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

check_config(handles);

function check_config(handles)
cfg = handles.config;
is_ok = true;

if is_ok && not(isfield(cfg,'acoustic_generator'))
	msgbox('Настройте геренатор акустического воздействия для начала работы.', [mfilename ' help'], 'help', 'modal');
	is_ok = false;
end
if is_ok && not(isfield(cfg,'video_device'))
	msgbox('Настройте тепловизор для начала работы.', [mfilename ' help'], 'help', 'modal');
	is_ok = false;
end
if is_ok && not(isfield(cfg,'thresholds'))
	msgbox('Настройте пороги программы для начала работы.', [mfilename ' help'], 'help', 'modal');
	is_ok = false;
end

if is_ok
	set(handles.work_start_btn, 'Enable','on');
else
	set(handles.work_start_btn, 'Enable','off');
end


% --- Executes on button press in setup_emi_btn.
function setup_emi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_emi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in setup_acoustics_btn.
function setup_acoustics_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_acoustics_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_acoustic(handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_irvideo_btn.
function setup_irvideo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_irvideo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ret_cfg = ir_setup_video(handles.config);
if isempty(ret_cfg)
	errordlg('Не обнаружено подходящих видео устройств.', [mfilename ' help'], 'modal');
	return
end

handles.config = ret_cfg;
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_btn.
function setup_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_thresholds(handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in work_abort_btn.
function work_abort_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_abort_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.work_start_btn, 'Enable','on');
set(handles.work_abort_btn, 'Enable','off');
set(handles.setup_emi_btn, 'Enable','on');
set(handles.setup_irvideo_btn, 'Enable','on');
set(handles.setup_acoustics_btn, 'Enable','on');
set(handles.setup_btn, 'Enable','on');

dos('taskkill /F /IM Lobanov_mark.exe 1>nul 2>&1');

if handles.config.acoustic_generator.harm.enable
	try
		playrec('reset');
	catch ME
		% disp(ME);
	end
end

if isfield(handles,'video')
	try
		if isvalid(handles.video.vidobj)
			stop(handles.video.vidobj);
			delete(handles.video.vidobj);
		end
		if isvalid(handles.video.timer)
			stop(handles.video.timer);
		end
		if handles.video.report.fh~=-1
			fclose(handles.video.report.fh);
		end
	catch ME
		% disp(ME);
	end
end


% --- Executes on button press in work_start_btn.
function work_start_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_start_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Find video recorder
video_devices = imaqhwinfo('winvideo');
cur_cam = find(strcmp(handles.config.video_device.name, {video_devices.DeviceInfo.DeviceName}),1);
if isempty(cur_cam)
	errordlg(['Не обнаружено видео устройство "' handles.config.video_device.name '".'], [mfilename ' help'], 'modal');
	return
end

% Start video recorder
handles.video.vidobj = videoinput('winvideo',video_devices.DeviceIDs{cur_cam}, handles.config.video_device.mode);
set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
try
	start(handles.video.vidobj);
catch
	errordlg(['Ошибка получения изображения из "' handles.config.video_device.name '".'], [mfilename ' help'], 'modal');
	return
end
handles.video.config = handles.config;


% Generages signal
if handles.config.acoustic_generator.harm.enable
	play.fs = 44100;
	play.buff_sz = 0.5*play.fs;
	play.buff_num = 10;
	play.buffs = [];
	play.config = handles.config;
	
	harm_cfg = handles.config.acoustic_generator.harm;
	harm_freq = [harm_cfg.freq_start harm_cfg.freq_finish];
	if any(harm_freq<1 | harm_freq > play.fs*0.45)
		errordlg(['Частоты синтеза сигнала выходят за допустимый диапазон [1,' num2str(round(play.fs*0.45)) '] Гц.'], [mfilename ' error'], 'modal');
		return;
	end

	%Test if current initialisation is ok
	if playrec('isInitialised')
		playrec('reset');
	end

	%Initialise if not initialised
	if ~playrec('isInitialised')
		dev_list = playrec('getDevices');
		dev_list(logical(not([dev_list.outputChans]))) = [];
		if isempty(dev_list)
			error('ir_stand:sound_output','Can''t find any sound output device.');
		end

		dev_ind = arrayfun(@(x) ~isempty(strfind(x.name, 'Microsoft Sound Mapper')), dev_list);
		if all(not(dev_ind))
			dev_ind = arrayfun(@(x) ~isempty(strfind(x.name, 'ереназначен')), dev_list);
		end
		if all(not(dev_ind))
			dev_ind(1) = true;
		end

		dev_id = dev_list(dev_ind).deviceID;

		playrec('init', play.fs, dev_id, -1, 1);

		% This slight delay is included because if a dialog box pops up during
		% initialisation (eg MOTU telling you there are no MOTU devices
		% attached) then without the delay Ctrl+C to stop playback sometimes
		% doesn't work.
		pause(0.1);
	end

	play.timer = struct('pos',0, ...
						'f_mod_last',0, ...
						'handle', timer('TimerFcn',@player_timer_func, 'StopFcn',@player_timer_stop, ...
										'Period',play.buff_sz/play.fs, 'ExecutionMode','fixedRate'));
	set(play.timer.handle, 'UserData',play);
	handles.play = play;
	start(handles.play.timer.handle);
end

set(handles.work_start_btn, 'Enable','off');
set(handles.work_abort_btn, 'Enable','on');
set(handles.setup_emi_btn, 'Enable','off');
set(handles.setup_irvideo_btn, 'Enable','off');
set(handles.setup_acoustics_btn, 'Enable','off');
set(handles.setup_btn, 'Enable','off');

% Fork SLS process
if handles.config.acoustic_generator.sls.enable
	handles.sls_watchdog = timer('TimerFcn',@watchdog_timer_func, 'StopFcn',@player_timer_stop, ...
								 'Period',1, 'ExecutionMode','fixedRate', 'UserData',handles);
	start(handles.sls_watchdog);
end

% Init fields for processing
handles.video.tic_id = tic();
handles.video.toc_frames = 0;
handles.video.work_stage = 0;

% Turn off detector lamp
scatter(0,0,300,0.3+[0 0 0],'filled', 'Parent',handles.detector_lamp, 'Visible','off');
set(handles.detector_lamp, 'Visible','off');

% Create image processing timer
handles.video.timer = timer('TimerFcn',@video_timer_func, 'Period',1/100, ...
							'ExecutionMode','fixedRate');
handles_video = handles.video;
handles_video.handles = handles;
set(handles.video.timer, 'UserData',handles_video);

guidata(handles.figure1, handles);

start(handles.video.timer);


function player_timer_func(timer_handle, eventdata)
try
	if not(playrec('isInitialised'))
		stop(timer_handle);
		return;
	end

	handles_play = get(timer_handle, 'UserData');

	while ~isempty(handles_play.buffs) && playrec('isFinished', handles_play.buffs(1))
		handles_play.buffs(1) = [];
	end

	harm_cfg = handles_play.config.acoustic_generator.harm;
	while numel(handles_play.buffs) < handles_play.buff_num
		cur_t = handles_play.timer.pos+(0:handles_play.buff_sz-1)'/handles_play.fs;
		handles_play.timer.pos = handles_play.timer.pos+handles_play.buff_sz/handles_play.fs;

		f_mod = acos(cos(cur_t*pi/harm_cfg.scan_time))/pi;

		switch harm_cfg.scan_type
			case 'lin'
				f_mod = (harm_cfg.freq_finish-harm_cfg.freq_start)*f_mod+harm_cfg.freq_start;
			case 'log'
				f_mod = harm_cfg.freq_start*(harm_cfg.freq_finish/harm_cfg.freq_start).^(f_mod);
			otherwise
				error('ir_stand:harm_gen',['Unsupported frequency modulation type "' harm_cfg.scan_type '".']);
		end

		f_mod = cumsum(f_mod)/handles_play.fs + handles_play.timer.f_mod_last;
		f_mod = rem(f_mod,1);
		handles_play.timer.f_mod_last = f_mod(end);

		cur_x = harm_cfg.amplitude*cos(2*pi*f_mod);

		% Play generated sound
		handles_play.buffs = [handles_play.buffs playrec('play', cur_x, 1)];
	end

	set(timer_handle, 'UserData',handles_play);
catch ME
	% disp(ME);
end


function watchdog_timer_func(timer_handle, eventdata)
try
	handles = get(timer_handle, 'UserData');
	if strcmp(get(handles.work_abort_btn,'Enable'),'off')
		stop(timer_handle);
		return;
	end

	[~, dos_result] = dos('tasklist /FI "IMAGENAME eq Lobanov_mark.exe"');
	if isempty(strfind(dos_result, 'Lobanov_mark.exe'))
		sls_dir = [fileparts(mfilename('fullpath')) filesep 'sls' filesep];
		dos_str = ['"' sls_dir 'hstart.exe" /NOCONSOLE /D="' sls_dir '" "Lobanov_mark.exe Db_Bor1/ 0 0"'];
		dos(dos_str);
	end
catch ME
	% disp(ME);
end


function video_timer_func(timer_handle, eventdata)
try
	%% Camera image aquiring and displaying
	handles_video = get(timer_handle,'UserData');
	frame_cur_rgb = getsnapshot(handles_video.vidobj);
	ax = fix(handles_video.config.video_device.axis);
	frame_cur_rgb = frame_cur_rgb(ax(3)+1:ax(4), ax(1)+1:ax(2), :);
	imshow(frame_cur_rgb, 'Parent',handles_video.handles.work_img_orig);
	frame_cur = rgb2temp(frame_cur_rgb);
	frame_sz = size(frame_cur);
	frame_cur = transpose(frame_cur(:));

	%% Time stamp displaying
	toc_t = toc(handles_video.tic_id);
	handles_video.toc_frames = handles_video.toc_frames+1;
	time_s = fix(toc_t);
	time_h = fix(time_s/3600);  time_s = time_s-time_h*3600;
	time_m = fix(time_s/60);    time_s = time_s-time_m*60;
	set(handles_video.handles.work_timer, 'String',sprintf('%02d:%02d:%02d (%d)',time_h,time_m,time_s, handles_video.toc_frames));

	%% Image processing cycle
	switch handles_video.work_stage
		%% Start camera initialisation stage -- just skip frames
		case 0
			if toc_t>handles_video.config.thresholds.start_delay && handles_video.toc_frames>10
				handles_video.work_stage = 100;
			end
			
		%% High pass filer initialisation stage
		case 100  % Initialise high pass filter
			if handles_video.config.thresholds.filt_hp_factor==-1
				handles_video.work_stage = 200;
			else
				if ~isfield(handles_video,'filt_hp_imgs')
					handles_video.filt_hp_imgs = {};
				end
			
				handles_video.filt_hp_imgs{end+1,1} = frame_cur;

				if size(handles_video.filt_hp_imgs,1)>=10
					filt_hp_imgs = cell2mat(handles_video.filt_hp_imgs);
					handles_video = rmfield(handles_video,'filt_hp_imgs');
					
					handles_video.filt_hp = struct('init_cnt',0, 'b',[1 -1], 'a',[1 handles_video.config.thresholds.filt_hp_factor], 'z',-mean(filt_hp_imgs));

					handles_video.work_stage = 101;
				end
			end
		case 101 % Stabilize high pass filter output
			if handles_video.filt_hp.init_cnt < handles_video.config.thresholds.filter_hp_initframes
				handles_video.filt_hp.init_cnt = handles_video.filt_hp.init_cnt+1;
				[~, handles_video.filt_hp.z] = filter(handles_video.filt_hp.b, handles_video.filt_hp.a, frame_cur, handles_video.filt_hp.z, 1);
			end
			if handles_video.filt_hp.init_cnt >= handles_video.config.thresholds.filter_hp_initframes
				handles_video.work_stage = 200;
			end

		%% Statistics initialisation stage
		case 200
			if isfield(handles_video,'filt_hp')
				[frame_cur, handles_video.filt_hp.z] = filter(handles_video.filt_hp.b, handles_video.filt_hp.a, frame_cur, handles_video.filt_hp.z, 1);
			end

			if ~isfield(handles_video,'stat_init')
				handles_video.stat_init = struct('frames',{{}}, 'times',[]);
			end

			handles_video.stat_init.frames{end+1,1} = frame_cur;
			handles_video.stat_init.times(end+1,1) = toc_t;

			if handles_video.stat_init.times(end)-handles_video.stat_init.times(1)>handles_video.config.thresholds.stat_time && length(handles_video.stat_init.frames)>10
				stat_imgs = cell2mat(handles_video.stat_init.frames);
				handles_video = rmfield(handles_video,'stat_init');

				if handles_video.config.thresholds.stat_lo>0
					handles_video.stat.lo = quantile(stat_imgs, handles_video.config.thresholds.stat_lo, 1);
				end
				handles_video.stat.hi = quantile(stat_imgs, handles_video.config.thresholds.stat_hi, 1);
				
				handles_video.work_stage = 300;
			end

		%% Main work stage
		case 300
			% High pass filtering
			if isfield(handles_video,'filt_hp')
				[frame_cur, handles_video.filt_hp.z] = filter(handles_video.filt_hp.b, handles_video.filt_hp.a, frame_cur, handles_video.filt_hp.z, 1);
			end

			% Statistics checkign
			is_signaling = false(size(frame_cur));
			if isfield(handles_video.stat,'lo')
				is_signaling = is_signaling | (frame_cur<handles_video.stat.lo);
			end
			is_signaling = is_signaling | (frame_cur>handles_video.stat.hi);

			% Median filtering
			if handles_video.config.thresholds.median_size>0
				is_signaling = reshape(is_signaling, frame_sz);
				is_signaling = medfilt2(is_signaling, handles_video.config.thresholds.median_size+[0 0]);
				is_signaling = transpose(is_signaling(:));
			end
			imshow(double(repmat(reshape(is_signaling, frame_sz),[1 1 3])), 'Parent',handles_video.handles.work_img_bw);

			% Detector: estimate currect values
			det_points = sum(is_signaling);
			det_part =   mean(is_signaling);
			if ~isfield(handles_video,'detector')
				handles_video.detector = struct('graphs',zeros(0,3), 'state',false, 'thresholds_on_toc',-inf);

%{
handles.video.report.fh=-1;
if not(isempty(handles.video.config.thresholds.report_path))
	handles.video.report.fh = fopen(fullfile(handles.video.config.thresholds.report_path, sprintf('report.txt')), 'wt');
end
handles.video.report.img_cnt = 0;
handles.video.report.img_toc = 0;
%}
				
			end
			handles_video.detector.graphs(end+1,:) = [toc_t det_points det_part];

			% Detector: plot graphs
			if handles_video.config.thresholds.report_graph_time>0
				handles_video.detector.graphs(handles_video.detector.graphs(:,1)<toc_t-handles_video.config.thresholds.report_graph_time,:) = [];
			end
			plot(handles_video.handles.work_graph_pix_num,  handles_video.detector.graphs(:,1), handles_video.detector.graphs(:,2));
			plot(handles_video.handles.work_graph_pix_part, handles_video.detector.graphs(:,1), handles_video.detector.graphs(:,3));

			set(handles_video.handles.work_graph_pix_num, 'XTickLabel',{});

			% Detector: plot thresholds
			x_lim = xlim(handles_video.handles.work_graph_pix_num);
			line(x_lim, handles_video.config.thresholds.detector_on_points +[0 0], 'Parent',handles_video.handles.work_graph_pix_num, 'Color','r');
			line(x_lim, handles_video.config.thresholds.detector_off_points+[0 0], 'Parent',handles_video.handles.work_graph_pix_num, 'Color','k');

			line(x_lim, handles_video.config.thresholds.detector_on_part +[0 0], 'Parent',handles_video.handles.work_graph_pix_part, 'Color','r');
			line(x_lim, handles_video.config.thresholds.detector_off_part+[0 0], 'Parent',handles_video.handles.work_graph_pix_part, 'Color','k');
			
			% Detector state logic
			if ~handles_video.detector.state
				thresholds_on = det_points>handles_video.config.thresholds.detector_on_points  || det_part>handles_video.config.thresholds.detector_on_part;
			else
				thresholds_on = det_points>handles_video.config.thresholds.detector_off_points || det_part>handles_video.config.thresholds.detector_off_part;
			end
			if thresholds_on
				handles_video.detector.thresholds_on_toc = toc_t;
			end
			new_st = thresholds_on | toc_t-handles_video.detector.thresholds_on_toc<handles_video.config.thresholds.detector_post_buff;

			% Detector switch on|off logic
			if handles_video.detector.state~=new_st
				if new_st % Detector just on
					scatter(0,0,300,[1 0 0],'filled', 'Parent',handles_video.handles.detector_lamp);
					% @@ TODO: continue there
				else % Detector just off
					scatter(0,0,300,0.3+[0 0 0],'filled', 'Parent',handles_video.handles.detector_lamp, 'Visible','off');
					% @@ TODO: continue there
				end
				set(handles_video.handles.detector_lamp, 'Visible','off');
				handles_video.detector.state=new_st;
			end

			
		%% Program logic error trap
		otherwise
			disp('ERROR: Unknown work stage.');
			error('ERROR: Unknown work stage.');
	end
	
%{
			%% Save report
			if handles_video.report.fh~=-1
				cur_res = handles_video.report.graphs(end,:);
				fprintf(handles_video.report.fh, '%f\t%d\t%e\n', cur_res(1), cur_res(2), cur_res(3));
			end
%{
			if not(isempty(handles_video.config.thresholds.report_path)) && handles_video.config.thresholds.report_img_interval>=0 && handles_video.report.img_toc<toc_t
				handles_video.report.img_toc = toc_t + handles_video.config.thresholds.report_img_interval;
				handles_video.report.img_cnt = handles_video.report.img_cnt+1;
				imwrite(frame_cur_rgb, fullfile(handles_video.config.thresholds.report_path, sprintf('img_%06d.jpg',handles_video.report.img_cnt)), 'jpg', 'Quality',85);
			end
%}
%}
	
	set(timer_handle, 'UserData',handles_video);

	drawnow();
catch ME
	% disp(ME);
end


function temp = rgb2temp(pic_rgb)
pic_rgb  = single(pic_rgb);

yuv_luma = 0.299*pic_rgb(:,:,1) + 0.587*pic_rgb(:,:,2) + 0.114*pic_rgb(:,:,3);

temp = 0.005319*yuv_luma -0.1609;

temp = min(1,max(0,temp));


function player_timer_stop(timer_handle, eventdata)
delete(timer_handle);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

xml_write(handles.config_file, handles.config, 'ir_stand');

work_abort_btn_Callback(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
delete(hObject);
