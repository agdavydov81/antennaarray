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

% Last Modified by GUIDE v2.5 06-Oct-2013 19:38:42

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
if not(isfield(cfg,'detector'));					cfg.detector = struct();				end
if not(isfield(cfg.detector,'start_time'));			cfg.detector.start_time = 5;			end
if not(isfield(cfg.detector,'fir_freq'));			cfg.detector.fir_freq = 3;				end
if not(isfield(cfg.detector,'fir_order'));			cfg.detector.fir_order = 4;				end
if not(isfield(cfg.detector,'stat_lo'));			cfg.detector.stat_lo = 0.05;			end
if not(isfield(cfg.detector,'stat_hi'));			cfg.detector.stat_hi = 0.95;			end
if not(isfield(cfg.detector,'median_size'));		cfg.detector.median_size = 3;			end
if not(isfield(cfg.detector,'detector_points'));	cfg.detector.detector_points = 10;		end
if not(isfield(cfg.detector,'detector_part'));		cfg.detector.detector_part = 0.01;		end

handles.config = cfg;

set(handles.start_time,		'String', num2str(cfg.detector.start_time));
set(handles.fir_freq,		'String', num2str(cfg.detector.fir_freq));
set(handles.fir_order,		'String', num2str(cfg.detector.fir_order));
set(handles.stat_lo,		'String', num2str(cfg.detector.stat_lo));
set(handles.stat_hi,		'String', num2str(cfg.detector.stat_hi));
set(handles.median_size,	'String', num2str(cfg.detector.median_size));
set(handles.detector_points,'String', num2str(cfg.detector.detector_points));
set(handles.detector_part,	'String', num2str(cfg.detector.detector_part));


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_thresholds wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_thresholds_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ok_btn.
function ok_btn_Callback(hObject, eventdata, handles)
% hObject    handle to ok_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in cancel_btn.
function cancel_btn_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function fir_freq_Callback(hObject, eventdata, handles)
% hObject    handle to fir_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fir_freq as text
%        str2double(get(hObject,'String')) returns contents of fir_freq as a double


% --- Executes during object creation, after setting all properties.
function fir_freq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fir_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fir_order_Callback(hObject, eventdata, handles)
% hObject    handle to fir_order (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fir_order as text
%        str2double(get(hObject,'String')) returns contents of fir_order as a double


% --- Executes during object creation, after setting all properties.
function fir_order_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fir_order (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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
