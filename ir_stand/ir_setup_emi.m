function varargout = ir_setup_emi(varargin)
% IR_SETUP_EMI MATLAB code for ir_setup_emi.fig
%      IR_SETUP_EMI, by itself, creates a new IR_SETUP_EMI or raises the existing
%      singleton*.
%
%      H = IR_SETUP_EMI returns the handle to a new IR_SETUP_EMI or the handle to
%      the existing singleton*.
%
%      IR_SETUP_EMI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_SETUP_EMI.M with the given input arguments.
%
%      IR_SETUP_EMI('Property','Value',...) creates a new IR_SETUP_EMI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_setup_emi_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_setup_emi_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_setup_emi

% Last Modified by GUIDE v2.5 20-May-2015 12:57:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_setup_emi_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_setup_emi_OutputFcn, ...
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


% --- Executes just before ir_setup_emi is made visible.
function ir_setup_emi_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_setup_emi (see VARARGIN)

% Choose default command line output for ir_setup_emi
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
handles.config0.emi_generator = struct('program_list',[], 'continue_flag',true, 'continue_index',1, 'continue_counter',1, 'restart_list',true);
handles.config = cfg;
handles.config_default = cfg_def;

set_controls(handles, struct_merge(cfg,cfg_def,handles.config0));

set_icon(handles.add_btn, 'add.png');
set_icon(handles.del_btn, 'delete.png');
set_icon(handles.top_btn, 'top.png');
set_icon(handles.up_btn, 'up.png');
set_icon(handles.down_btn, 'down.png');
set_icon(handles.bottom_btn, 'bottom.png');
set_icon(handles.ok_btn, 'yes.png', true);
set_icon(handles.cancel_btn, 'no.png', true);
set_icon(handles.reset_btn, 'undo.png', true);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_setup_emi wait for user response (see UIRESUME)
uiwait(handles.figure1);


function cfg = set_controls(handles, cfg)
if size(cfg.emi_generator.program_list,2) == 3
	cfg.emi_generator.program_list(:,4) = 1;
end
if size(cfg.emi_generator.program_list,2) == 4
	cfg.emi_generator.program_list(:,[5 6]) = nan;
end

set(handles.emi_program_tbl, 'Data', [cfg.emi_generator.program_list; nan(1,numel(get(handles.emi_program_tbl,'ColumnWidth')))]);
set(handles.emi_continue_flag, 'Value', cfg.emi_generator.continue_flag);
set(handles.continue_index_ed,	'String', num2str(cfg.emi_generator.continue_index));
set(handles.continue_counter_ed,'String', num2str(cfg.emi_generator.continue_counter));
emi_continue_flag_Callback(handles.emi_continue_flag, [], handles);
set(handles.restart_list_1, 'Value', ~handles.config0.emi_generator.restart_list);
set(handles.restart_list_2, 'Value', handles.config0.emi_generator.restart_list);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_emi_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config;
if handles.press_ok
	cfg.emi_generator.program_list = get(handles.emi_program_tbl, 'Data');
	kill_ind = any(isnan(cfg.emi_generator.program_list(:,1:4)),2);
	cfg.emi_generator.program_list(kill_ind, :) = [];
	cfg.emi_generator.continue_flag = get(handles.emi_continue_flag, 'Value');
	cfg.emi_generator.continue_index = str2double(get(handles.continue_index_ed,'String'));
	cfg.emi_generator.continue_counter = str2double(get(handles.continue_counter_ed,'String'));
	cfg.emi_generator.restart_list = get(handles.restart_list_2, 'Value');
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


% --- Executes when entered data in editable cell(s) in emi_program_tbl.
function emi_program_tbl_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to emi_program_tbl (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
data = get(hObject, 'Data');
nan_rows = all(isnan(data),2);
if any(nan_rows(1:end-1)) || not(nan_rows(end))
	set(hObject, 'Data',[data(not(nan_rows),:); nan(1,size(data,2))]);
end


% --- Executes on button press in add_btn.
function add_btn_Callback(hObject, eventdata, handles)
% hObject    handle to add_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel)
	return
end
set(handles.emi_program_tbl, 'Data',[data(1:sel(1)-1,:); 1, nan(1,size(data,2)-1); data(sel(1):end,:)]);


% --- Executes on button press in del_btn.
function del_btn_Callback(hObject, eventdata, handles)
% hObject    handle to del_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if size(data,1)<2 || isempty(sel) || sel(1)==size(data,1)
	return
end
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1:end],:));


% --- Executes on button press in up_btn.
function up_btn_Callback(hObject, eventdata, handles)
% hObject    handle to up_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if size(data,1)<2 || isempty(sel) || sel(1)==size(data,1) || sel(1)==1
	return
end
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-2 sel(1) sel(1)-1 sel(1)+1:end],:));


% --- Executes on button press in down_btn.
function down_btn_Callback(hObject, eventdata, handles)
% hObject    handle to down_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if size(data,1)<2 || isempty(sel) || sel(1)>=size(data,1)-1
	return
end
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1 sel(1) sel(1)+2:end],:));


% --- Executes on button press in top_btn.
function top_btn_Callback(hObject, eventdata, handles)
% hObject    handle to top_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if size(data,1)<2 || isempty(sel) || sel(1)==size(data,1)
	return
end
set(handles.emi_program_tbl, 'Data',data([sel(1) 1:sel(1)-1 sel(1)+1:end],:));


% --- Executes on button press in bottom_btn.
function bottom_btn_Callback(hObject, eventdata, handles)
% hObject    handle to bottom_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if size(data,1)<2 || isempty(sel) || sel(1)==size(data,1)
	return
end
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1:end-1 sel(1) end],:));


% --- Executes on button press in reset_btn.
function reset_btn_Callback(hObject, eventdata, handles)
% hObject    handle to reset_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set_controls(handles, struct_merge(handles.config_default,handles.config0));


% --- Executes when selected cell(s) is changed in emi_program_tbl.
function emi_program_tbl_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to emi_program_tbl (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'UserData', eventdata.Indices);


% --- Executes on button press in emi_continue_flag.
function emi_continue_flag_Callback(hObject, eventdata, handles)
% hObject    handle to emi_continue_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of emi_continue_flag
if get(hObject, 'Value')
	is_enable = 'on';
else
	is_enable = 'off';
end
set(handles.continue_index_ed,	'Enable',is_enable);
set(handles.continue_counter_ed,'Enable',is_enable);
