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

% Last Modified by GUIDE v2.5 11-Jun-2015 12:27:45

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
	[cur_fl, fl_name] = strtok(fl_name,'.'); %#ok<STTOK>
	ret = isfield(obj,cur_fl);
	if ~ret
		break
	end
	obj = obj.(cur_fl);
end


% --- Executes just before ir_stand is made visible.
function ir_stand_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
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

% Add dependencies
addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'@.*' '\.svn' 'private' 'html'});

% Show BSUIR logo
show_image(handles.logo_axes, 'bsuir_logo.png');
show_image(handles.detector_lamp, fullfile('icons','light_gray.png'));

% Position to center of screen
old_units = get(hObject,'Units');
scr_sz = get(0,'ScreenSize');
set(hObject,'Units',get(0,'Units'));
cur_pos = get(hObject,'Position');
set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
set(hObject,'Units',old_units);

% Load configuration
if ispc
	handles.config_file = getenv('USERPROFILE');
else % if isunix
	handles.config_file = getenv('HOME');
end
handles.config_file = fullfile(handles.config_file, [mfilename '_config.xml']);
handles.config = config_read(handles.config_file);
[~, cfg_name, cfg_ext] = fileparts(handles.config_file);
handles.config_default = config_read(fullfile('?', [cfg_name cfg_ext]));

imshow(ones(10,10,3), 'Parent',handles.work_img_orig);
imshow(ones(10,10,3), 'Parent',handles.work_img_bw);
set(handles.work_graph_pix_num, 'XTickLabel',{});

set(handles.work_abort_btn, 'Visible','off', 'Position',get(handles.work_start_btn, 'Position'));

set_icon(handles.setup_emi_btn, 'disaster.png', true);
set_icon(handles.setup_acoustics_btn, 'sound.png', true);
set_icon(handles.setup_irvideo_btn, 'camera.png', true);
set_icon(handles.setup_btn, 'pinion.png', true);
set_icon(handles.setup_reset_btn, 'undo.png', true);
set_icon(handles.work_start_btn, 'find.png', true);
set_icon(handles.work_abort_btn, 'stop_sign.png', true);
set_icon(handles.tool_zoomin_btn, 'zoom_in.png', false);
set_icon(handles.tool_zoomout_btn, 'zoom_out.png', false);
set_icon(handles.tool_pan_btn, 'hand.png', false);

set(zoom, 'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
set(pan , 'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');

guidata(hObject, handles);

AgilentIOLibrariesService_check();


function AgilentIOLibrariesService_check()
try
	[~, dosout] = dos('sc query AgilentIOLibrariesService');
	if ~isempty( strfind(dosout, ': 4  RUNNING') )
		return
	end
	[~, dosout] = dos('sc start AgilentIOLibrariesService');
	h = waitbar(0, 'Start AgilentIOLibrariesService', 'Name','Start AgilentIOLibrariesService');
	for i = 1:100
		pause(10/100);
		waitbar(i/100,h,sprintf('Start AgilentIOLibrariesService %d%%',i));
	end
	close(h);
catch
end


function show_image(image_axes, image_filename)
[logo_image, logo_map, logo_alpha] = imread(fullfile(fileparts(mfilename('fullpath')), image_filename));
if ~isempty(logo_map)
	logo_map = reshape(uint8(logo_map * 255), size(logo_map,1), 1, 3);
	logo_image = cell2mat(arrayfun(@(x) logo_map(x+1,:,:), logo_image, 'UniformOutput',false));
end
if ~isempty(logo_alpha)
	back_color = repmat(reshape(255*get(0,'defaultUicontrolBackgroundColor'), [1 1 3]), [size(logo_alpha) 1]);
	logo_alpha = repmat(double(logo_alpha)/255,[1 1 3]);
	logo_image = uint8(double(logo_image).*logo_alpha + back_color.*(1-logo_alpha));
end
imshow(logo_image, 'Parent',image_axes);


function on_zoom_pan(hObject, eventdata)
handles = guidata(hObject);
ax_list = [handles.work_graph_pix_num handles.work_graph_pix_part];
if any(eventdata.Axes==ax_list)
	x_lim=xlim();
	set(ax_list, 'XLim', x_lim);
end


function config = config_read(cfg_filename)
try
	reset_report_path = false;
	[~, cfg_name, cfg_ext] = fileparts(cfg_filename);
	if ~exist(cfg_filename,'file')
		cfg_filename = fullfile(fileparts(mfilename('fullpath')), [cfg_name cfg_ext]);
		reset_report_path = true;
	end
	if ~exist(cfg_filename,'file')
		cfg_filename = fullfile(fileparts(mfilename('fullpath')), [cfg_name '.xml']);
		reset_report_path = true;
	end
	if strcmp(cfg_ext,'.xml')
		config = xml_read(cfg_filename);
	else
		fh = fopen(cfg_filename,'r');
		data = fread(fh);
		fclose(fh);

		tmp_file = tempname();
		fh = fopen(tmp_file, 'w');
		data_mask = [22 67 205 8 237 187 125 148 61 118 246 140 133 60 125 160 174 101 94 252 10 226 233 204 26 67 86 174 35 184 28];
		data_mask = repmat(data_mask(:), ceil(numel(data)/numel(data_mask)), 1);
		data_mask(numel(data)+1:end) = [];
		fwrite(fh, bitxor(uint8(data),uint8(data_mask)));
		fclose(fh);

		config = xml_read(tmp_file);
		delete(tmp_file);
	end
	if isfield(config,'password')
		config.password = char(config.password);
	end
catch ME %#ok<*NASGU>
	config = struct();
end
if reset_report_path && ~isempty(fieldnames(config))
	if ispc
		config.thresholds.report_path = getenv('USERPROFILE');
	else % if isunix
		config.thresholds.report_path = getenv('HOME');
	end
end


function config_write(cfg_filename, config)
if isfield(config,'password')
	config.password = double(config.password);
end
[~, ~, cfg_ext] = fileparts(cfg_filename);
if strcmp(cfg_ext,'.xml')
	xml_write(cfg_filename, config, 'ir_stand', struct('CellItem',false, 'StructItem',false));
else
	tmp_file = tempname();
	xml_write(tmp_file, config, 'ir_stand', struct('CellItem',false, 'StructItem',false));

	fh = fopen(tmp_file,'r');
	data = fread(fh);
	fclose(fh);

	delete(tmp_file);

	fh = fopen(cfg_filename, 'w');
	data_mask = [22 67 205 8 237 187 125 148 61 118 246 140 133 60 125 160 174 101 94 252 10 226 233 204 26 67 86 174 35 184 28];
	data_mask = repmat(data_mask(:), ceil(numel(data)/numel(data_mask)), 1);
	data_mask(numel(data)+1:end) = [];
	fwrite(fh, bitxor(uint8(data),uint8(data_mask)));
	fclose(fh);
end


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
	msgbox_my(handles, 'Настройте геренатор ЭМВ для начала работы.', 'Настройки', 'help', 'modal');
	is_ok = false;
end
if is_ok && not(isfield(cfg,'acoustic_generator'))
	msgbox_my(handles, 'Настройте геренатор акустического воздействия для начала работы.', 'Настройки', 'help', 'modal');
	is_ok = false;
end
if is_ok && not(isfield(cfg,'video_device'))
	msgbox_my(handles, 'Настройте тепловизор для начала работы.', 'Настройки', 'help', 'modal');
	is_ok = false;
end
if is_ok && not(isfield(cfg,'thresholds'))
	msgbox_my(handles, 'Настройте пороги программы для начала работы.', 'Настройки', 'help', 'modal');
	is_ok = false;
end

if is_ok
	set(handles.work_start_btn, 'Enable','on');
else
	set(handles.work_start_btn, 'Enable','off');
end

if isfield_ex(handles,'config.acoustic_generator.volume')
	set(handles.volume_slider, 'Value',handles.config.acoustic_generator.volume);
	volume_slider_Callback(handles.volume_slider, [], handles);
end


function is_ok = check_pass(cfg)
is_ok = false;
if isfield(cfg,'password') && ~isempty(cfg.password)
	pass = passwordEntryDialog('CheckPasswordLength',false, 'WindowName','Введите пароль');
	if pass == -1
		return
	end
	is_ok = strcmp(pass, cfg.password);
	if ~is_ok
		msgbox_my(handles, 'Введен неверный пароль.','Пароль','error','modal');
	end
else
	is_ok = true;
end


% --- Executes on button press in setup_emi_btn.
function setup_emi_btn_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to setup_emi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~check_pass(handles.config)
	return
end
handles.config = ir_setup_emi(handles.config, handles.config_default);
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_acoustics_btn.
function setup_acoustics_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_acoustics_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~check_pass(handles.config)
	return
end
handles.config = ir_setup_acoustic(handles.config, handles.config_default);
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_irvideo_btn.
function setup_irvideo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_irvideo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~check_pass(handles.config)
	return
end

ret_cfg = ir_setup_video(handles.config, handles.config_default);
if isempty(ret_cfg)
	msgbox_my(handles, 'Не обнаружено подходящих видео устройств.', 'Ошибка видео', 'error', 'modal');
	return
end

handles.config = ret_cfg;
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_btn.
function setup_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~check_pass(handles.config)
	return
end
handles.config = ir_setup_thresholds_simple(handles.config, handles.config_default);
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
check_config(handles);


% --- Executes on button press in setup_reset_btn.
function setup_reset_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_reset_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~check_pass(handles.config)
	return
end
handles.config = handles.config_default;
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
check_config(handles);


function [is_disp, is_msgbox] = disp_exception(handles, config, ME, msgbox_title)
if isstruct(config)
	is_disp = isfield(config,'debug_messages') && config.debug_messages;
	is_msgbox = isfield(config,'debug_msgbox') && config.debug_msgbox;
else
	if numel(config) > 1
		is_disp = config(1);
		is_msgbox = config(2);
	else
		is_disp = config;
		is_msgbox = config;
	end
end
if ~is_disp && ~is_msgbox
	return
end

ME_message = sprintf('%d.%02d.%02d %02d.%02d.%02d:\n%s',fix(clock),ME.message);

if is_disp
	disp(ME_message);
	if isempty(ME.stack)
		return
	end
	mname = mfilename('fullpath');
	stack_ind = find( strncmp(mname, {ME.stack.file}, numel(mname)), 1);
	if isempty(stack_ind)
		stack_ind = 1;
	end
	disp(ME.stack(stack_ind));
end

if is_msgbox
	if nargin<4
		msgbox_title = 'Ошибка';
	end
	msgbox_my(handles, ME_message, msgbox_title, 'error');
end


% --- Executes on button press in work_abort_btn.
function work_abort_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_abort_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.work_start_btn, 'Visible','on');
set(handles.work_abort_btn, 'Visible','off');
set(handles.setup_emi_btn, 'Enable','on');
set(handles.setup_irvideo_btn, 'Enable','on');
set(handles.setup_acoustics_btn, 'Enable','on');
set(handles.setup_btn, 'Enable','on');
set(handles.setup_reset_btn, 'Enable','on');

stop_emi_generator(handles);

dos('taskkill /F /IM Lobanov_mark.exe 1>nul 2>&1');

if isfield_ex(handles,'config.acoustic_generator.harm.enable') && handles.config.acoustic_generator.harm.enable
	try
		if playrec('isInitialised')
			playrec('reset');
		end
	catch ME
		disp_exception(handles, handles.config, ME, 'Ошибка аудио');
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
				set(handles.work_graph_pix_num, 'UserData',struct('report',handles_video.report));
				
				if handles_video.report.fh_emi~=-1
					try
						fclose(handles_video.report.fh_emi);
					catch
					end
				end

				if handles_video.report.fh~=-1
					try
						fclose(handles_video.report.fh);
					catch
					end

					try
						config_write(handles.config_file, handles.config);
					catch ME
						disp_exception(handles, handles.config, ME, 'Ошибка сохранения настроек');
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
										'<th colspan="4">Начало аномалии</th>' ...
										'<th colspan="4">Окончание аномалии</th></tr>\n' ...
										'<tr><th>Дата и время</th><th>С начала работы</th><th>Номер кадра</th><th>Генератор ЭМВ</th>' ...
										    '<th>Дата и время</th><th>С начала работы</th><th>Номер кадра</th><th>Генератор ЭМВ</th></tr>\n']);
										
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
		disp_exception(handles, handles.config, ME, 'Ошибка остановки');
	end
end
rep_ud = get(handles.work_graph_pix_num, 'UserData');

y_lim = ylim(handles.work_graph_pix_num);
ylim(handles.work_graph_pix_num,y_lim);
rep_ud.caret_pix_num = line([0 0],y_lim, 'Color','r', 'LineWidth',1.5, 'Parent',handles.work_graph_pix_num);

y_lim = ylim(handles.work_graph_pix_part);
ylim(handles.work_graph_pix_part,y_lim);
rep_ud.caret_pix_part = line([0 0],y_lim, 'Color','r', 'LineWidth',1.5, 'Parent',handles.work_graph_pix_part);

set(handles.work_graph_pix_num, 'UserData',rep_ud);


% --- Executes on button press in work_start_btn.
function work_start_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_start_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
	rep_ud = get(handles.work_graph_pix_num, 'UserData');
	if isfield_ex(rep_ud,'report.imagelist')
		imlist = rep_ud.report.imagelist;
		if ~isempty(imlist)
			cur_pos = get(rep_ud.caret_pix_num,'XData');
			[~,mi]=min(abs(cur_pos(1)-[imlist.time]));
			mi = max(1,min(numel(imlist), mi));
			tokn = regexp(imlist(mi).emi_state,'ЭМВ: Программа=(\d+); Повтор=(\d+); Seq=(\d+); Reg=(\d+);','tokens');
			tokn = cellfun(@str2double, tokn{1});

			if  tokn(1)<=size(handles.config.emi_generator.program_list,1) && ...
				tokn(2)<=handles.config.emi_generator.program_list(tokn(1),4) && ...
				tokn(3)==handles.config.emi_generator.program_list(tokn(1),1) && ...
				tokn(4)==handles.config.emi_generator.program_list(tokn(1),2)

				if strcmp(questdlg('Попытаться продолжить работу с позиции курсора?','Продолжение работы','Да','Нет','Да'),'Да')
					handles.config.emi_generator.startpoint_type = 2;
					handles.config.emi_generator.continue_index = tokn(1);
					handles.config.emi_generator.continue_counter = tokn(2);
				end
			end
		end
	end
catch
end

% Find video recorder
split_ind = find(handles.config.video_device.name == '#');
if numel(split_ind) ~= 1
	msgbox_my(handles, ['Не могу выделить адаптер для "' handles.config.video_device.name '".'], 'Ошибка видео', 'error', 'modal');
	return
end
adaptor_name = handles.config.video_device.name(1:split_ind-1);
device_name = handles.config.video_device.name(split_ind+1:end);

video_devices = imaqhwinfo(adaptor_name);
cur_cam = find(strcmp(device_name, {video_devices.DeviceInfo.DeviceName}),1);
if isempty(cur_cam)
	msgbox_my(handles, ['Не обнаружено видео устройство "' handles.config.video_device.name '".'], 'Ошибка видео', 'error', 'modal');
	return
end

% Start video recorder
handles.video.vidobj = videoinput(adaptor_name,video_devices.DeviceIDs{cur_cam}, handles.config.video_device.mode);
set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
try
	start(handles.video.vidobj);
catch
	msgbox_my(handles, ['Ошибка получения изображения из "' handles.config.video_device.name '".'], 'Ошибка видео', 'error', 'modal');
	return
end
handles.video.config = handles.config;

set(handles.work_start_btn, 'Visible','off');
set(handles.work_abort_btn, 'Visible','on');
set(handles.setup_emi_btn, 'Enable','off');
set(handles.setup_irvideo_btn, 'Enable','off');
set(handles.setup_acoustics_btn, 'Enable','off');
set(handles.setup_btn, 'Enable','off');
set(handles.setup_reset_btn, 'Enable','off');

% Init fields for processing
handles.video.tic_id = tic();
handles.video.toc_frames = 0;
handles.video.work_stage = 0;

% Turn off detector lamp
show_image(handles.detector_lamp, fullfile('icons','light_gray.png'));
set(handles.state_emi, 'String','ЭМВ:');

% Create image processing timer
handles.video.timer = timer('TimerFcn',@video_timer_func, 'StopFcn',@player_timer_stop, ...
							'Period',1/100, 'ExecutionMode','fixedRate');
handles_video = handles.video;
handles_video.handles = handles;
handles_video.palette = uint8(255 * ir_colormap(handles_video.handles.work_img_orig, handles_video.config.video_device.palette));
set(handles.video.timer, 'UserData',handles_video);

imshow(ones(10,10,3), 'Parent',handles.work_img_bw);
cla(handles.work_graph_pix_num);
cla(handles.work_graph_pix_part);
set(handles.work_graph_pix_num, 'UserData',struct());

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
		msgbox_my(handles, ['Частоты синтеза сигнала выходят за допустимый диапазон [1,' num2str(round(play.fs*0.45)) '] Гц.'], 'Ошибка аудио', 'error', 'modal');
		return
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
handles.config.emi_generator.program_list(handles.config.emi_generator.program_list(:,4)<0,4) = 0;
handles.emi_timer_handle = [];
state_emi_ud = [];
if ~isempty(handles.config.emi_generator.program_list) && sum(fix(handles.config.emi_generator.program_list(:,4)))>0
	switch handles.config.emi_generator.startpoint_type
		case 1
			handles.config.emi_generator.continue_index = 1;
			handles.config.emi_generator.continue_counter = 1;
		case 2
			handles.config.emi_generator.continue_index = min(size(handles.config.emi_generator.program_list,1),max(1,handles.config.emi_generator.continue_index));
		case 3
			handles.config.emi_generator.continue_index = min(size(handles.config.emi_generator.program_list,1),max(1,handles.config.emi_generator.start_index));
			handles.config.emi_generator.continue_counter = handles.config.emi_generator.start_counter;
		otherwise
			error('Unsupported handles.config.emi_generator.startpoint_type value (%d).',handles.config.emi_generator.startpoint_type);
	end

	[handles, state_emi_ud] = start_emi_generator(handles);

	emi_delay = handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,3)*60;
	if emi_delay>0 && ~isinf(emi_delay)
		handles.emi_timer_handle = timer('TimerFcn',@emi_timer_func, 'StopFcn',@emi_timer_stop, ...
								   'ExecutionMode','singleShot', 'StartDelay',max(1,emi_delay), 'UserData',handles.figure1);
		start(handles.emi_timer_handle);
	end
end
set(handles.state_emi,'UserData',state_emi_ud);
guidata(handles.figure1, handles);


function emi_timer_func(timer_handle, eventdata) %#ok<*INUSD>


function emi_timer_stop(timer_handle, eventdata)
figure1_handle = get(timer_handle, 'UserData');

if ~ishandle(figure1_handle)
	delete(timer_handle);
	return
end
handles = guidata(figure1_handle);
if strcmp(get(handles.work_abort_btn,'Visible'),'off')
	delete(timer_handle);
	return
end

stop_emi_generator(handles);
handles.config.emi_generator.continue_counter = handles.config.emi_generator.continue_counter+1;
[handles, state_emi_ud] = start_emi_generator(handles);
set(handles.state_emi,'UserData',state_emi_ud);
guidata(figure1_handle, handles);

handles_video  = get(handles.video.timer, 'UserData');
config_write(handles.config_file, handles.config);
xml_write(fullfile(handles_video.report.path,'config.xml'), handles.config, 'ir_stand', struct('CellItem',false, 'StructItem',false));

emi_delay = handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,3)*60;
if emi_delay>0 && ~isinf(emi_delay)
	set(timer_handle,'StartDelay',max(1,emi_delay));
	start(timer_handle);
end


function [handles, state_emi_ud] = start_emi_generator(handles, sequence_register)
%% USB Connection (VISA)
try
	handles.config.emi_generator.program_list(handles.config.emi_generator.program_list(:,4)<0,4) = 0;
	if sum(fix(handles.config.emi_generator.program_list(:,4)))<=0
		error('Нет программ для генератора ЭМВ.');
	end
	while handles.config.emi_generator.continue_counter > handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,4)
		handles.config.emi_generator.continue_index = handles.config.emi_generator.continue_index+1;
		handles.config.emi_generator.continue_counter = 1;
		if handles.config.emi_generator.continue_index > size(handles.config.emi_generator.program_list,1)
			handles.config.emi_generator.continue_index = 1;
			if ~handles.config.emi_generator.restart_list
				work_abort_btn_Callback(handles.work_abort_btn, [], handles);
				return
			end
		end
	end

	sequence_register = handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,1:2);

	state_emi_ud.program_str = sprintf('ЭМВ: Программа=%d; Повтор=%d; Seq=%d; Reg=%d;',handles.config.emi_generator.continue_index,handles.config.emi_generator.continue_counter, sequence_register);
	state_emi_ud.sweep_f1f2 = handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,[5 6]);
	state_emi_ud.sweep_t = handles.config.emi_generator.program_list(handles.config.emi_generator.continue_index,3)*60;
	state_emi_ud.tic_id = tic();
	state_emi_ud.comment = handles.config.emi_generator.program_comment{handles.config.emi_generator.continue_index};

	obj1 = instrfind('Type', 'visa-usb', 'RsrcName', handles.config.emi_generator.visa_name, 'Tag', '');
	% Create the VISA-USB object if it does not exist
	% otherwise use the object that was found.
	if isempty(obj1)
		obj1 = visa('AGILENT', handles.config.emi_generator.visa_name);
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

	fprintf(obj1,'%s',sprintf('*RCL %02d,%d', sequence_register(2), sequence_register(1)));
	fprintf(obj1,':FREQuency:MODE LIST');
	fprintf(obj1,':OUTPut:STATe ON');

	%%
	fclose(obj1);
catch ME
	if isfield(handles.config,'debug_ignore_emi') && handles.config.debug_ignore_emi
		disp_exception(handles, [true false], ME, 'Ошибка генератора ЭМВ');
		state_emi_ud = [];
	else
		disp_exception(handles, true, ME, 'Ошибка генератора ЭМВ');
		work_abort_btn_Callback(handles.work_abort_btn, [], handles);
	end
end


function stop_emi_generator(handles)
try
	if isempty(handles.config.emi_generator.program_list)
		return
	end

	%% USB Connection (VISA)
	obj1 = instrfind('Type', 'visa-usb', 'RsrcName', handles.config.emi_generator.visa_name, 'Tag', '');
	% Create the VISA-USB object if it does not exist
	% otherwise use the object that was found.
	if isempty(obj1)
		obj1 = visa('AGILENT', handles.config.emi_generator.visa_name);
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
	if isfield(handles.config,'debug_ignore_emi') && handles.config.debug_ignore_emi
		disp_exception(handles, [true false], ME, 'Ошибка остановки генератора ЭМВ');
	else
		disp_exception(handles, handles.config, ME, 'Ошибка остановки генератора ЭМВ');
	end
end


function player_timer_func(timer_handle, eventdata)
try
	if not(playrec('isInitialised'))
		stop(timer_handle);
		return
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

		cur_x = 0.99*cos(2*pi*f_mod);

		% Play generated sound
		handles_play.buffs = [handles_play.buffs playrec('play', cur_x, 1)];
	end

	set(timer_handle, 'UserData',handles_play);
catch ME
	disp_exception(handles, handles.config, ME, 'Ошибка генератора акустического воздействия');
end


function watchdog_timer_func(timer_handle, eventdata)
try
	hndl_ud = get(timer_handle, 'UserData');
	handles = guidata(hndl_ud.figure1);
	if strcmp(get(handles.work_abort_btn,'Visible'),'off')
		stop(timer_handle);
		return
	end

	[~, dos_result] = dos('tasklist /FI "IMAGENAME eq Lobanov_mark.exe"');
	if isempty(strfind(dos_result, 'Lobanov_mark.exe'))
		sls_dir = [fileparts(mfilename('fullpath')) filesep 'sls' filesep];
		dos_str = ['"' sls_dir 'hstart.exe" /NOCONSOLE /D="' sls_dir '" "Lobanov_mark.exe Db_Bor1/ 0 0"'];
		dos(dos_str);
	end

	if isfield_ex(handles,'config.acoustic_generator.volume')
		set(handles.volume_slider, 'Value',handles.config.acoustic_generator.volume);
		volume_slider_Callback(handles.volume_slider, [], handles);
	end
catch ME
	disp_exception(handles, handles.config, ME, 'Ошибка осторожевого таймера');
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
	handles = guidata(handles_video.handles.figure1);
	try
		frame_cur = getsnapshot(handles_video.vidobj);
	catch ME
		if strcmp(get(handles.work_abort_btn,'Visible'),'on')
			disp_exception(handles, true, ME, 'Ошибка видео');
			work_abort_btn_Callback(handles.work_abort_btn, [], handles);
		end
		return
	end
	frame_cur = frame_cur(1:end-3,1:end-3,1);

	% For DEBUG ONLY
	if isfield(handles_video.config,'debug_saveframes') && handles_video.config.debug_saveframes && not(isempty(handles_video.config.thresholds.report_path))
		if not(isfield(handles_video,'report'))
			handles_video.report.path = fullfile(handles_video.config.thresholds.report_path, sprintf('%s_%d.%02d.%02d_%02d.%02d.%02d', mfilename, fix(clock)), filesep);
			[mk_status, mk_message] = mkdir(fullfile(handles_video.report.path,'raw_frames'));
			if mk_status~=1
				error('disp:report',['Ошибка создания каталога "' fullfile(handles_video.report.path,'raw_frames') '" протокола: ' mk_message]);
			end
		end
		save(fullfile(handles_video.report.path,'raw_frames',sprintf('%06d.mat',handles_video.toc_frames)),'frame_cur','-v6');
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
		frame_cur_rgb = fix(frame_cur*63)+1;
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
	set(handles_video.handles.state_timer, 'String', [toc2str(toc_t,':') sprintf('\n(%d)', handles_video.toc_frames)]);

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
				show_image(handles_video.handles.detector_lamp, fullfile('icons','light_green.png'));
			end

		%% Main work stage
		case 300
			state_emi_ud = get(handles.state_emi,'UserData');
			if ~isempty(state_emi_ud)
				emi_t = toc(state_emi_ud.tic_id);
				emi_str = [state_emi_ud.program_str ' ' toc2str(emi_t,':')];
				if all(state_emi_ud.sweep_f1f2>0)
					emi_str = [emi_str sprintf('; F~%.3f МГц',10.^( min(fix(emi_t/state_emi_ud.sweep_t*11411),11410)/11410 * diff(log10(state_emi_ud.sweep_f1f2)) + log10(state_emi_ud.sweep_f1f2(1))))];
				end
				if ~isempty(state_emi_ud.comment)
					emi_str = [emi_str ' (' state_emi_ud.comment ')'];
				end
				set(handles.state_emi, 'String', emi_str);
			end
			
			% High pass filtering
			if isfield(handles_video,'filter_hp')
				[frame_cur, handles_video.filter_hp.z] = filter(handles_video.filter_hp.b, handles_video.filter_hp.a, frame_cur, handles_video.filter_hp.z, 1);
			end

			% Statistics checkign
			is_signaling = (frame_cur<handles_video.stat.lo) | (frame_cur>handles_video.stat.hi);

			% Median filtering
			if handles_video.config.thresholds.median_size_ispercent
				median_size = round(handles_video.config.thresholds.median_size*min(frame_sz)/100);
			else
				median_size = handles_video.config.thresholds.median_size;
			end
			if median_size>1
				is_signaling = reshape(is_signaling, frame_sz);
				is_signaling = medfilt2(is_signaling, median_size+[0 0]);
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

				if isfield(handles_video,'report')
					handles_video_report_path = handles_video.report.path;
				else
					handles_video_report_path = nan;
				end
				handles_video.report = struct(	'fh',-1, 'prebuf_img',{{}}, 'prebuf_toc',zeros(0,2), 'prebuf_emi',{{}}, ...
												'normal_img_cnt',0, 'normal_img_toc',-inf, 'overall',{{}}, 'fh_emi',-1, ...
												'imagelist',struct('filename',{},'frame',{},'time',{},'emi_state',{}));

				if not(isempty(handles_video.config.thresholds.report_path))
					if isnan(handles_video_report_path)
						handles_video.report.path = fullfile(handles_video.config.thresholds.report_path, sprintf('%s_%d.%02d.%02d_%02d.%02d.%02d', mfilename, fix(clock)), filesep);
						[mk_status, mk_message] = mkdir(handles_video.report.path);
						if mk_status~=1
							error('disp:report',['Ошибка создания каталога "' handles_video.report.path '" протокола: ' mk_message]);
						end
					else
						handles_video.report.path = handles_video_report_path;
					end
					
					xml_write(fullfile(handles_video.report.path,'config.xml'), handles_video.config, 'ir_stand', struct('CellItem',false, 'StructItem',false));

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
					handles_video.report.overall(end+1,2:5) = {datestr(now) toc2str(toc_t,':') sprintf('%d',handles_video.toc_frames) get(handles.state_emi,'String')};

					show_image(handles_video.handles.detector_lamp, fullfile('icons','light_red.png'));

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

						% Save Generators state
						if handles_video.report.fh_emi~=-1
							fclose(handles_video.report.fh_emi);
						end
						handles_video.report.fh_emi = fopen(fullfile(handles_video.report.anomaly_path,'emi_state.txt'), 'wt');
						
						for ii = 1:handles_video.report.anomaly_img_cnt
							img_filename = sprintf('%simage_%06d_%s.png',handles_video.report.anomaly_path, handles_video.report.prebuf_toc(ii,1), toc2str(handles_video.report.prebuf_toc(ii,2),'.'));
							imwrite(handles_video.report.prebuf_img{ii}, img_filename, 'png');
							handles_video.report.imagelist(end+1,1) = struct('filename',img_filename, 'frame',handles_video.report.prebuf_toc(ii,1), 'time',handles_video.report.prebuf_toc(ii,2), 'emi_state',handles_video.report.prebuf_emi{ii});
							fprintf(handles_video.report.fh_emi, '%d\t%e\t%s\n', handles_video.report.prebuf_toc(ii,1), handles_video.report.prebuf_toc(ii,2), handles_video.report.prebuf_emi{ii});
						end
						handles_video.report.prebuf_img = {};
						handles_video.report.prebuf_toc = zeros(0,2);
						handles_video.report.prebuf_emi = {};
					end

				else % Detector just turn OFF
					handles_video.report.overall(end,6:9) = {datestr(now) toc2str(toc_t,':') sprintf('%d',handles_video.toc_frames) get(handles.state_emi,'String')};

					show_image(handles_video.handles.detector_lamp, fullfile('icons','light_green.png'));

					handles_video.report.normal_img_toc = toc_t;
				end

				handles_video.detector.state=new_st;
			end

			if	handles_video.detector.state && handles_video.report.fh~=-1 && handles_video.config.thresholds.report_deton_img_number>0
				if handles_video.report.anomaly_img_cnt < handles_video.config.thresholds.report_deton_img_number && ...
						toc_t-handles_video.report.anomaly_img_toc >= handles_video.config.thresholds.report_deton_img_interval
					img_filename = sprintf('%simage_%06d_%s.png',handles_video.report.anomaly_path, handles_video.toc_frames, toc2str(toc_t,'.'));
					imwrite([frame_cur_rgb frame_cur_bw], img_filename, 'png');
					handles_video.report.anomaly_img_cnt = handles_video.report.anomaly_img_cnt+1;
					handles_video.report.anomaly_img_toc = toc_t;
					emi_state = get(handles.state_emi,'String');
					handles_video.report.imagelist(end+1,1) = struct('filename',img_filename, 'frame',handles_video.toc_frames, 'time',toc_t, 'emi_state',emi_state);
					fprintf(handles_video.report.fh_emi, '%d\t%e\t%s\n', handles_video.toc_frames, toc_t, emi_state);
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
					handles_video.report.prebuf_emi{end+1} = get(handles.state_emi,'String');

					kill_mask = handles_video.report.prebuf_toc(:,2) < toc_t-handles_video.config.thresholds.detector_pre_buff;
					kill_mask(1 : end-max(0,handles_video.config.thresholds.report_deton_img_number-1)) = true;

					handles_video.report.prebuf_img(kill_mask) = [];
					handles_video.report.prebuf_toc(kill_mask,:) = [];
					handles_video.report.prebuf_emi(kill_mask) = [];
				end
			end

		%% Program logic error trap
		otherwise
			error('disp:report','ERROR: Unknown work stage.');
	end

	set(timer_handle, 'UserData',handles_video);

	drawnow();
catch ME
	if strcmp(ME.identifier,'disp:report')
		ME_cfg = true;
	else
		ME_cfg = handles_video.config;
	end
	disp_exception(handles, ME_cfg, ME, 'Ошибка обработчика видео');
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


% --- Executes on slider movement.
function volume_slider_Callback(hObject, eventdata, handles)
% hObject    handle to volume_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
cur_vol = get(hObject,'Value');
set(handles.volume_text, 'String',sprintf('Громкость акустического сигнала: %.0f%%',cur_vol*100));
dos_str = ['"' fullfile(fileparts(mfilename('fullpath')), 'sls', 'nircmd', 'nircmdc.exe') '" setsysvolume ' sprintf('%.0f',cur_vol*65535)];
sls_dir = [fileparts(mfilename('fullpath')) filesep 'sls' filesep];
dos_str = ['"' sls_dir 'hstart.exe" /NOCONSOLE "' dos_str '"'];
dos(dos_str);
handles.config.acoustic_generator.volume = cur_vol;
config_write(handles.config_file, handles.config);
guidata(hObject, handles);
obj_ud = get(hObject,'UserData');
if cur_vol<0.85 && isempty(obj_ud)
	pos = get(handles.figure1, 'Position');
	w = 80;
	h = 3.5;
	pos = [(pos(3)-w)/2 (pos(4)-h)/2 w h];
	hndl = uicontrol('Parent',handles.figure1, 'Style','text',  'Min',0,  'Max',3,  ...
			'String',sprintf('\nУровень громкости акустического сигнала < 70 дБ.'),  'Units','characters', ...
			'Position',pos, 'BackgroundColor',[1 0.25 0.25], 'FontSize',9);
	set(hObject,'UserData',hndl);
end
if cur_vol>=0.85 && ~isempty(obj_ud)
	delete(obj_ud);
	set(hObject,'UserData',[]);
end


function added_paths=addpath_recursive(root, varargin)
if nargin==0 || isempty(root)
	call_stack=dbstack('-completenames');
	if length(call_stack)>1
		root=fileparts(call_stack(2).file);
	else
		root=pwd();
	end
end

cfg=struct('ignore_dirs',{{}}, 'addpath_arg',{{}}, 'add_root',false);
if rem(length(varargin),2)
	error('addpath_recursive:arguments_parse', 'Incorrect number of input arguments.');
end
for i=1:length(varargin)/2
	cfg.(varargin{2*i-1})=varargin{2*i};
end

if isa(cfg.ignore_dirs,'char')
	cfg.ignore_dirs={cfg.ignore_dirs};
end
if not(isa(cfg.ignore_dirs,'cell'))
	error('addpath_recursive:arguments_parse', 'ignore_dirs argument must be string or cell of strings.');
end

if isa(cfg.addpath_arg,'char')
	cfg.addpath_arg={cfg.addpath_arg};
end
if not(isa(cfg.addpath_arg,'cell'))
	error('addpath_recursive:arguments_parse', 'addpath_arg argument must be string or cell.');
end

added_paths=addpath_recursive_call(root, cfg, {});


function added_paths=addpath_recursive_call(root, cfg, added_paths)
if cfg.add_root
	addpath(root, cfg.addpath_arg{:});
	added_paths{end+1}=root;
else
	cfg.add_root=true;
end

list=dir(root);
list(not([list.isdir]))=[];
list={list.name};
list(strcmp(list,'.'))=[];
list(strcmp(list,'..'))=[];

ignore_mask=false(size(list));
for i=1:length(cfg.ignore_dirs)
	[reg_beg, reg_end]=regexp(list, cfg.ignore_dirs{i});
	ignore_mask=ignore_mask | cellfun(@(l,b,e) not(isempty(b))&&b==1&&e==length(l), list, reg_beg, reg_end);
end
list(ignore_mask)=[];

for i=1:length(list)
	added_paths=addpath_recursive_call([root filesep list{i}], cfg, added_paths);
end


% function errordlg(varargin)
% msgbox_my(guidata(gcf), varargin{:});


% function msgbox(msg, title, varargin)
% msgbox_my(guidata(gcf), msg, title, varargin{:});


function msgbox_my(handles, msg, title, varargin)
msgbox(msg, title, varargin{:});
return

msglist = get(handles.logo_axes, 'UserData');
if isempty(msglist)
	pos = [2 1 100 3.2];
else
	pos = get(msglist(end),'Position');
	pos2 = pos(2) + pos(4) + 0.1;
	btn_pos = get(handles.work_start_btn, 'Position');
	if pos2+pos(4)<btn_pos(2) % Немного грубо, т.к. не учитывается позиция панели, но будет работать
		pos(2) = pos2;
	end
end
msg = sprintf('%d.%02d.%02d %02d.%02d.%02d: %s\n%s',fix(clock),title,msg);
hndl = uicontrol('Parent',handles.figure1,  'Style','text',  'Min',0,  'Max',3,  'String',msg,  'Units','characters',  'Position',pos, 'BackgroundColor',[1 0.5 0.5], ...
	'HorizontalAlignment','left',  'Enable','inactive',  'ButtonDownFcn',@msgbox_buttondown);
set(handles.logo_axes, 'UserData',[msglist hndl]);


function msgbox_buttondown(hObject, eventdata)
handles = guidata(hObject);
msglist = get(handles.logo_axes, 'UserData');
obj_ind = find(msglist==hObject);
msglist(obj_ind) = [];
set(handles.logo_axes, 'UserData',msglist);
obj_pos = get(hObject, 'Position');
delete(hObject);
if obj_ind<=numel(msglist)
	next_pos = get(msglist(obj_ind),'Position');
	dy = next_pos(2) - obj_pos(2);
	for ii = obj_ind:numel(msglist)
		cur_pos = get(msglist(ii), 'Position');
		cur_pos(2) = cur_pos(2) - dy;
		set(msglist(ii), 'Position',cur_pos);
	end
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
mouse_pos = get(hObject, 'CurrentPoint');
check_pos(handles, mouse_pos, handles.work_graph_pix_num);
check_pos(handles, mouse_pos, handles.work_graph_pix_part);


function check_pos(handles, mouse_pos, hObject)
ui_pos = get(hObject, 'Position');
par_pos = get(handles.work_uipanel,'Position');
ui_pos([1 2]) = ui_pos([1 2]) + par_pos([1 2]);
if  mouse_pos(1)>ui_pos(1) && mouse_pos(1)<ui_pos(1)+ui_pos(3) && ...
	mouse_pos(2)>ui_pos(2) && mouse_pos(2)<ui_pos(2)+ui_pos(4)
		ui_lim = get(hObject, 'XLim');
		x_pos = diff(ui_lim)*(mouse_pos(1)-ui_pos(1))/ui_pos(3)+ui_lim(1);
		work_graph_ButtonDownFcn(handles, x_pos);
end


function work_graph_ButtonDownFcn(handles, mouse_x)
if strcmp(get(handles.work_abort_btn,'Visible'),'on')
	return
end
rep_ud = get(handles.work_graph_pix_num, 'UserData');
if ~isfield_ex(rep_ud,'report.imagelist')
	return
end
imlist = rep_ud.report.imagelist;
if isempty(imlist)
	return
end
[~,mi]=min(abs(mouse_x-[imlist.time]));

caret_move_on_ind(handles, rep_ud, imlist(mi));


function caret_move_on_ind(handles, rep_ud, imlist_mi)
if isempty(imlist_mi)
	return
end
img = imread(imlist_mi.filename);
image(img(:,1:size(img,2)/2,:), 'Parent',handles.work_img_orig);
axis(handles.work_img_orig,'equal');
set(handles.work_img_orig, 'XTick',[], 'YTick',[]);
image(img(:,size(img,2)/2+1:end,:), 'Parent',handles.work_img_bw);
axis(handles.work_img_bw,'equal');
set(handles.work_img_bw, 'XTick',[], 'YTick',[]);

set(handles.state_emi, 'String',imlist_mi.emi_state);
set(handles.state_timer,'String', [toc2str(imlist_mi.time,':') sprintf('\n(%d)', imlist_mi.frame)]);

show_image(handles.detector_lamp, fullfile('icons','light_red.png'));

set(rep_ud.caret_pix_num,'XData',imlist_mi.time+[0 0]);
set(rep_ud.caret_pix_part,'XData',imlist_mi.time+[0 0]);


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key
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
	otherwise
		return
end
if any(strcmp(eventdata.Modifier,'shift'))
	shift_steps=shift_steps*5;
end
if any(strcmp(eventdata.Modifier,'control'))
	shift_steps=shift_steps*20;
end
if strcmp(get(handles.work_abort_btn,'Visible'),'on')
	return
end
rep_ud = get(handles.work_graph_pix_num, 'UserData');
if ~isfield_ex(rep_ud,'report.imagelist')
	return
end
imlist = rep_ud.report.imagelist;
if isempty(imlist)
	return
end
cur_pos = get(rep_ud.caret_pix_num,'XData');
[~,mi]=min(abs(cur_pos(1)-[imlist.time]));
mi = max(1,min(numel(imlist), mi + shift_steps));

caret_move_on_ind(handles, rep_ud, imlist(mi));


% --- Executes on button press in tool_zoomin_btn.
function tool_zoomin_btn_Callback(hObject, eventdata, handles)
% hObject    handle to tool_zoomin_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
	zoom('xon');
	set(zoom,'Direction','in');
	set(handles.tool_zoomout_btn,'Value',0);
	set(handles.tool_pan_btn,'Value',0);
else
	zoom('off');
end


% --- Executes on button press in tool_zoomout_btn.
function tool_zoomout_btn_Callback(hObject, eventdata, handles)
% hObject    handle to tool_zoomout_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
	zoom('xon');
	set(zoom,'Direction','out');
	set(handles.tool_zoomin_btn,'Value',0);
	set(handles.tool_pan_btn,'Value',0);
else
	zoom('off');
end


% --- Executes on button press in tool_pan_btn.
function tool_pan_btn_Callback(hObject, eventdata, handles)
% hObject    handle to tool_pan_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
	pan('xon');
	set(handles.tool_zoomin_btn,'Value',0);
	set(handles.tool_zoomout_btn,'Value',0);
else
	pan('off');
end
