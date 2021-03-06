function varargout = ir_setup_thresholds_simple(varargin)
% IR_SETUP_THRESHOLDS_SIMPLE MATLAB code for ir_setup_thresholds_simple.fig
%      IR_SETUP_THRESHOLDS_SIMPLE, by itself, creates a new IR_SETUP_THRESHOLDS_SIMPLE or raises the existing
%      singleton*.
%
%      H = IR_SETUP_THRESHOLDS_SIMPLE returns the handle to a new IR_SETUP_THRESHOLDS_SIMPLE or the handle to
%      the existing singleton*.
%
%      IR_SETUP_THRESHOLDS_SIMPLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_SETUP_THRESHOLDS_SIMPLE.M with the given input arguments.
%
%      IR_SETUP_THRESHOLDS_SIMPLE('Property','Value',...) creates a new IR_SETUP_THRESHOLDS_SIMPLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_setup_thresholds_simple_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_setup_thresholds_simple_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_setup_thresholds_simple

% Last Modified by GUIDE v2.5 08-May-2015 02:24:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_setup_thresholds_simple_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_setup_thresholds_simple_OutputFcn, ...
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


% --- Executes just before ir_setup_thresholds_simple is made visible.
function ir_setup_thresholds_simple_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_setup_thresholds_simple (see VARARGIN)

% Choose default command line output for ir_setup_thresholds_simple
handles.output = hObject;

% Position to center of screen
old_units = get(hObject,'Units');
scr_sz = get(0,'ScreenSize');
set(hObject,'Units',get(0,'Units'));
cur_pos = get(hObject,'Position');
set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
set(hObject,'Units',old_units);

% Fill configuration fields
if isempty(varargin)
	cfg = struct();
	cfg_def = struct();
else
	cfg = varargin{1};
	cfg_def = varargin{2};
end
handles.config0 = struct('debug_messages',0, 'debug_msgbox',0, 'debug_saveframes',0, 'password','');
handles.config0.thresholds = struct('detector_on_points',100, 'detector_on_part',0.01, 'detector_off_points',80, ...
									'detector_off_part',0.008, 'detector_pre_buff',0.5, 'detector_post_buff',0.8, ...
									'start_delay',3, 'filter_no_median',1, 'filter_hp_factor',-0.97, 'filter_hp_initframes',200, ...
									'stat_lo',0.005, 'stat_hi',0.995, 'stat_time',15, 'stat_pixshift',1, ...
									'median_size',3, 'median_size_ispercent',0, 'report_path','.', ...
									'report_detoff_img_interval',60, 'report_detoff_img_number',1440, ...
									'report_deton_img_interval',1, 'report_deton_img_number',30, 'report_graph_time',3600);
if ispc
	handles.config0.thresholds.report_path = getenv('USERPROFILE');
else % if isunix
	handles.config0.thresholds.report_path = getenv('HOME');
end
handles.config_orig = cfg;
handles.config_default = cfg_def;
handles.config = struct_merge(cfg,cfg_def,handles.config0);
set_controls(handles, handles.config);

set_icon(handles.ok_btn, 'yes.png', true);
set_icon(handles.cancel_btn, 'no.png', true);
set_icon(handles.reset_btn, 'undo.png', true);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_thresholds_simple wait for user response (see UIRESUME)
uiwait(handles.figure1);


function set_controls(handles, cfg)
set(handles.detector_on_points,			'String', num2str(cfg.thresholds.detector_on_points));
set(handles.detector_on_part,			'String', num2str(cfg.thresholds.detector_on_part));
set(handles.detector_off_points,		'String', num2str(cfg.thresholds.detector_off_points));
set(handles.detector_off_part,			'String', num2str(cfg.thresholds.detector_off_part));
set(handles.detector_pre_buff,			'String', num2str(cfg.thresholds.detector_pre_buff));
set(handles.detector_post_buff,			'String', num2str(cfg.thresholds.detector_post_buff));


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_thresholds_simple_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config_orig;
if handles.press_ok
	cfg.thresholds = handles.config.thresholds;
	cfg.debug_messages = handles.config.debug_messages;
	cfg.debug_msgbox = handles.config.debug_msgbox;
	cfg.debug_saveframes = handles.config.debug_saveframes;
	cfg.password = handles.config.password;

	cfg.thresholds.detector_on_points =		str2double(get(handles.detector_on_points,'String'));
	cfg.thresholds.detector_on_part =		str2double(get(handles.detector_on_part,'String'));
	cfg.thresholds.detector_off_points =	str2double(get(handles.detector_off_points,'String'));
	cfg.thresholds.detector_off_part =		str2double(get(handles.detector_off_part,'String'));
	cfg.thresholds.detector_pre_buff =		str2double(get(handles.detector_pre_buff,'String'));
	cfg.thresholds.detector_post_buff =		str2double(get(handles.detector_post_buff,'String'));
end

varargout{1} = cfg;

% The figure can be deleted now
delete(handles.figure1);


% --- Executes on button press in ok_btn.
function ok_btn_Callback(hObject, eventdata, handles)
% hObject    handle to ok_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.press_ok = true;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes on button press in cancel_btn.
function cancel_btn_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.press_ok = false;
guidata(hObject, handles);
uiresume(handles.figure1);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
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
	handles.press_ok = is_key_esc_ret(2);
	guidata(hObject, handles);
	uiresume(handles.figure1);
end


% --- Executes on button press in advanced_btn.
function advanced_btn_Callback(hObject, eventdata, handles)
% hObject    handle to advanced_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_thresholds(handles.config, struct_merge(handles.config_default,handles.config0));
guidata(hObject, handles);


% --- Executes on button press in reset_btn.
function reset_btn_Callback(hObject, eventdata, handles)
% hObject    handle to reset_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set_controls(handles, struct_merge(handles.config_default,handles.config0));
