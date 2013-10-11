function varargout = ir_setup_video(varargin)
% IR_SETUP_VIDEO MATLAB code for ir_setup_video.fig
%      IR_SETUP_VIDEO, by itself, creates a new IR_SETUP_VIDEO or raises the existing
%      singleton*.
%
%      H = IR_SETUP_VIDEO returns the handle to a new IR_SETUP_VIDEO or the handle to
%      the existing singleton*.
%
%      IR_SETUP_VIDEO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_SETUP_VIDEO.M with the given input arguments.
%
%      IR_SETUP_VIDEO('Property','Value',...) creates a new IR_SETUP_VIDEO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_setup_video_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_setup_video_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_setup_video

% Last Modified by GUIDE v2.5 09-Oct-2013 23:14:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_setup_video_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_setup_video_OutputFcn, ...
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


% --- Executes just before ir_setup_video is made visible.
function ir_setup_video_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_setup_video (see VARARGIN)

% Choose default command line output for ir_setup_video
handles.output = hObject;

if isempty(varargin)
	cfg = struct();
else
	cfg = varargin{1};
end
handles.config = cfg;

if not(isfield(cfg,'video_device'));					cfg.video_device = struct();				end
if not(isfield(cfg.video_device,'name'));				cfg.video_device.name = '';					end
if not(isfield(cfg.video_device,'mode'));				cfg.video_device.mode = '';					end
if not(isfield(cfg.video_device,'axis'));				cfg.video_device.axis = [];					end

handles.video.devices = imaqhwinfo('winvideo');
if isempty(handles.video.devices.DeviceInfo)
	return
end
set(handles.video_camera, 'String',{handles.video.devices.DeviceInfo.DeviceName});
handles.video.cur_device = 1;
if not(isempty(cfg.video_device.name))
	cur_cam = find(strcmp(cfg.video_device.name, {handles.video.devices.DeviceInfo.DeviceName}),1);
	if isempty(cur_cam)
		cfg.video_device.mode = '';
		cfg.video_device.axis = [];
	else
		handles.video.cur_device = cur_cam;
	end
end
set(handles.video_camera, 'Value',handles.video.cur_device);

video_modes = handles.video.devices.DeviceInfo(handles.video.cur_device).SupportedFormats;
set(handles.video_mode, 'String',video_modes);
handles.video.mode =		handles.video.devices.DeviceInfo(handles.video.cur_device).DefaultFormat;
if not(isempty(cfg.video_device.mode))
	cur_mode = find(strcmp(cfg.video_device.mode, video_modes),1);
	if isempty(cur_mode)
		cfg.video_device.axis = [];
	else
		handles.video.mode = video_modes{cur_mode};
	end
end
set(handles.video_mode, 'Value',find(strcmp(handles.video.mode,video_modes),1));

handles.video.cam_info =	imaqhwinfo('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device});
handles.video.vidobj =		videoinput('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device}, handles.video.mode);
set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
start(handles.video.vidobj);
frame_cur = getsnapshot(handles.video.vidobj);
resize_for_image(handles, size(frame_cur));
image(frame_cur, 'Parent',handles.video_image);
set(handles.video_image, 'XTick',[], 'YTick',[]);
handles.video.axis_def = axis(handles.video_image);
handles.video.axis = handles.video.axis_def;
if not(isempty(cfg.video_device.axis))
	handles.video.axis = cfg.video_device.axis;
end
axis(handles.video_image, handles.video.axis);

set(handles.figure1,'UserData',struct()); % the handles.video.fps new storage
handles.video.timer = timer('TimerFcn',@ir_setup_video_timer_func, 'Period',1/100, ...
							'StartDelay',2, 'ExecutionMode','fixedRate', 'UserData',handles.figure1);
set(handles.video_fps, 'String','');

guidata(hObject, handles);

set(zoom, 'ActionPostCallback',@ir_setup_video_post_zoom_pan);
set(pan , 'ActionPostCallback',@ir_setup_video_post_zoom_pan);

start(handles.video.timer);

% UIWAIT makes ir_setup_video wait for user response (see UIRESUME)
uiwait(handles.figure1);


function ir_setup_video_timer_func(timer_handle, eventdata)
fig_handle = get(timer_handle, 'UserData');
handles = guidata(fig_handle);

try
	handles_video_fps = get(handles.figure1,'UserData');

	if isfield(handles_video_fps,'ticID')
		frame_cur = getsnapshot(handles.video.vidobj);
		image(frame_cur, 'Parent',handles.video_image);
		set(handles.video_image, 'XTick',[], 'YTick',[]);
		axis(handles.video_image, handles.video.axis);

		toc_t = toc(handles_video_fps.ticID);
		if toc_t>handles_video_fps.tic_pos
			handles_video_fps.counter = handles_video_fps.counter+1;
			if toc_t>handles_video_fps.tok_pos
				handles_video_fps.frames_queue(end+1) = handles_video_fps.counter;
				handles_video_fps.tic_queue(end+1) = handles_video_fps.tic_pos;

				handles_video_fps.counter = 0;
				handles_video_fps.tic_pos = toc_t;

				handles_video_fps.tok_pos = fix(toc_t)+1;

				if length(handles_video_fps.tic_queue)>handles_video_fps.queue_length
					handles_video_fps.tic_queue(1:end-handles_video_fps.queue_length) = [];
					handles_video_fps.frames_queue(1:end-handles_video_fps.queue_length) = [];
				end
				ax = fix(handles.video.axis);
				set(handles.video_fps,'String',sprintf('%d x %d @ %.1f', ax(2)-ax(1), ax(4)-ax(3), sum(handles_video_fps.frames_queue)/(toc_t-handles_video_fps.tic_queue(1))));
			end
		end
	else
		handles_video_fps = struct('ticID',tic(), 'tic_pos',2, 'tok_pos',3, 'counter',0, 'queue_length',5, 'tic_queue',[], 'frames_queue',[]);
		set(handles.video_fps,'String','');
	end
	set(handles.figure1,'UserData',handles_video_fps);

	drawnow();
catch ME
%	disp(ME);
end


function resize_for_image(handles, img_sz)
Y = img_sz(1);
X = img_sz(2);
scr_sz = get(0,'ScreenSize');

if 0.8*scr_sz(3)<X || 0.8*scr_sz(4)<Y
	max_div = max([X/scr_sz(3)  Y/scr_sz(4)])/0.8;
	X = round(X/max_div);
	Y = round(Y/max_div);
end
if X<480
	mul_k = 480/X;
	X = round(X*mul_k);
	Y = round(Y*mul_k);
end

set(handles.figure1, 'Units','pixels', 'Position',[(scr_sz(3)-(X+20))/2 (scr_sz(4)-(Y+90))/2 X+20 Y+82]);

set(handles.video_image,		'Units','pixels',	'Position',[10  10 X Y]); %
set(handles.video_camera,		'Units','pixels',	'Position',[10  Y+50 200 22]);
set(handles.video_camera_text,	'Units','pixels',	'Position',[215 Y+53 60 16]);
set(handles.video_mode,			'Units','pixels',	'Position',[10  Y+20 200 22]);
set(handles.video_mode_text,	'Units','pixels',	'Position',[215 Y+23 60 16]);

set(handles.zoom_reset,			'Units','pixels',	'Position',[10+X-22 Y+20 22 22]);
set(handles.zoomin,				'Units','pixels',	'Position',[10+X-52 Y+20 22 22]);
set(handles.video_fps,			'Units','pixels',	'Position',[10+X-210 Y+23 150 16]);

set(handles.setup_ok,			'Units','pixels',	'Position',[10+X-70-8-70 Y+50 70 22]);
set(handles.setup_cancel,		'Units','pixels',	'Position',[10+X-70      Y+50 70 22]);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_video_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
varargout{1} = [];

if isfield(handles,'output')
	stop(handles.video.vidobj);
	delete(handles.video.vidobj);
	delete(handles.video.timer);

	cfg = handles.config;
	if handles.press_ok
		cfg.video_device.name =	handles.video.cam_info.DeviceName;
		cfg.video_device.mode =	handles.video.mode;
		cfg.video_device.axis =	axis(handles.video_image);
	end

	varargout{1} = cfg;
end

% The figure can be deleted now
delete(handles.figure1);


function ir_setup_video_post_zoom_pan(hObject, eventdata)
handles = guidata(hObject);
handles.video.axis = axis(handles.video_image);
guidata(hObject, handles);


% --- Executes on selection change in video_camera.
function video_camera_Callback(hObject, eventdata, handles)
% hObject    handle to video_camera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns video_camera contents as cell array
%        contents{get(hObject,'Value')} returns selected item from video_camera
if handles.video.cur_device==get(hObject,'Value')
	return
end

stop(handles.video.timer);

stop(handles.video.vidobj);
delete(handles.video.vidobj);

handles.video.cur_device=get(hObject,'Value');
handles.video.cam_info=imaqhwinfo('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device});

video_modes = handles.video.devices.DeviceInfo(handles.video.cur_device).SupportedFormats;
set(handles.video_mode, 'String',video_modes);
handles.video.mode = handles.video.devices.DeviceInfo(handles.video.cur_device).DefaultFormat;
set(handles.video_mode, 'Value',find(strcmp(handles.video.mode,video_modes),1));

handles.video.vidobj = videoinput('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device}, handles.video.mode);

set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
start(handles.video.vidobj);
frame_cur = getsnapshot(handles.video.vidobj);
resize_for_image(handles, size(frame_cur));
image(frame_cur, 'Parent',handles.video_image);
set(handles.video_image, 'XTick',[], 'YTick',[]);
handles.video.axis_def = axis(handles.video_image);
handles.video.axis = handles.video.axis_def;
guidata(hObject, handles);

set(handles.figure1,'UserData',struct());
if ~get(handles.zoomin,'Value')
	start(handles.video.timer);
end


% --- Executes during object creation, after setting all properties.
function video_camera_CreateFcn(hObject, eventdata, handles)
% hObject    handle to video_camera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in video_mode.
function video_mode_Callback(hObject, eventdata, handles)
% hObject    handle to video_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns video_mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from video_mode
cur_mode = get(hObject,'String');
cur_mode = cur_mode{get(hObject,'Value')};
if strcmp(handles.video.mode, cur_mode)
	return
end

stop(handles.video.timer);

stop(handles.video.vidobj);
delete(handles.video.vidobj);

handles.video.mode = cur_mode;
handles.video.vidobj =		videoinput('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device}, handles.video.mode);

set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
start(handles.video.vidobj);
frame_cur = getsnapshot(handles.video.vidobj);
resize_for_image(handles, size(frame_cur));
image(frame_cur, 'Parent',handles.video_image);
set(handles.video_image, 'XTick',[], 'YTick',[]);
handles.video.axis_def = axis(handles.video_image);
handles.video.axis = handles.video.axis_def;
guidata(hObject, handles);

set(handles.figure1,'UserData',struct());
if ~get(handles.zoomin,'Value')
	start(handles.video.timer);
end


% --- Executes during object creation, after setting all properties.
function video_mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to video_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function detector_quantiles_Callback(hObject, eventdata, handles)
% hObject    handle to detector_quantiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of detector_quantiles as text
%        str2double(get(hObject,'String')) returns contents of detector_quantiles as a double


% --- Executes during object creation, after setting all properties.
function detector_quantiles_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detector_quantiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function detector_estimation_time_Callback(hObject, eventdata, handles)
% hObject    handle to detector_estimation_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of detector_estimation_time as text
%        str2double(get(hObject,'String')) returns contents of detector_estimation_time as a double


% --- Executes during object creation, after setting all properties.
function detector_estimation_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detector_estimation_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setup_ok.
function setup_ok_Callback(hObject, eventdata, handles)
% hObject    handle to setup_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.video.timer);
handles.press_ok = true;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in setup_cancel.
function setup_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to setup_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.video.timer);
handles.press_ok = false;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
	stop(handles.video.timer);
	handles.press_ok = false;
	guidata(hObject, handles);
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% Check for "enter" or "escape"
is_key_esc_ret = strcmp(get(hObject,'CurrentKey'),{'escape' 'return'});
if any(is_key_esc_ret)
	stop(handles.video.timer);
	handles.press_ok = is_key_esc_ret(2);
	guidata(hObject, handles);
	uiresume(handles.figure1);
end


% --- Executes on button press in zoomin.
function zoomin_Callback(hObject, eventdata, handles)
% hObject    handle to zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.zoomin,'Value')
	stop(handles.video.timer);
	set(zoom, 'Direction','in', 'Enable','on');
else
	set(zoom, 'Enable','off');
	set(handles.figure1,'UserData',struct());
	start(handles.video.timer);
end


% --- Executes on button press in zoom_reset.
function zoom_reset_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.video.axis = handles.video.axis_def;
guidata(hObject, handles);
axis(handles.video_image, handles.video.axis_def);
