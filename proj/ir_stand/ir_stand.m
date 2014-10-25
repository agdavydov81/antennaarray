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

function ret = isfield_ex(obj, fl_name)
	ret = true;
	while ret && ~isempty(fl_name)
		[cur_fl fl_name] = strtok(fl_name,'.');
		ret = isfield(obj,cur_fl);
		if ~ret
			break
		end
		obj = obj.(cur_fl);
	end

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

if is_ok && not(isfield(cfg,'emi_generator'))
	msgbox('Настройте геренатор ЭМВ для начала работы.', [mfilename ' help'], 'help', 'modal');
	is_ok = false;
end
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
handles.config = ir_setup_emi(handles.config);
xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_acoustics_btn.
function setup_acoustics_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_acoustics_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_acoustic(handles.config);
xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
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
xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_btn.
function setup_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_thresholds_simple(handles.config);
xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
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

stop_emi_generator(handles);

dos('taskkill /F /IM Lobanov_mark.exe 1>nul 2>&1');

if isfield_ex(handles,'config.acoustic_generator.harm.enable') && handles.config.acoustic_generator.harm.enable
	try
		playrec('reset');
	catch ME
		if isfield(handles.config,'disp_debug') && handles.config.disp_debug
			disp(ME.message);
			disp(ME.stack(1));
		end
	end
end

if isfield(handles,'video')
	try
		if isvalid(handles.video.vidobj)
			stop(handles.video.vidobj);
			delete(handles.video.vidobj);
		end
		if isvalid(handles.video.timer)
			handles_video = get(handles.video.timer,'UserData');
			stop(handles.video.timer);

			if isfield(handles_video,'report') && isfield(handles_video.report,'fh')
				if handles_video.report.fh~=-1
					try
						fclose(handles_video.report.fh);
					catch
					end

					try
						xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
					catch ME
						if isfield(handles.config,'disp_debug') && handles.config.disp_debug
							disp(ME.message);
							disp(ME.stack(1));
						end
					end

					% Save overall report to file
					fh = fopen([handles_video.report.path 'report.html'],'w');
					if fh~=-1
						[~, rep_name] = fileparts(handles_video.report.path(1:end-1));
						
						fprintf(fh, ['<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">\n' ...
									'<html>\n' ...
									'<head>\n' ...
									'<meta http-equiv="content-type" content="text/html; windows-1252">\n' ...
									'<title>' rep_name ' report</title>\n' ...
									'</head>\n' ...
									'<body>\n' ...
									'<div style="text-align: left; font-family: Arial;">\n']);

						if isempty(handles_video.report.overall)
							fprintf(fh, 'Аномалий не обнаружено.\n');
						else
							fprintf(fh, 'Обнаружено %d aномалий.<br><br>\n', size(handles_video.report.overall,1));

							fprintf(fh, ['<table border="1" cellpadding="0" cellspacing="0">\n' ...
										'<caption>Перечень аномалий</caption>\n' ...
										'<tbody>\n']);

							fprintf(fh, ['<tr><th rowspan="2">Путь к каталогу аномалии</th>' ...
										'<th colspan="3">Начало аномалии</th>' ...
										'<th colspan="3">Окончание аномалии</th></tr>\n' ...
										'<tr><th>Дата и время</th><th>С начала работы</th><th>Номер кадра</th>' ...
										    '<th>Дата и время</th><th>С начала работы</th><th>Номер кадра</th></tr>\n']);
										
							for i=1:size(handles_video.report.overall,1)
								rel_path = char(handles_video.report.overall{i,1});
								[~,rel_path,rel_path2] = fileparts(rel_path(1:end-1));
								fprintf(fh, '<tr><td><a href="%s%s">%s</a></td>', rel_path, rel_path2, char(handles_video.report.overall{i,1}));
								cellfun(@(x) fprintf(fh,'<td>%s</td>',char(x)), handles_video.report.overall(i,2:end));
								fprintf(fh, '</tr>\n');
							end
							
							fprintf(fh, '</tbody></table>\n');
						end

						fprintf(fh, '</div></body></html>\n');

						fclose(fh);
					end
				end
			end
		end
	catch ME
		if isfield(handles.config,'disp_debug') && handles.config.disp_debug
			disp(ME.message);
			disp(ME.stack(1));
		end
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

set(handles.work_start_btn, 'Enable','off');
set(handles.work_abort_btn, 'Enable','on');
set(handles.setup_emi_btn, 'Enable','off');
set(handles.setup_irvideo_btn, 'Enable','off');
set(handles.setup_acoustics_btn, 'Enable','off');
set(handles.setup_btn, 'Enable','off');


% Init fields for processing
handles.video.tic_id = tic();
handles.video.toc_frames = 0;
handles.video.work_stage = 0;

% Turn off detector lamp
scatter(0,0,300,0.3+[0 0 0],'filled', 'Parent',handles.detector_lamp, 'Visible','off');
set(handles.detector_lamp, 'Visible','off');

% Create image processing timer
handles.video.timer = timer('TimerFcn',@video_timer_func, 'StopFcn',@player_timer_stop, ...
							'Period',1/100, 'ExecutionMode','fixedRate');
handles_video = handles.video;
handles_video.handles = handles;
handles_video.palette = uint8(255 * ir_colormap(handles_video.handles.work_img_orig, handles_video.config.video_device.palette));
set(handles.video.timer, 'UserData',handles_video);

guidata(handles.figure1, handles);

start(handles.video.timer);

function start_generators(handles)
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

% Fork SLS process
if handles.config.acoustic_generator.sls.enable
	handles.sls_watchdog = timer('TimerFcn',@watchdog_timer_func, 'StopFcn',@player_timer_stop, ...
								 'Period',1, 'ExecutionMode','fixedRate', 'UserData',handles);
	start(handles.sls_watchdog);
end

% Start EMI generator
handles.emi_timer_handle = [];
if ~isempty(handles.config.emi_generator.program_list)
	if handles.config.emi_generator.continue_flag
		handles.config.emi_generator.program_index = min(size(handles.config.emi_generator.program_list,1),max(1,handles.config.emi_generator.program_index));
	end

	start_emi_generator(handles.config.emi_generator.program_list(handles.config.emi_generator.program_index,1));

	emi_delay = handles.config.emi_generator.program_list(handles.config.emi_generator.program_index,2)*60;
	if emi_delay>0 && ~isinf(emi_delay)
		handles.emi_timer_handle = timer('TimerFcn',@emi_timer_func, 'StopFcn',@emi_timer_stop, ...
								'ExecutionMode','singleShot', 'StartDelay',max(1,emi_delay), 'UserData',handles.figure1);
		start(handles.emi_timer_handle);
	end
end
guidata(handles.figure1, handles);


function emi_timer_func(timer_handle, eventdata)


function emi_timer_stop(timer_handle, eventdata)
figure1_handle = get(timer_handle, 'UserData');

if ~ishandle(figure1_handle)
	delete(timer_handle);
	return
end
handles = guidata(figure1_handle);
if strcmp(get(handles.work_abort_btn,'Enable'),'off')
	delete(timer_handle);
	return
end

handles.config.emi_generator.program_index = handles.config.emi_generator.program_index+1;
if handles.config.emi_generator.program_index > size(handles.config.emi_generator.program_list,1)
	handles.config.emi_generator.program_index = 1;
end
guidata(figure1_handle, handles);

stop_emi_generator(handles);
start_emi_generator(handles.config.emi_generator.program_list(handles.config.emi_generator.program_index,1));

handles_video  = get(handles.video.timer, 'UserData');
xml_write(handles.config_file, handles.config, 'ir_stand', struct('StructItem',false));
xml_write(fullfile(handles_video.report.path,'config.xml'), handles.config, 'ir_stand', struct('StructItem',false));

emi_delay = handles.config.emi_generator.program_list(handles.config.emi_generator.program_index,2)*60;
if emi_delay>0 && ~isinf(emi_delay)
	set(timer_handle,'StartDelay',max(1,emi_delay));
	start(timer_handle);
end


function start_emi_generator(emi_generator_program)
%% USB Connection (VISA)

obj1 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x1F01::my51350313::0::INSTR', 'Tag', '');
% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    obj1 = visa('AGILENT', 'USB0::0x0957::0x1F01::my51350313::0::INSTR');
else
    fclose(obj1);
    obj1 = obj1(1);
end
% Connect to instrument object, obj1.
fopen(obj1);

%% Reset & Status

fprintf(obj1, '*CLS');
fprintf(obj1, '*RST');
% instrumentInfo = query(obj1, '*IDN?');
% disp(['Instrument identification information: ' instrumentInfo]);

%% Commands

fprintf(obj1,':OUTPut:STATe OFF');
fprintf(obj1,':OUTPut:MODulation:STATe OFF');


fprintf(obj1,':FREQuency 66MHz');
fprintf(obj1,':POWer -10dBm');

fprintf(obj1,'*RCL 0%d,0', emi_generator_program);
fprintf(obj1,':FREQuency:MODE LIST');
fprintf(obj1,':OUTPut:STATe ON');

%%
fclose(obj1);


function stop_emi_generator(handles)
try
	if isempty(handles.config.emi_generator.program_list)
		return
	end

	%% USB Connection (VISA)
	obj1 = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x1F01::my51350313::0::INSTR', 'Tag', '');
	% Create the VISA-USB object if it does not exist
	% otherwise use the object that was found.
	if isempty(obj1)
		obj1 = visa('AGILENT', 'USB0::0x0957::0x1F01::my51350313::0::INSTR');
	else
		fclose(obj1);
		obj1 = obj1(1);
	end
	% Connect to instrument object, obj1.
	fopen(obj1);

	%% Reset & Status

	fprintf(obj1, '*CLS');
	fprintf(obj1, '*RST');
	% instrumentInfo = query(obj1, '*IDN?');
	% disp(['Instrument identification information: ' instrumentInfo]);

	%% Commands

	fclose(obj1);
catch ME
	if isfield(handles.config,'disp_debug') && handles.config.disp_debug
		disp(ME.message);
		disp(ME.stack(1));
	end
end


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
% 	if isfield(handles.config,'disp_debug') && handles.config.disp_debug
% 		disp(ME.message);
% 		disp(ME.stack(1));
% 	end
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
% 	if isfield(handles.config,'disp_debug') && handles.config.disp_debug
% 		disp(ME.message);
% 		disp(ME.stack(1));
% 	end
end

function str = toc2str(toc_t, sep_ch)
	time_s = fix(toc_t);
	time_h = fix(time_s/3600);  time_s = time_s-time_h*3600;
	time_m = fix(time_s/60);    time_s = time_s-time_m*60;
	str = sprintf('%02d%c%02d%c%02d', time_h, sep_ch, time_m, sep_ch, time_s);
	
function data = make_stat_shift(data, shift_sz, merge_func)
	data_merge = zeros([size(data) 2*shift_sz+1]);

	data_big = [repmat(data(1,:),shift_sz,1); data; repmat(data(end,:),shift_sz,1)];
	for sh=-shift_sz:shift_sz
		data_merge(:,:,sh+shift_sz+1) = data_big(sh+shift_sz+(1:size(data,1)),:);
	end
	data = merge_func(data_merge, [], 3);

	data_big = [repmat(data(:,1),1,shift_sz), data, repmat(data(:,end),1,shift_sz)];
	for sh=-shift_sz:shift_sz
		data_merge(:,:,sh+shift_sz+1) = data_big(:,sh+shift_sz+(1:size(data,2)));
	end
	data = merge_func(data_merge, [], 3);

function video_timer_func(timer_handle, eventdata)
try
	%% Camera image aquiring and displaying
	handles_video = get(timer_handle,'UserData');
	frame_cur = getsnapshot(handles_video.vidobj);
	frame_cur = frame_cur(1:end-3,1:end-3,1);

	% For DEBUG ONLY
	if isfield(handles_video.config,'debug_save_frames') && handles_video.config.debug_save_frames
		save(sprintf('frame_cur_%05d.mat',handles_video.toc_frames),'frame_cur','-v6');
	end

	ax = fix(handles_video.config.video_device.axis);
	frame_cur = double(frame_cur(ax(3)+1:ax(4), ax(1)+1:ax(2))) / double(intmax(class(frame_cur)));
	if handles_video.config.video_device.autobalance
		t_rg = handles_video.config.video_device.t_range;
		imagesc(frame_cur*(t_rg(2)-t_rg(1))+t_rg(1), 'Parent',handles_video.handles.work_img_orig);
		cur_min = min(frame_cur(:));
		cur_max = max(frame_cur(:));
		frame_cur_rgb = fix((frame_cur-cur_min)/(cur_max-cur_min)*63)+1;
	else
		image(frame_cur*64, 'Parent',handles_video.handles.work_img_orig);
		frame_cur_rgb = fix(frame_cur/4);
	end
	frame_cur_rgb = reshape(handles_video.palette(max(1,min(64,frame_cur_rgb)),:,:), [size(frame_cur_rgb) 3]);
	axis(handles_video.handles.work_img_orig,'equal');
	set(handles_video.handles.work_img_orig, 'XTick',[], 'YTick',[]);
	frame_sz = size(frame_cur);
	frame_cur = transpose(frame_cur(:));

	%% Brightness changing adaptation
	if handles_video.config.thresholds.filter_no_median
		frame_cur = frame_cur - median(frame_cur);
	end

	%% Time stamp displaying
	toc_t = toc(handles_video.tic_id);
	handles_video.toc_frames = handles_video.toc_frames+1;
	set(handles_video.handles.work_timer, 'String', [toc2str(toc_t,':') sprintf(' (%d)', handles_video.toc_frames)]);

	%% Image processing cycle
	switch handles_video.work_stage
		%% Start camera initialisation stage -- just skip frames
		case 0
			if toc_t>handles_video.config.thresholds.start_delay && handles_video.toc_frames>10
				handles_video.work_stage = 100;
			end

		%% High pass filer initialisation stage
		case 100  % Initialise high pass filter
			if handles_video.config.thresholds.filter_hp_factor==-1
				handles_video.work_stage = 200;
			else
				if ~isfield(handles_video,'filter_hp_images')
					handles_video.filter_hp_images = {};
				end

				handles_video.filter_hp_images{end+1,1} = frame_cur;

				if size(handles_video.filter_hp_images,1)>=10
					filter_hp_images = cell2mat(handles_video.filter_hp_images);
					handles_video = rmfield(handles_video,'filter_hp_images');
					
					handles_video.filter_hp = struct('init_cnt',0, 'b',[1 -1], 'a',[1 handles_video.config.thresholds.filter_hp_factor], 'z',-mean(filter_hp_images));

					handles_video.work_stage = 101;
				end
			end
		case 101 % Stabilize high pass filter output
			if handles_video.filter_hp.init_cnt < handles_video.config.thresholds.filter_hp_initframes
				handles_video.filter_hp.init_cnt = handles_video.filter_hp.init_cnt+1;
				[~, handles_video.filter_hp.z] = filter(handles_video.filter_hp.b, handles_video.filter_hp.a, frame_cur, handles_video.filter_hp.z, 1);
			end
			if handles_video.filter_hp.init_cnt >= handles_video.config.thresholds.filter_hp_initframes
				handles_video.work_stage = 200;
			end

		%% Statistics initialisation stage
		case 200
			if isfield(handles_video,'filter_hp')
				[frame_cur, handles_video.filter_hp.z] = filter(handles_video.filter_hp.b, handles_video.filter_hp.a, frame_cur, handles_video.filter_hp.z, 1);
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
				else
					handles_video.stat.lo = -inf(1,size(stat_imgs,2));
				end
				handles_video.stat.hi = quantile(stat_imgs, handles_video.config.thresholds.stat_hi, 1);

				if handles_video.config.thresholds.stat_pixshift>0
					stat_lo_sqr = reshape(handles_video.stat.lo, frame_sz);
					stat_lo_sqr = make_stat_shift(stat_lo_sqr, handles_video.config.thresholds.stat_pixshift, @min);
					handles_video.stat.lo = reshape(stat_lo_sqr, size(handles_video.stat.lo));

					stat_hi_sqr = reshape(handles_video.stat.hi, frame_sz);
					stat_hi_sqr = make_stat_shift(stat_hi_sqr, handles_video.config.thresholds.stat_pixshift, @max);
					handles_video.stat.hi = reshape(stat_hi_sqr, size(handles_video.stat.hi));
				end

				handles_video.work_stage = 300;
				start_generators(handles_video.handles);
			end

		%% Main work stage
		case 300
			% High pass filtering
			if isfield(handles_video,'filter_hp')
				[frame_cur, handles_video.filter_hp.z] = filter(handles_video.filter_hp.b, handles_video.filter_hp.a, frame_cur, handles_video.filter_hp.z, 1);
			end

			% Statistics checkign
			is_signaling = (frame_cur<handles_video.stat.lo) | (frame_cur>handles_video.stat.hi);

			% Median filtering
			if handles_video.config.thresholds.median_size>1
				is_signaling = reshape(is_signaling, frame_sz);
				is_signaling = medfilt2(is_signaling, handles_video.config.thresholds.median_size+[0 0]);
				is_signaling = transpose(is_signaling(:));
			end
			frame_cur_bw_mask = repmat(reshape(is_signaling, frame_sz),[1 1 3]);
			frame_cur_bw = uint8(frame_cur_bw_mask);
			frame_cur_bw(frame_cur_bw_mask) = 255;
			imshow(frame_cur_bw, 'Parent',handles_video.handles.work_img_bw);

			% Detector: estimate currect values
			det_points = sum(is_signaling);
			det_part =   mean(is_signaling);

			if ~isfield(handles_video,'detector')
				handles_video.detector = struct('graphs',zeros(0,3), 'state',false, 'thresholds_on_toc',-inf);

				handles_video.report = struct(	'fh',-1, 'prebuf_img',{{}}, 'prebuf_toc',zeros(0,2), ...
												'normal_img_cnt',0, 'normal_img_toc',-inf, 'overall',{{}});

				if not(isempty(handles_video.config.thresholds.report_path))
					[cur.Y, cur.M, cur.D, cur.H, cur.MN, cur.S] = datevec(now);
					handles_video.report.path = fullfile(handles_video.config.thresholds.report_path, sprintf('%s_%d.%d.%d_%02d.%02d.%02d', mfilename, cur.Y, cur.M, cur.D, cur.H, cur.MN, round(cur.S)), filesep);
					[mk_status, mk_message] = mkdir(handles_video.report.path);
					if mk_status~=1
						error('disp:report',['Ошибка создания каталога "' handles_video.report.path '" протокола: ' mk_message]);
					end
					
					xml_write(fullfile(handles_video.report.path,'config.xml'), handles_video.config, 'ir_stand', struct('StructItem',false));

					handles_video.report.fh = fopen(fullfile(handles_video.report.path,'graphs.txt'), 'wt');
					if handles_video.report.fh==-1
						error('disp:report',['Ошибка создания файла "' fullfile(handles_video.report.path,'graphs.txt') '" протокола.']);
					end

					if handles_video.config.thresholds.report_detoff_img_number>0
						handles_video.report.normal_path = fullfile(handles_video.report.path, 'normal', filesep);
						[mk_status, mk_message] = mkdir(handles_video.report.normal_path);
						if mk_status~=1
							error('disp:report',['Ошибка создания каталога "' handles_video.report.normal_path '" протокола: ' mk_message]);
						end
					end
				end
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

			% Save report graphs file
			if handles_video.report.fh~=-1
				fprintf(handles_video.report.fh, '%d\t%f\t%d\t%e\n', handles_video.toc_frames, toc_t, det_points, det_part);
			end

			% Detector switch on|off logic
			if handles_video.detector.state~=new_st
				if new_st % Detector just turn ON - make anomaly report
					handles_video.report.overall(end+1,2:4) = {datestr(now) toc2str(toc_t,':') sprintf('%d',handles_video.toc_frames)};

					scatter(0,0,300,[1 0 0],'filled', 'Parent',handles_video.handles.detector_lamp);

					if handles_video.report.fh~=-1 && handles_video.config.thresholds.report_deton_img_number>0
						handles_video.report.anomaly_path = fullfile(handles_video.report.path, sprintf('anomaly_%06d_%s', handles_video.toc_frames, toc2str(toc_t,'.')), filesep);
						[mk_status, mk_message] = mkdir(handles_video.report.anomaly_path);
						if mk_status~=1
							error('disp:report',['Ошибка создания каталога "' handles_video.report.anomaly_path '" протокола: ' mk_message]);
						end
						
						handles_video.report.overall{end,1} = handles_video.report.anomaly_path;

						% Save prebuffered images to log
						handles_video.report.anomaly_img_cnt = numel(handles_video.report.prebuf_img);
						handles_video.report.anomaly_img_toc = -inf;

						for ii = 1:handles_video.report.anomaly_img_cnt
							imwrite(handles_video.report.prebuf_img{ii}, sprintf('%simage_%06d_%s.png',handles_video.report.anomaly_path, handles_video.report.prebuf_toc(ii,1), toc2str(handles_video.report.prebuf_toc(ii,2),'.')), 'png');
						end
						handles_video.report.prebuf_img = {};
						handles_video.report.prebuf_toc = zeros(0,2);
					end

					% @@ TODO: Save Generators state

				else % Detector just turn OFF
					handles_video.report.overall(end,5:7) = {datestr(now) toc2str(toc_t,':') sprintf('%d',handles_video.toc_frames)};

					scatter(0,0,300,0.3+[0 0 0],'filled', 'Parent',handles_video.handles.detector_lamp, 'Visible','off');
					handles_video.report.normal_img_toc = toc_t;
				end

				set(handles_video.handles.detector_lamp, 'Visible','off');
				handles_video.detector.state=new_st;
			end

			if	handles_video.detector.state && handles_video.report.fh~=-1 && handles_video.config.thresholds.report_deton_img_number>0
				if handles_video.report.anomaly_img_cnt < handles_video.config.thresholds.report_deton_img_number && ...
						toc_t-handles_video.report.anomaly_img_toc >= handles_video.config.thresholds.report_deton_img_interval
					imwrite([frame_cur_rgb frame_cur_bw], sprintf('%simage_%06d_%s.png',handles_video.report.anomaly_path, handles_video.toc_frames, toc2str(toc_t,'.')), 'png');
					handles_video.report.anomaly_img_cnt = handles_video.report.anomaly_img_cnt+1;
					handles_video.report.anomaly_img_toc = toc_t;
				end
			end

			if ~handles_video.detector.state
				if handles_video.report.normal_img_cnt < handles_video.config.thresholds.report_detoff_img_number && ...
						toc_t-handles_video.report.normal_img_toc >= handles_video.config.thresholds.report_detoff_img_interval
					imwrite([frame_cur_rgb frame_cur_bw], sprintf('%simage_%06d_%s.png',handles_video.report.normal_path, handles_video.toc_frames, toc2str(toc_t,'.')), 'png');
					handles_video.report.normal_img_cnt = handles_video.report.normal_img_cnt+1;
					handles_video.report.normal_img_toc = toc_t;
				end

				if handles_video.config.thresholds.detector_pre_buff>0 && handles_video.config.thresholds.report_deton_img_number>0
					handles_video.report.prebuf_img{end+1} = [frame_cur_rgb frame_cur_bw];
					handles_video.report.prebuf_toc(end+1,:) = [handles_video.toc_frames toc_t];

					kill_mask = handles_video.report.prebuf_toc(:,2) < toc_t-handles_video.config.thresholds.detector_pre_buff;
					kill_mask(1 : end-max(0,handles_video.config.thresholds.report_deton_img_number-1)) = true;

					handles_video.report.prebuf_img(kill_mask) = [];
					handles_video.report.prebuf_toc(kill_mask,:) = [];
				end
			end

		%% Program logic error trap
		otherwise
			disp('ERROR: Unknown work stage.');
			error('ERROR: Unknown work stage.');
	end
	
	set(timer_handle, 'UserData',handles_video);

	drawnow();
catch ME
	if strcmp(ME.identifier,'disp:report') || (isfield(handles_video.config,'disp_debug') && handles_video.config.disp_debug)
		disp(ME.message);
		disp(ME.stack(1));
	end
end


function temp = rgb2temp(pic_rgb)
pic_rgb  = single(pic_rgb);

yuv_luma = 0.299*pic_rgb(:,:,1) + 0.587*pic_rgb(:,:,2) + 0.114*pic_rgb(:,:,3);

temp = 0.005319*yuv_luma -0.1609;

% temp = min(1,max(0,temp));


function player_timer_stop(timer_handle, eventdata)
delete(timer_handle);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

work_abort_btn_Callback(hObject, eventdata, handles)

% Hint: delete(hObject) closes the figure
delete(hObject);
