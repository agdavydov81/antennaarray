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

% Last Modified by GUIDE v2.5 29-Sep-2013 01:55:40

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
if not(isfield(cfg,'video'));							cfg.video = struct();						end
if not(isfield(cfg.video,'detector'));					cfg.video.detector = struct();				end
if not(isfield(cfg.video.detector,'quantiles'));		cfg.video.detector.quantiles = [0.05 0.95];	end
if not(isfield(cfg.video.detector,'estimation_time'));	cfg.video.detector.estimation_time = 5;		end
if not(isfield(cfg.video,'device'));					cfg.video.device = struct();				end
if not(isfield(cfg.video.device,'name'));				cfg.video.device.name = '';					end
if not(isfield(cfg.video.device,'mode'));				cfg.video.device.mode = '';					end
if not(isfield(cfg.video.device,'axis'));				cfg.video.device.axis = [];					end

handles.config = cfg;

set(handles.detector_quantiles,			'String',sprintf('%0.2f ',cfg.video.detector.quantiles));
set(handles.detector_estimation_time,	'String',num2str(cfg.video.detector.estimation_time));

handles.video.devices = imaqhwinfo('winvideo');
set(handles.video_camera, 'String',{handles.video.devices.DeviceInfo.DeviceName});
handles.video.cur_device = 1;
if not(isempty(cfg.video.device.name))
	cur_cam = find(strcmp(cfg.video.device.name, {handles.video.devices.DeviceInfo.DeviceName}),1);
	if isempty(cur_cam)
		cfg.video.device.mode = '';
		cfg.video.device.axis = [];
	else
		handles.video.cur_device = cur_cam;
	end
end
set(handles.video_camera, 'Value',handles.video.cur_device);

video_modes = handles.video.devices.DeviceInfo(handles.video.cur_device).SupportedFormats;
set(handles.video_mode, 'String',video_modes);
handles.video.mode =		handles.video.devices.DeviceInfo(handles.video.cur_device).DefaultFormat;
if not(isempty(cfg.video.device.mode))
	cur_mode = find(strcmp(cfg.video.device.mode, video_modes),1);
	if isempty(cur_mode)
		cfg.video.device.axis = [];
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
imshow(frame_cur, 'Parent',handles.video_image);
if isempty(cfg.video.device.axis)
	handles.video.axis = axis(handles.video_image);
else
	handles.video.axis = cfg.video.device.axis;
end
%	axis(handles.video_image, handles.video.axis);

handles.video.timer = timer('StartDelay',2, 'TimerFcn',@ir_setup_video_timer_func, ...
							'Period',1/50, 'ExecutionMode','fixedRate', 'UserData',handles.figure1);

% Update handles structure
guidata(hObject, handles);

set(zoom,'ActionPostCallback',@ir_setup_video_zoom_pan_image);
set(pan ,'ActionPostCallback',@ir_setup_video_zoom_pan_image);

start(handles.video.timer);

% UIWAIT makes ir_setup_video wait for user response (see UIRESUME)
uiwait(handles.figure1);


function ir_setup_video_timer_func(timer_handle, eventdata)
fig_handle = get(timer_handle, 'UserData');
handles = guidata(fig_handle);

try
	frame_cur = getsnapshot(handles.video.vidobj);
	imshow(frame_cur, 'Parent',handles.video_image);
	axis(handles.video_image, handles.video.axis);
	disp(axis(handles.video_image)); % @@ debug
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

set(handles.figure1, 'Units','pixels', 'Position',[(scr_sz(3)-(X+40))/2 (scr_sz(4)-(Y+210))/2 X+40 Y+195]);

set(handles.video_uipanel,		'Units','pixels',	'Position',[6 7 X+30 Y+100]);
set(handles.video_image,		'Units','pixels',	'Position',[15  16 X Y]);
set(handles.video_camera,		'Units','pixels',	'Position',[15  Y+54 200 22]);
set(handles.video_camera_text,	'Units','pixels',	'Position',[220 Y+57 90 16]);
set(handles.video_mode,			'Units','pixels',	'Position',[15  Y+24 200 22]);
set(handles.video_mode_text,	'Units','pixels',	'Position',[220 Y+27 90 16]);

set(handles.detector_uipanel,	'Units','pixels',	'Position',[6 Y+110 X+30 84]);
set(handles.setup_ok,			'Units','pixels',	'Position',[X-55 38 69 23]);
set(handles.setup_cancel,		'Units','pixels',	'Position',[X-55 10 69 23]);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_video_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

stop(handles.video.vidobj);
delete(handles.video.vidobj);
delete(handles.video.timer);

cfg = handles.config;
if handles.press_ok
	cfg.video.detector.quantiles =			str2num(get(handles.detector_quantiles,'String'));
	cfg.video.detector.estimation_time =	str2double(get(handles.detector_estimation_time,'String'));
	cfg.video.device.name =					handles.video.cam_info.DeviceName;
	cfg.video.device.mode =					handles.video.mode;
	cfg.video.device.axis =					handles.video.axis;
end

varargout{1} = cfg;

% The figure can be deleted now
delete(handles.figure1);


function ir_setup_video_zoom_pan_image(hObject, eventdata)
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
handles.video.vidobj = videoinput('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device}, ...
											 handles.video.devices.DeviceInfo(handles.video.cur_device).DefaultFormat);
set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
start(handles.video.vidobj);
frame_cur = getsnapshot(handles.video.vidobj);
resize_for_image(handles, size(frame_cur));
imshow(frame_cur, 'Parent',handles.video_image);
handles.video.axis = axis(handles.video_image);

guidata(hObject, handles);

start(handles.video.timer);


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

handles.video.cam_info=	imaqhwinfo('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device});
handles.video.mode =	cur_mode;
handles.video.vidobj =	videoinput('winvideo',handles.video.devices.DeviceIDs{handles.video.cur_device}, handles.video.mode);
set(handles.video.vidobj, 'ReturnedColorSpace','rgb');
triggerconfig(handles.video.vidobj, 'manual');
start(handles.video.vidobj);
frame_cur = getsnapshot(handles.video.vidobj);
resize_for_image(handles, size(frame_cur));
imshow(frame_cur, 'Parent',handles.video_image);
handles.video.axis = axis(handles.video_image);

guidata(hObject, handles);

start(handles.video.timer);


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