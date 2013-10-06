function varargout = ir_stand(varargin)
% IR_STAND MATLAB code for ir_stand.fig
%      IR_STAND, by itself, creates a new IR_STAND or raises the existing
%      singleton*.
%
%      H = IR_STAND returns the handle to a new IR_STAND or the handle to
%      the existing singleton*.
%
%      IR_STAND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IR_STAND.M with the given input arguments.
%
%      IR_STAND('Property','Value',...) creates a new IR_STAND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ir_stand_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ir_stand_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ir_stand

% Last Modified by GUIDE v2.5 25-Sep-2013 15:21:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ir_stand_OpeningFcn, ...
                   'gui_OutputFcn',  @ir_stand_OutputFcn, ...
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


% --- Executes just before ir_stand is made visible.
function ir_stand_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ir_stand (see VARARGIN)

% Choose default command line output for ir_stand
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ir_stand wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Show BSUIR logo
imshow([fileparts(mfilename('fullpath')) filesep 'bsuir_logo.png'], 'Parent',handles.logo_axes);

% Position to center of screen
old_units = get(hObject,'Units');
scr_sz = get(0,'ScreenSize');
set(hObject,'Units',get(0,'Units'));
cur_pos = get(hObject,'Position');
set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
set(hObject,'Units',old_units);

% Load configuration
[cur_path, cur_name]= fileparts(mfilename('fullpath'));
handles.config_file = fullfile(cur_path, [cur_name '_config.mat']);
try
	cache = load(handles.config_file);
	handles.config = cache.config;
catch ME
	cfg.generator.sls = struct('enable',true);
	cfg.generator.harm = struct('enable',false, ...
								'freq_start',100, ...
								'freq_finish',8000, ...
								'scan_time',10, ...
								'scan_type','log', ...
								'amplitude', 0.95);
	handles.config = cfg;
end

set(handles.work_stop_btn,     'Enable','off');
set(handles.work_abort_btn,    'Enable','off');
set(handles.work_continue_btn, 'Enable','off');

guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ir_stand_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in setup_emi_btn.
function setup_emi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_emi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in setup_acoustics_btn.
function setup_acoustics_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_acoustics_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.config = ir_setup_acoustic(handles.config);
guidata(hObject, handles);


% --- Executes on button press in setup_irvideo_btn.
function setup_irvideo_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_irvideo_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in setup_report_btn.
function setup_report_btn_Callback(hObject, eventdata, handles)
% hObject    handle to setup_report_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in work_continue_btn.
function work_continue_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_continue_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in work_stop_btn.
function work_stop_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_stop_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in work_abort_btn.
function work_abort_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_abort_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.config.generator.sls.enable
	dos('taskkill /F /IM Lobanov_mark.exe 1>nul 2>&1');
end

if handles.config.generator.harm.enable
	playrec('reset');
end

set(handles.work_start_btn, 'Enable','on');
set(handles.work_abort_btn, 'Enable','off');
set(handles.setup_acoustics_btn, 'Enable','on');


% --- Executes on button press in work_start_btn.
function work_start_btn_Callback(hObject, eventdata, handles)
% hObject    handle to work_start_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Fork SLS process
if handles.config.generator.sls.enable
	sls_dir = [fileparts(mfilename('fullpath')) filesep 'sls' filesep];
	dos_str = ['"' sls_dir 'hstart.exe" /NOCONSOLE /D="' sls_dir '" "Lobanov_mark.exe Db_Bor1/ 0 0"'];
	dos(dos_str);
end

% Generages signal
if handles.config.generator.harm.enable
	play.fs = 44100;
	play.buff_sz = 0.5*play.fs;
	play.buff_num = 10;
	play.buffs = [];

	%Test if current initialisation is ok
	if playrec('isInitialised')
		playrec('reset');
	end

	%Initialise if not initialised
	if ~playrec('isInitialised')
		dev_list = playrec('getDevices');
		dev_list(logical(not([dev_list.outputChans]))) = [];
		if isempty(dev_list)
			error('ir_stand:sound_output','Can''t find any sound output device.');
		end

		dev_ind = arrayfun(@(x) ~isempty(strfind(x.name, 'Microsoft Sound Mapper')), dev_list);
		if all(not(dev_ind))
			dev_ind = arrayfun(@(x) ~isempty(strfind(x.name, 'ереназначен')), dev_list);
		end
		if all(not(dev_ind))
			dev_ind(1) = true;
		end

		dev_id = dev_list(dev_ind).deviceID;

		playrec('init', play.fs, dev_id, -1, 1);

		% This slight delay is included because if a dialog box pops up during
		% initialisation (eg MOTU telling you there are no MOTU devices
		% attached) then without the delay Ctrl+C to stop playback sometimes
		% doesn't work.
		pause(0.1);
	end

	play.timer = struct('pos',0, ...
						'f_mod_last',0, ...
						'handle', timer('TimerFcn',@player_timer_func, 'StopFcn',@player_timer_stop, 'Period',play.buff_sz/play.fs, 'ExecutionMode','fixedRate', 'UserData',handles.figure1));
	handles.play = play;
	guidata(handles.figure1, handles);
	start(handles.play.timer.handle);
end

set(handles.work_start_btn, 'Enable','off');
set(handles.work_abort_btn, 'Enable','on');
set(handles.setup_acoustics_btn, 'Enable','off');


function player_timer_func(timer_handle, eventdata)
if not(playrec('isInitialised'))
	stop(timer_handle);
	return;
end

fig_handle = get(timer_handle, 'UserData');
handles = guidata(fig_handle);

while ~isempty(handles.play.buffs) && playrec('isFinished', handles.play.buffs(1))
	handles.play.buffs(1) = [];
end

harm_cfg = handles.config.generator.harm;
while numel(handles.play.buffs) < handles.play.buff_num
	cur_t = handles.play.timer.pos+(0:handles.play.buff_sz-1)'/handles.play.fs;
	handles.play.timer.pos = handles.play.timer.pos+handles.play.buff_sz/handles.play.fs;

	f_mod = acos(cos(cur_t*pi/harm_cfg.scan_time))/pi;

	switch harm_cfg.scan_type
		case 'lin'
			f_mod = (harm_cfg.freq_finish-harm_cfg.freq_start)*f_mod+harm_cfg.freq_start;
		case 'log'
			f_mod = harm_cfg.freq_start*(harm_cfg.freq_finish/harm_cfg.freq_start).^(f_mod);
		otherwise
			error('ir_stand:harm_gen',['Unsupported frequency modulation type "' harm_cfg.scan_type '".']);
	end

	f_mod = cumsum(f_mod)/handles.play.fs + handles.play.timer.f_mod_last;
	f_mod = rem(f_mod,1);
	handles.play.timer.f_mod_last = f_mod(end);

	cur_x = harm_cfg.amplitude*cos(2*pi*f_mod);

	% Play generated sound
	handles.play.buffs = [handles.play.buffs playrec('play', cur_x, 1)];
end

guidata(fig_handle, handles);


function player_timer_stop(timer_handle, eventdata)
delete(timer_handle);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

config = handles.config;
save(handles.config_file, 'config');

% Hint: delete(hObject) closes the figure
delete(hObject);
