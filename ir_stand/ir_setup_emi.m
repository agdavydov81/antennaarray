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

% Last Modified by GUIDE v2.5 07-Nov-2015 19:35:04

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
tbl_cf = get(handles.emi_program_tbl,'ColumnFormat');
handles.config0.emi_generator = struct(	'program_list',nan(1,sum(strcmp('numeric',tbl_cf))), 'program_comment',{{''}}, ...
										'startpoint_type',1, 'continue_index',1, 'continue_counter',1, ...
										'start_index',1, 'start_counter',1, 'restart_list',1);
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
set(handles.emi_program_tbl, 'Data', [num2cell(cfg.emi_generator.program_list) cfg.emi_generator.program_comment(:)]);
set(handles.emi_startpoint_type_1, 'Value', cfg.emi_generator.startpoint_type==1);
set(handles.emi_startpoint_type_2, 'Value', cfg.emi_generator.startpoint_type==2);
set(handles.emi_startpoint_type_3, 'Value', cfg.emi_generator.startpoint_type==3);
set(handles.emi_startpoint_type_2, 'String', sprintf('Продолжить работу с места остановки (программа %d, повтор %d)',cfg.emi_generator.continue_index,cfg.emi_generator.continue_counter));
set(handles.start_index_ed,	'String', num2str(cfg.emi_generator.start_index));
set(handles.start_counter_ed,'String', num2str(cfg.emi_generator.start_counter));
uipanel3_SelectionChangeFcn([], [], handles);
set(handles.restart_list_1, 'Value', ~cfg.emi_generator.restart_list);
set(handles.restart_list_2, 'Value', cfg.emi_generator.restart_list);


% --- Outputs from this function are returned to the command line.
function varargout = ir_setup_emi_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cfg = handles.config;
if handles.press_ok
	data = get(handles.emi_program_tbl, 'Data');
	cfg.emi_generator.program_comment = data(:,7);
	data(:,7) = [];
	data(cellfun(@isempty, data)) = {nan};
	cfg.emi_generator.program_list = cell2mat(data);
	cfg.emi_generator.startpoint_type = find(arrayfun(@(x) get(x,'Value'), ...
		[handles.emi_startpoint_type_1, handles.emi_startpoint_type_2, handles.emi_startpoint_type_3]));
	cfg.emi_generator.start_index = str2double(get(handles.start_index_ed,'String'));
	cfg.emi_generator.start_counter = str2double(get(handles.start_counter_ed,'String'));
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
data = get(handles.emi_program_tbl, 'Data');
tbl_cf = get(handles.emi_program_tbl,'ColumnFormat');
data_num = data(:,strcmp('numeric',tbl_cf));
kill_ind = any( cellfun(@(x) isempty(x)||isnan(x), data_num(:,1:4)), 2);
if any(kill_ind)
	q_ans1 = 'Да, удалить строки с ошибками';
	q_ans2 = 'Нет, вернуться к редактированию';
	q_ans = questdlg({	'Некоторые обязательные ячейки таблицы не заполнены, либо содержат не корректные значения.' ...
						'В случае продолжения строки с такими значениями будут удалены из таблицы.' ...
						'Продолжить?'}, 'Ошибки в таблице', q_ans1, q_ans2, q_ans1);
	if strcmp(q_ans, q_ans1)
		pos = java_scroll_getpos(handles.emi_program_tbl);
		set(handles.emi_program_tbl, 'Data',data(~kill_ind,:));
		java_scroll_setpos(pos);
	end
else
	handles.press_ok = true;
	guidata(hObject, handles);
	uiresume(handles.figure1);
end


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


% --- Executes on button press in add_btn.
function add_btn_Callback(hObject, eventdata, handles)
% hObject    handle to add_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel)
	sel = size(data,1)+1;
end
tbl_cf = get(handles.emi_program_tbl,'ColumnFormat');
data_row = cell(1,numel(tbl_cf));
data_row(strcmp('char',tbl_cf)) = {''};
pos = java_scroll_getpos(handles.emi_program_tbl);
set(handles.emi_program_tbl, 'Data',[data(1:sel(1)-1,:); data_row; data(sel(1):end,:)]);
java_scroll_setpos(pos);


% --- Executes on button press in del_btn.
function del_btn_Callback(hObject, eventdata, handles)
% hObject    handle to del_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel)
	return
end
pos = java_scroll_getpos(handles.emi_program_tbl);
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1:end],:));
java_scroll_setpos(pos);


% --- Executes on button press in up_btn.
function up_btn_Callback(hObject, eventdata, handles)
% hObject    handle to up_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel) || sel(1)==1
	return
end
pos = java_scroll_getpos(handles.emi_program_tbl);
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-2 sel(1) sel(1)-1 sel(1)+1:end],:));
java_scroll_setpos(pos);


% --- Executes on button press in down_btn.
function down_btn_Callback(hObject, eventdata, handles)
% hObject    handle to down_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel) || sel(1)>=size(data,1)
	return
end
pos = java_scroll_getpos(handles.emi_program_tbl);
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1 sel(1) sel(1)+2:end],:));
java_scroll_setpos(pos);


% --- Executes on button press in top_btn.
function top_btn_Callback(hObject, eventdata, handles)
% hObject    handle to top_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel) || sel(1)==1
	return
end
% No need to restore position
set(handles.emi_program_tbl, 'Data',data([sel(1) 1:sel(1)-1 sel(1)+1:end],:));


% --- Executes on button press in bottom_btn.
function bottom_btn_Callback(hObject, eventdata, handles)
% hObject    handle to bottom_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = get(handles.emi_program_tbl, 'Data');
sel = get(handles.emi_program_tbl, 'UserData');
if isempty(sel) || sel(1)>=size(data,1)
	return
end
pos = java_scroll_getpos(handles.emi_program_tbl);
set(handles.emi_program_tbl, 'Data',data([1:sel(1)-1 sel(1)+1:end sel(1)],:));
pos.jpos = pos.jpos + 1e+9;
java_scroll_setpos(pos);


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


% --- Executes when selected object is changed in uipanel3.
function uipanel3_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel3 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
if get(handles.emi_startpoint_type_3, 'Value')
	is_enable = 'on';
else
	is_enable = 'off';
end
set(handles.start_index_ed,	'Enable',is_enable);
set(handles.start_counter_ed,'Enable',is_enable);


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
data = get(handles.emi_program_tbl,'Data');

if any(eventdata.Indices(2)==[1 2]) % Try automatically fill from the default programs list
	[ind, val]= find_default_program(eventdata, handles);
	if ~isempty(ind)
		data(eventdata.Indices(1),:) = val;
		pos = java_scroll_getpos(handles.emi_program_tbl);
		set(handles.emi_program_tbl,'Data',data);
		java_scroll_setpos(pos);
	end
end

ind_restore = [3 5 6 7];
if any(eventdata.Indices(2)==ind_restore) % Try restore values for default programs
	[ind, val] = find_default_program(eventdata, handles);
	if ~isempty(ind)
		data(eventdata.Indices(1),ind_restore) = val(ind_restore);
		pos = java_scroll_getpos(handles.emi_program_tbl);
		set(handles.emi_program_tbl,'Data',data);
		java_scroll_setpos(pos);
	end
end


function pos = java_scroll_getpos(emi_program_tbl)
pos.jobj = findjobj(emi_program_tbl);
pos.jscroll = pos.jobj.getVerticalScrollBar();
pos.jpos = pos.jscroll.getValue();


function java_scroll_setpos(pos)
drawnow();
pos.jscroll.setValue(pos.jpos);
pos.jobj.repaint();
pos.jobj.revalidate();


function [ind, val] = find_default_program(eventdata, handles)
ind = [];
val = {};
try
	if	isfield_ex(handles,'config_default.emi_generator.program_list') && ...
		isfield_ex(handles,'config_default.emi_generator.program_comment')

		data = get(handles.emi_program_tbl,'Data');
		cfg_def = handles.config_default;
		ind = find(	cfg_def.emi_generator.program_list(:,1) == data{eventdata.Indices(1),1} & ...
					cfg_def.emi_generator.program_list(:,2) == data{eventdata.Indices(1),2},1);

		if ~isempty(ind)
			val = [num2cell(cfg_def.emi_generator.program_list) cfg_def.emi_generator.program_comment(:)];
			val = val(ind,:);
		end
	end
catch
end


function ret = isfield_ex(obj, fl_name)
ret = true;
while ret && ~isempty(fl_name)
	[cur_fl, fl_name] = strtok(fl_name,'.'); %#ok<STTOK>
	ret = isfield(obj,cur_fl);
	if ~ret
		break
	end
	obj = obj.(cur_fl);
end
