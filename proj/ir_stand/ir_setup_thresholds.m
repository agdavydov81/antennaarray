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

% Last Modified by GUIDE v2.5 07-Oct-2013 19:34:54

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
else
	cfg = varargin{1};
end
handles.config = cfg;

if not(isfield(cfg,'thresholds'));						cfg.thresholds = struct();					end
if not(isfield(cfg.thresholds,'start_delay'));			cfg.thresholds.start_delay = 10;			end
if not(isfield(cfg.thresholds,'start_time'));			cfg.thresholds.start_time = 5;				end
if not(isfield(cfg.thresholds,'stat_lo'));				cfg.thresholds.stat_lo = 0.005;				end
if not(isfield(cfg.thresholds,'stat_hi'));				cfg.thresholds.stat_hi = 0.995;				end
if not(isfield(cfg.thresholds,'median_size'));			cfg.thresholds.median_size = 3;				end
if not(isfield(cfg.thresholds,'detector_points'));		cfg.thresholds.detector_points = 10;		end
if not(isfield(cfg.thresholds,'detector_part'));		cfg.thresholds.detector_part = 0.01;		end
if not(isfield(cfg.thresholds,'report_path'));			cfg.thresholds.report_path = '';			end
if not(isfield(cfg.thresholds,'report_img_interval'));	cfg.thresholds.report_img_interval = 60;	end
if not(isfield(cfg.thresholds,'report_graph_time'));	cfg.thresholds.report_graph_time = 600;		end

set(handles.start_delay,		'String', num2str(cfg.thresholds.start_delay));
set(handles.start_time,			'String', num2str(cfg.thresholds.start_time));
set(handles.stat_lo,			'String', num2str(cfg.thresholds.stat_lo));
set(handles.stat_hi,			'String', num2str(cfg.thresholds.stat_hi));
set(handles.median_size,		'String', num2str(cfg.thresholds.median_size));
set(handles.detector_points,	'String', num2str(cfg.thresholds.detector_points));
set(handles.detector_part,		'String', num2str(cfg.thresholds.detector_part));
set(handles.report_path,		'String', cfg.thresholds.report_path);
set(handles.report_img_interval,'String', num2str(cfg.thresholds.report_img_interval));
set(handles.report_graph_time,	'String', num2str(cfg.thresholds.report_graph_time));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_thresholds wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_thresholds_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config;
if handles.press_ok
	cfg.thresholds.start_delay = 		str2double(get(handles.start_delay,'String'));
	cfg.thresholds.start_time = 		str2double(get(handles.start_time,'String'));
	cfg.thresholds.stat_lo =			str2double(get(handles.stat_lo,'String'));
	cfg.thresholds.stat_hi =			str2double(get(handles.stat_hi,'String'));
	cfg.thresholds.median_size =		str2double(get(handles.median_size,	'String'));
	cfg.thresholds.detector_points =	str2double(get(handles.detector_points,'String'));
	cfg.thresholds.detector_part =		str2double(get(handles.detector_part,'String'));
	cfg.thresholds.report_path =		get(handles.report_path, 'String');
	cfg.thresholds.report_img_interval=	str2double(get(handles.report_img_interval,'String'));
	cfg.thresholds.report_graph_time =	str2double(get(handles.report_graph_time,'String'));
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


function stat_lo_Callback(hObject, eventdata, handles)
% hObject    handle to stat_lo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stat_lo as text
%        str2double(get(hObject,'String')) returns contents of stat_lo as a double


% --- Executes during object creation, after setting all properties.
function stat_lo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stat_lo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function stat_hi_Callback(hObject, eventdata, handles)
% hObject    handle to stat_hi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stat_hi as text
%        str2double(get(hObject,'String')) returns contents of stat_hi as a double


% --- Executes during object creation, after setting all properties.
function stat_hi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stat_hi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function start_time_Callback(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_time as text
%        str2double(get(hObject,'String')) returns contents of start_time as a double


% --- Executes during object creation, after setting all properties.
function start_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function detector_points_Callback(hObject, eventdata, handles)
% hObject    handle to detector_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of detector_points as text
%        str2double(get(hObject,'String')) returns contents of detector_points as a double


% --- Executes during object creation, after setting all properties.
function detector_points_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detector_points (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function detector_part_Callback(hObject, eventdata, handles)
% hObject    handle to detector_part (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of detector_part as text
%        str2double(get(hObject,'String')) returns contents of detector_part as a double


% --- Executes during object creation, after setting all properties.
function detector_part_CreateFcn(hObject, eventdata, handles)
% hObject    handle to detector_part (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function median_size_Callback(hObject, eventdata, handles)
% hObject    handle to median_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of median_size as text
%        str2double(get(hObject,'String')) returns contents of median_size as a double


% --- Executes during object creation, after setting all properties.
function median_size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to median_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function start_delay_Callback(hObject, eventdata, handles)
% hObject    handle to start_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_delay as text
%        str2double(get(hObject,'String')) returns contents of start_delay as a double


% --- Executes during object creation, after setting all properties.
function start_delay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_delay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function report_path_Callback(hObject, eventdata, handles)
% hObject    handle to report_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of report_path as text
%        str2double(get(hObject,'String')) returns contents of report_path as a double


% --- Executes during object creation, after setting all properties.
function report_path_CreateFcn(hObject, eventdata, handles)
% hObject    handle to report_path (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in report_path_sel.
function report_path_sel_Callback(hObject, eventdata, handles)
% hObject    handle to report_path_sel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
root = get(handles.report_path, 'String');
root = uigetdir(root ,'¬ыберите каталог дл€ сохранени€ протокола');
if not(root)
	return;
end
set(handles.report_path, 'String', root);


function report_img_interval_Callback(hObject, eventdata, handles)
% hObject    handle to report_img_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of report_img_interval as text
%        str2double(get(hObject,'String')) returns contents of report_img_interval as a double


% --- Executes during object creation, after setting all properties.
function report_img_interval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to report_img_interval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function report_graph_time_Callback(hObject, eventdata, handles)
% hObject    handle to report_graph_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of report_graph_time as text
%        str2double(get(hObject,'String')) returns contents of report_graph_time as a double


% --- Executes during object creation, after setting all properties.
function report_graph_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to report_graph_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
