function varargout = SLS_SegCfgDlg(varargin)
%SLS_SEGCFGDLG M-file for SLS_SegCfgDlg.fig
%      SLS_SEGCFGDLG, by itself, creates a new SLS_SEGCFGDLG or raises the existing
%      singleton*.
%
%      H = SLS_SEGCFGDLG returns the handle to a new SLS_SEGCFGDLG or the handle to
%      the existing singleton*.
%
%      SLS_SEGCFGDLG('Property','Value',...) creates a new SLS_SEGCFGDLG using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to SLS_SegCfgDlg_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      SLS_SEGCFGDLG('CALLBACK') and SLS_SEGCFGDLG('CALLBACK',hObject,...) call the
%      local function named CALLBACK in SLS_SEGCFGDLG.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SLS_SegCfgDlg

% Last Modified by GUIDE v2.5 19-Oct-2009 01:36:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SLS_SegCfgDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @SLS_SegCfgDlg_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
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


% --- Executes just before SLS_SegCfgDlg is made visible.
function SLS_SegCfgDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for SLS_SegCfgDlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SLS_SegCfgDlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global seg_config;
set(handles.ed_FrameSize,           'String',   num2str(seg_config.frame_size));
set(handles.ed_FrameStep,           'String',   num2str(seg_config.frame_step));
[proc_index, proc_names]=find_str({'PLP'; 'RastaPLP'; 'LSF'; 'MFCC'}, seg_config.proc_type);
set(handles.pop_ProcType,           'String',   proc_names,  'Value',proc_index); 
set(handles.ed_SegLen,              'String',   num2str(seg_config.seg_min_len));
set(handles.ed_SegThreshold,        'String',   num2str(seg_config.seg_dist_threshold));
set(handles.ed_SpectrumChangeMax,   'String',   num2str(seg_config.spectrum_max_change_freq));
handles.SLS_DistTypesNames={    ...
    'euclidean'     'Евклидово расстояние'; ...
    'seuclidean'    'Нормированное Евклидово расстояние'; ...
    'mahalanobis'   'Расстояние Махаланобиса'; ...
    'cityblock'     'Метрика городских кварталов'; ...
    'minkowski'     'Метрика Минковского'; ...
    'cosine'        'Косинусное расстояние'; ...
    'correlation'   'Корреляционное расстояние'};
dist_index=find_str(handles.SLS_DistTypesNames(:,1), seg_config.dist_func);
set(handles.pop_DistFunc,           'String',   handles.SLS_DistTypesNames(:,2),'Value',min(dist_index,size(handles.SLS_DistTypesNames,1)));
set(handles.ed_MinkowskiParam,      'String',   num2str(seg_config.dist_minkowski_param));
set(handles.ed_DistAvr,             'String',   num2str(seg_config.dist_avr_time));
set(handles.chk_DebugInfo,          'Value',    seg_config.display_debug);
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = SLS_SegCfgDlg_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ed_FrameSize_Callback(hObject, eventdata, handles)
% hObject    handle to ed_FrameSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_FrameSize as text
%        str2double(get(hObject,'String')) returns contents of ed_FrameSize as a double


% --- Executes during object creation, after setting all properties.
function ed_FrameSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_FrameSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_FrameStep_Callback(hObject, eventdata, handles)
% hObject    handle to ed_FrameStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_FrameStep as text
%        str2double(get(hObject,'String')) returns contents of ed_FrameStep as a double


% --- Executes during object creation, after setting all properties.
function ed_FrameStep_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_FrameStep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_ProcType.
function pop_ProcType_Callback(hObject, eventdata, handles)
% hObject    handle to pop_ProcType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pop_ProcType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_ProcType


% --- Executes during object creation, after setting all properties.
function pop_ProcType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_ProcType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_SegLen_Callback(hObject, eventdata, handles)
% hObject    handle to ed_SegLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_SegLen as text
%        str2double(get(hObject,'String')) returns contents of ed_SegLen as a double


% --- Executes during object creation, after setting all properties.
function ed_SegLen_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_SegLen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_SegThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to ed_SegThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_SegThreshold as text
%        str2double(get(hObject,'String')) returns contents of ed_SegThreshold as a double


% --- Executes during object creation, after setting all properties.
function ed_SegThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_SegThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_SpectrumChangeMax_Callback(hObject, eventdata, handles)
% hObject    handle to ed_SpectrumChangeMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_SpectrumChangeMax as text
%        str2double(get(hObject,'String')) returns contents of ed_SpectrumChangeMax as a double


% --- Executes during object creation, after setting all properties.
function ed_SpectrumChangeMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_SpectrumChangeMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chk_DebugInfo.
function chk_DebugInfo_Callback(hObject, eventdata, handles)
% hObject    handle to chk_DebugInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_DebugInfo


% --- Executes on button press in btn_OK.
function btn_OK_Callback(hObject, eventdata, handles)
% hObject    handle to btn_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global seg_config;
seg_config.frame_size=                  str2double(get(handles.ed_FrameSize,'String'));
seg_config.frame_step=                  str2double(get(handles.ed_FrameStep,'String'));
proc_types=                             get(handles.pop_ProcType,'String');
proc_index=                             get(handles.pop_ProcType,'Value');
seg_config.proc_type=                   proc_types{proc_index};
seg_config.seg_min_len=                 str2double(get(handles.ed_SegLen,'String'));
seg_config.seg_dist_threshold=          str2double(get(handles.ed_SegThreshold,'String'));
seg_config.spectrum_max_change_freq=    str2double(get(handles.ed_SpectrumChangeMax,'String'));
dist_index=                             get(handles.pop_DistFunc,'Value');
seg_config.dist_func=                   handles.SLS_DistTypesNames{dist_index,1};
seg_config.dist_minkowski_param=        max(1,round(str2double(get(handles.ed_MinkowskiParam,'String'))));
seg_config.dist_avr_time=               str2double(get(handles.ed_DistAvr,'String'));
seg_config.display_debug=               get(handles.chk_DebugInfo,'Value');
xml_struct_save('SLS_SegCfg.xml',seg_config);
delete(handles.figure1);

% --- Executes on button press in btn_Cancel.
function btn_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);

function [name_ind, names]=find_str(names, name_cur)
    name_ind=1;
    find_success=0;
    for i=1:length(names)
        if strcmpi(names{i}, name_cur)
            name_ind=i;
            find_success=1;
            break;
        end
    end
    if ~find_success
        names{end}=name_cur;
        name_ind=length(names);
    end

% --- Executes on selection change in pop_DistFunc.
function pop_DistFunc_Callback(hObject, eventdata, handles)
% hObject    handle to pop_DistFunc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pop_DistFunc contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_DistFunc


% --- Executes during object creation, after setting all properties.
function pop_DistFunc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_DistFunc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_MinkowskiParam_Callback(hObject, eventdata, handles)
% hObject    handle to ed_MinkowskiParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_MinkowskiParam as text
%        str2double(get(hObject,'String')) returns contents of ed_MinkowskiParam as a double


% --- Executes during object creation, after setting all properties.
function ed_MinkowskiParam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_MinkowskiParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ed_DistAvr_Callback(hObject, eventdata, handles)
% hObject    handle to ed_DistAvr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_DistAvr as text
%        str2double(get(hObject,'String')) returns contents of ed_DistAvr as a double


% --- Executes during object creation, after setting all properties.
function ed_DistAvr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_DistAvr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
