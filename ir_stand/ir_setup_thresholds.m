function varargout = ir_setup_thresholds(varargin)
% IR_SETUP_THRESHOLDS MATLAB code for ir_setup_thresholds.fig
%      IR_SETUP_THRESHOLDS, by itself, creates a new IR_SETUP_THRESHOLDS or raises the existing
%      singleton*.
%
%      H = IR_SETUP_THRESHOLDS returns the handle to a new IR_SETUP_THRESHOLDS or the handle to
%      the existing singleton*.
%
%      IR_SETUP_THRESHOLDS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_SETUP_THRESHOLDS.M with the given input arguments.
%
%      IR_SETUP_THRESHOLDS('Property','Value',...) creates a new IR_SETUP_THRESHOLDS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_setup_thresholds_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_setup_thresholds_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_setup_thresholds

% Last Modified by GUIDE v2.5 08-May-2015 03:04:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_setup_thresholds_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_setup_thresholds_OutputFcn, ...
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


% --- Executes just before ir_setup_thresholds is made visible.
function ir_setup_thresholds_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_setup_thresholds (see VARARGIN)

% Choose default command line output for ir_setup_thresholds
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
handles.config = cfg;
handles.config_default = cfg_def;

handles = set_controls(handles, struct_merge(cfg,cfg_def));

set_icon(handles.ok_btn, 'yes.png', true);
set_icon(handles.cancel_btn, 'no.png', true);
set_icon(handles.reset_btn, 'undo.png', true);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_thresholds wait for user response (see UIRESUME)
uiwait(handles.figure1);


function [handles, cfg] = set_controls(handles, cfg)
set(handles.start_delay,				'String', num2str(cfg.thresholds.start_delay));
set(handles.filter_no_median,			'Value',  cfg.thresholds.filter_no_median);
set(handles.filter_hp_factor,			'String', num2str(cfg.thresholds.filter_hp_factor));
set(handles.filter_hp_initframes,		'String', num2str(cfg.thresholds.filter_hp_initframes));
set(handles.stat_lo,					'String', num2str(cfg.thresholds.stat_lo));
set(handles.stat_hi,					'String', num2str(cfg.thresholds.stat_hi));
set(handles.stat_time,					'String', num2str(cfg.thresholds.stat_time));
set(handles.stat_pixshift,				'String', num2str(cfg.thresholds.stat_pixshift));
set(handles.median_size,				'String', num2str(cfg.thresholds.median_size));
set(handles.median_size_ispercent,		'Value',  cfg.thresholds.median_size_ispercent);
set(handles.report_path,				'String', cfg.thresholds.report_path);
set(handles.report_detoff_img_interval,	'String', num2str(cfg.thresholds.report_detoff_img_interval));
set(handles.report_detoff_img_number,	'String', num2str(cfg.thresholds.report_detoff_img_number));
set(handles.report_deton_img_interval,	'String', num2str(cfg.thresholds.report_deton_img_interval));
set(handles.report_deton_img_number,	'String', num2str(cfg.thresholds.report_deton_img_number));
set(handles.report_graph_time,			'String', num2str(cfg.thresholds.report_graph_time));
set(handles.debug_messages,				'Value',  cfg.debug_messages);
set(handles.debug_saveframes,			'Value',  cfg.debug_saveframes);
handles.password_string = cfg.password;


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_thresholds_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config;
if handles.press_ok
	cfg.thresholds.start_delay =				str2double(get(handles.start_delay,'String'));
	cfg.thresholds.filter_no_median =			get(handles.filter_no_median, 'Value');
	cfg.thresholds.filter_hp_factor =			str2double(get(handles.filter_hp_factor,'String'));
	cfg.thresholds.filter_hp_initframes =		str2double(get(handles.filter_hp_initframes,'String'));
	cfg.thresholds.stat_lo =					str2double(get(handles.stat_lo,'String'));
	cfg.thresholds.stat_hi =					str2double(get(handles.stat_hi,'String'));
	cfg.thresholds.stat_time =					str2double(get(handles.stat_time,'String'));
	cfg.thresholds.stat_pixshift =				str2double(get(handles.stat_pixshift,'String'));
	cfg.thresholds.median_size =				str2double(get(handles.median_size,'String'));
	cfg.thresholds.median_size_ispercent =		get(handles.median_size_ispercent,'Value');
	cfg.thresholds.report_path =				get(handles.report_path,'String');
	cfg.thresholds.report_detoff_img_interval=	str2double(get(handles.report_detoff_img_interval,'String'));
	cfg.thresholds.report_detoff_img_number=	str2double(get(handles.report_detoff_img_number,'String'));
	cfg.thresholds.report_deton_img_interval=	str2double(get(handles.report_deton_img_interval,'String'));
	cfg.thresholds.report_deton_img_number=		str2double(get(handles.report_deton_img_number,'String'));
	cfg.thresholds.report_graph_time =			str2double(get(handles.report_graph_time,'String'));
	cfg.debug_messages =						get(handles.debug_messages,'Value');
	cfg.debug_saveframes =						get(handles.debug_saveframes,'Value');
	cfg.password =								handles.password_string;
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


% --- Executes on button press in report_path_sel.
function report_path_sel_Callback(hObject, eventdata, handles)
% hObject    handle to report_path_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
root = get(handles.report_path, 'String');
root = uigetdir(root ,'Выберите каталог для сохранения протокола');
if not(root)
	return;
end
set(handles.report_path, 'String', root);


% --- Executes on button press in filter_hp_freqz_btn.
function filter_hp_freqz_btn_Callback(hObject, eventdata, handles)
% hObject    handle to filter_hp_freqz_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filter_hp_factor = str2double(get(handles.filter_hp_factor,'String'));
fvtool([1 -1],[1 filter_hp_factor]);


% --- Executes on button press in password_btn.
function password_btn_Callback(hObject, eventdata, handles)
% hObject    handle to password_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pass = passwordEntryDialog('CheckPasswordLength',false, 'ValidatePassword',true, 'WindowName','Введите пароль');
if pass == -1
	return
end
handles.password_string = pass;
guidata(hObject, handles);


% --- Executes on button press in reset_btn.
function reset_btn_Callback(hObject, eventdata, handles)
% hObject    handle to reset_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = set_controls(handles, struct_merge(handles.config_default));
guidata(hObject, handles);
