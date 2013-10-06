function varargout = ir_setup_acoustic(varargin)
% IR_SETUP_ACOUSTIC MATLAB code for ir_setup_acoustic.fig
%      IR_SETUP_ACOUSTIC, by itself, creates a new IR_SETUP_ACOUSTIC or raises the existing
%      singleton*.
%
%      H = IR_SETUP_ACOUSTIC returns the handle to a new IR_SETUP_ACOUSTIC or the handle to
%      the existing singleton*.
%
%      IR_SETUP_ACOUSTIC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_SETUP_ACOUSTIC.M with the given input arguments.
%
%      IR_SETUP_ACOUSTIC('Property','Value',...) creates a new IR_SETUP_ACOUSTIC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_setup_acoustic_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_setup_acoustic_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_setup_acoustic

% Last Modified by GUIDE v2.5 27-Sep-2013 17:47:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_setup_acoustic_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_setup_acoustic_OutputFcn, ...
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


% --- Executes just before ir_setup_acoustic is made visible.
function ir_setup_acoustic_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_setup_acoustic (see VARARGIN)

% Choose default command line output for ir_setup_acoustic
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

if not(isfield(cfg,'acoustic_generator'));					cfg.acoustic_generator = struct();				end
if not(isfield(cfg.acoustic_generator,'sls'));				cfg.acoustic_generator.sls = struct();			end
if not(isfield(cfg.acoustic_generator.sls,'enable'));		cfg.acoustic_generator.sls.enable = 1;			end
if not(isfield(cfg.acoustic_generator,'harm'));				cfg.acoustic_generator.harm = struct();			end
if not(isfield(cfg.acoustic_generator.harm,'enable'));		cfg.acoustic_generator.harm.enable = 0;			end
if not(isfield(cfg.acoustic_generator.harm,'freq_start'));	cfg.acoustic_generator.harm.freq_start = 100;	end
if not(isfield(cfg.acoustic_generator.harm,'freq_finish'));	cfg.acoustic_generator.harm.freq_finish = 8000;	end
if not(isfield(cfg.acoustic_generator.harm,'scan_time'));	cfg.acoustic_generator.harm.scan_time = 10;		end
if not(isfield(cfg.acoustic_generator.harm,'scan_type'));	cfg.acoustic_generator.harm.scan_type = 'log';	end
if not(isfield(cfg.acoustic_generator.harm,'amplitude'));	cfg.acoustic_generator.harm.amplitude = 0.95;	end

set(handles.get_sls_chkbtn,		 'Value',cfg.acoustic_generator.sls.enable);
set(handles.get_harm_chkbtn,	 'Value',cfg.acoustic_generator.harm.enable);
set(handles.harm_freq_start_ed,  'String',num2str(cfg.acoustic_generator.harm.freq_start));
set(handles.harm_freq_finish_ed, 'String',num2str(cfg.acoustic_generator.harm.freq_finish));
set(handles.harm_scan_time_ed,   'String',num2str(cfg.acoustic_generator.harm.scan_time));
set(handles.harm_amplitude_ed,   'String',num2str(cfg.acoustic_generator.harm.amplitude));
switch cfg.acoustic_generator.harm.scan_type
	case 'lin'
		set(handles.harm_scan_lin, 'Value',1);
	case 'log'
		set(handles.harm_scan_log, 'Value',1);
	otherwise
end
get_harm_chkbtn_Callback([], [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_acoustic wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_acoustic_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config;
if handles.press_ok
	cfg.acoustic_generator.sls.enable =  get(handles.get_sls_chkbtn, 'Value');
	cfg.acoustic_generator.harm.enable = get(handles.get_harm_chkbtn, 'Value');
	cfg.acoustic_generator.harm.freq_start =  str2double(get(handles.harm_freq_start_ed,  'String'));
	cfg.acoustic_generator.harm.freq_finish = str2double(get(handles.harm_freq_finish_ed, 'String'));
	cfg.acoustic_generator.harm.scan_time =   str2double(get(handles.harm_scan_time_ed,   'String'));
	cfg.acoustic_generator.harm.amplitude =   str2double(get(handles.harm_amplitude_ed,   'String'));
	if get(handles.harm_scan_log, 'Value')
		cfg.acoustic_generator.harm.scan_type = 'log';
	else
		cfg.acoustic_generator.harm.scan_type = 'lin';
	end
end

varargout{1} = cfg;

% The figure can be deleted now
delete(handles.figure1);


% --- Executes on button press in radiobutton2.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3


% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton4


% --- Executes on button press in get_sls_chkbtn.
function get_sls_chkbtn_Callback(hObject, eventdata, handles)
% hObject    handle to get_sls_chkbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of get_sls_chkbtn


% --- Executes on button press in get_harm_chkbtn.
function get_harm_chkbtn_Callback(hObject, eventdata, handles)
% hObject    handle to get_harm_chkbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of get_harm_chkbtn
if get(handles.get_harm_chkbtn, 'Value')
	is_enable = 'on';
else
	is_enable = 'off';
end
set(handles.harm_freq_start_ed,  'Enable',is_enable);
set(handles.harm_freq_finish_ed, 'Enable',is_enable);
set(handles.harm_scan_time_ed,   'Enable',is_enable);
set(handles.harm_scan_lin,		 'Enable',is_enable);
set(handles.harm_scan_log,		 'Enable',is_enable);
set(handles.harm_amplitude_ed,	 'Enable',is_enable);


function harm_freq_start_ed_Callback(hObject, eventdata, handles)
% hObject    handle to harm_freq_start_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harm_freq_start_ed as text
%        str2double(get(hObject,'String')) returns contents of harm_freq_start_ed as a double


% --- Executes during object creation, after setting all properties.
function harm_freq_start_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harm_freq_start_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function harm_freq_finish_ed_Callback(hObject, eventdata, handles)
% hObject    handle to harm_freq_finish_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harm_freq_finish_ed as text
%        str2double(get(hObject,'String')) returns contents of harm_freq_finish_ed as a double


% --- Executes during object creation, after setting all properties.
function harm_freq_finish_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harm_freq_finish_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function harm_scan_time_ed_Callback(hObject, eventdata, handles)
% hObject    handle to harm_scan_time_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harm_scan_time_ed as text
%        str2double(get(hObject,'String')) returns contents of harm_scan_time_ed as a double


% --- Executes during object creation, after setting all properties.
function harm_scan_time_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harm_scan_time_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function harm_scan_speed_ed_Callback(hObject, eventdata, handles)
% hObject    handle to harm_scan_speed_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harm_scan_speed_ed as text
%        str2double(get(hObject,'String')) returns contents of harm_scan_speed_ed as a double


% --- Executes during object creation, after setting all properties.
function harm_scan_speed_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harm_scan_speed_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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


function harm_amplitude_ed_Callback(hObject, eventdata, handles)
% hObject    handle to harm_amplitude_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of harm_amplitude_ed as text
%        str2double(get(hObject,'String')) returns contents of harm_amplitude_ed as a double


% --- Executes during object creation, after setting all properties.
function harm_amplitude_ed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to harm_amplitude_ed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
