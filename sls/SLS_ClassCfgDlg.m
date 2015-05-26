function varargout = SLS_ClassCfgDlg(varargin)
% SLS_CLASSCFGDLG M-file for SLS_ClassCfgDlg.fig
%      SLS_CLASSCFGDLG, by itself, creates a new SLS_CLASSCFGDLG or raises the existing
%      singleton*.
%
%      H = SLS_CLASSCFGDLG returns the handle to a new SLS_CLASSCFGDLG or the handle to
%      the existing singleton*.
%
%      SLS_CLASSCFGDLG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLS_CLASSCFGDLG.M with the given input arguments.
%
%      SLS_CLASSCFGDLG('Property','Value',...) creates a new SLS_CLASSCFGDLG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SLS_ClassCfgDlg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SLS_ClassCfgDlg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SLS_ClassCfgDlg

% Last Modified by GUIDE v2.5 25-Jan-2009 23:07:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SLS_ClassCfgDlg_OpeningFcn, ...
                   'gui_OutputFcn',  @SLS_ClassCfgDlg_OutputFcn, ...
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


% --- Executes just before SLS_ClassCfgDlg is made visible.
function SLS_ClassCfgDlg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SLS_ClassCfgDlg (see VARARGIN)

% Choose default command line output for SLS_ClassCfgDlg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SLS_ClassCfgDlg wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global class_config;
set(handles.ed_FrameSize,           'String',   num2str(class_config.frame_size));
set(handles.ed_FrameStep,           'String',   num2str(class_config.frame_step));
[proc_index, proc_types]=find_str({'PLP'; 'RastaPLP'; 'LSF'; 'MFCC'}, class_config.proc_type);
set(handles.pop_ProcType,           'String',   proc_types,'Value',proc_index); 
set(handles.ed_GeneralizedMeanParam,'String',   num2str(class_config.gen_mean_param));
set(handles.ed_SegLenFactor,        'String',   num2str(class_config.seg_len_factor));
handles.SLS_DistTypesNames={    ...
    'euclidean'     'Евклидово расстояние'; ...
    'seuclidean'    'Нормированное Евклидово расстояние'; ...
    'mahalanobis'   'Расстояние Махаланобиса'; ...
    'cityblock'     'Метрика городских кварталов'; ...
    'minkowski'     'Метрика Минковского'; ...
    'cosine'        'Косинусное расстояние'; ...
    'correlation'   'Корреляционное расстояние'};
dist_index=find_str(handles.SLS_DistTypesNames(:,1), class_config.dist_func);
set(handles.pop_DistFunc,           'String',   handles.SLS_DistTypesNames(:,2),'Value', min(dist_index,size(handles.SLS_DistTypesNames,1)));
set(handles.ed_MinkowskiParam,      'String',   num2str(class_config.dist_minkowski_param));
set(handles.ed_ClassNum,            'String',   num2str(class_config.class_num));
handles.SLS_ClassTypesNames={    ...
    'K-means'       'K-средних'; ...
    'SOFM'          'Самоорганизующиеся карты'};
dist_index=find_str(handles.SLS_ClassTypesNames(:,1), class_config.class_type);
set(handles.pop_ClassType,          'String',   handles.SLS_ClassTypesNames(:,2),'Value', min(dist_index,size(handles.SLS_ClassTypesNames,1)));
set(handles.chk_DebugInfo,          'Value',    class_config.display_debug);
guidata(hObject, handles);


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


% --- Outputs from this function are returned to the command line.
function varargout = SLS_ClassCfgDlg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function ed_ClassNum_Callback(hObject, eventdata, handles)
% hObject    handle to ed_ClassNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_ClassNum as text
%        str2double(get(hObject,'String')) returns contents of ed_ClassNum as a double


% --- Executes during object creation, after setting all properties.
function ed_ClassNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_ClassNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in pop_ClassType.
function pop_ClassType_Callback(hObject, eventdata, handles)
% hObject    handle to pop_ClassType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns pop_ClassType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_ClassType


% --- Executes during object creation, after setting all properties.
function pop_ClassType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pop_ClassType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_OK.
function btn_OK_Callback(hObject, eventdata, handles)
% hObject    handle to btn_OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global class_config;
class_config.frame_size=            str2double(get(handles.ed_FrameSize,'String'));
class_config.frame_step=            str2double(get(handles.ed_FrameStep,'String'));
proc_types=                         get(handles.pop_ProcType,'String');
proc_index=                         get(handles.pop_ProcType,'Value');
class_config.proc_type=             proc_types{proc_index};
class_config.gen_mean_param=        str2double(get(handles.ed_GeneralizedMeanParam,'String'));
class_config.seg_len_factor=        str2double(get(handles.ed_SegLenFactor,'String'));
dist_index=                         get(handles.pop_DistFunc,'Value');
class_config.dist_func=             handles.SLS_DistTypesNames{dist_index,1};
class_config.dist_minkowski_param=  str2double(get(handles.ed_MinkowskiParam,'String'));
class_config.class_num=             str2double(get(handles.ed_ClassNum,'String'));
dist_index=                         get(handles.pop_ClassType,'Value');
class_config.class_type=            handles.SLS_ClassTypesNames{dist_index,1};
class_config.display_debug=         get(handles.chk_DebugInfo,'Value');
xml_struct_save('SLS_ClassCfg.xml',class_config);
delete(handles.figure1);


% --- Executes on button press in btn_Cancel.
function btn_Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);


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



function ed_SegLenFactor_Callback(hObject, eventdata, handles)
% hObject    handle to ed_SegLenFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_SegLenFactor as text
%        str2double(get(hObject,'String')) returns contents of ed_SegLenFactor as a double


% --- Executes during object creation, after setting all properties.
function ed_SegLenFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_SegLenFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
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


% --- Executes on button press in chk_DebugInfo.
function chk_DebugInfo_Callback(hObject, eventdata, handles)
% hObject    handle to chk_DebugInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_DebugInfo



function ed_GeneralizedMeanParam_Callback(hObject, eventdata, handles)
% hObject    handle to ed_GeneralizedMeanParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ed_GeneralizedMeanParam as text
%        str2double(get(hObject,'String')) returns contents of ed_GeneralizedMeanParam as a double


% --- Executes during object creation, after setting all properties.
function ed_GeneralizedMeanParam_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ed_GeneralizedMeanParam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


