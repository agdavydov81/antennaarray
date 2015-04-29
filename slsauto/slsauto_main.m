function varargout = slsauto_main(varargin)
% SLSAUTO_MAIN MATLAB code for slsauto_main.fig
%      SLSAUTO_MAIN, by itself, creates a new SLSAUTO_MAIN or raises the existing
%      singleton*.
%
%      H = SLSAUTO_MAIN returns the handle to a new SLSAUTO_MAIN or the handle to
%      the existing singleton*.
%
%      SLSAUTO_MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SLSAUTO_MAIN.M with the given input arguments.
%
%      SLSAUTO_MAIN('Property','Value',...) creates a new SLSAUTO_MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before slsauto_main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to slsauto_main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help slsauto_main

% Last Modified by GUIDE v2.5 25-Apr-2015 17:50:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @slsauto_main_OpeningFcn, ...
                   'gui_OutputFcn',  @slsauto_main_OutputFcn, ...
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


% --- Executes just before slsauto_main is made visible.
function slsauto_main_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to slsauto_main (see VARARGIN)

% Choose default command line output for slsauto_main
handles.output = hObject;

% Add dependencies
addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'@.*' '\.svn' 'private' 'html'});

% Load translation module
handles.gtxt = simplegettext();
handles.gtxt.traslate_ui(hObject);

% Load dialog values
handles.cache_filename = [mfilename '_cache.mat'];
try
	cache = load(handles.cache_filename);
	set(handles.snd_filename_edit,'String',cache.dlg_cfg.snd_filename_edit);
catch %#ok<*CTCH>
end

% Position to center of screen
old_units = get(hObject,'Units');
scr_sz = get(0,'ScreenSize');
set(hObject,'Units',get(0,'Units'));
cur_pos = get(hObject,'Position');
set(hObject,'Position',[(scr_sz(3)-cur_pos(3))/2, (scr_sz(4)-cur_pos(4))/2, cur_pos([3 4])]);
set(hObject,'Units',old_units); 

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes slsauto_main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = slsauto_main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
	dlg_cfg.snd_filename_edit =	get(handles.snd_filename_edit,'String');
	save(handles.cache_filename,'dlg_cfg');
catch
end

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in snd_filename_btn.
function snd_filename_btn_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to snd_filename_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[dlg_name,dlg_path] = uigetfile({'*.wav;*.flac;*.ogg','Sound files';'*.*','All files'}, ...
						handles.gtxt.translate('Select file for processing'),get(handles.snd_filename_edit,'String'));
if dlg_name==0
	return
end
set(handles.snd_filename_edit,'String',fullfile(dlg_path,dlg_name));


% --- Executes on button press in pitchraw_btn.
function pitchraw_btn_Callback(hObject, eventdata, handles)
% hObject    handle to pitchraw_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slsauto_pitch_raw(struct('snd_filename',get(handles.snd_filename_edit,'String')));


% --- Executes on button press in pitcheditor_btn.
function pitcheditor_btn_Callback(hObject, eventdata, handles)
% hObject    handle to pitcheditor_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slsauto_pitch_editor(struct('snd_filename',get(handles.snd_filename_edit,'String')));


% --- Executes on button press in syntagmstat_btn.
function syntagmstat_btn_Callback(hObject, eventdata, handles)
% hObject    handle to syntagmstat_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slsauto_syntagm_stat(struct('snd_filename',get(handles.snd_filename_edit,'String')));


% --- Executes on button press in syntagmgen_btn.
function syntagmgen_btn_Callback(hObject, eventdata, handles)
% hObject    handle to syntagmgen_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dlg_out = inputdlg(	handles.gtxt.translate({'The minimum length of a pause (s)' 'The maximum signal power in the pause (dB)'}), ...
					handles.gtxt.translate('Input function parameters'), 1, {'0.5' '-30'}, 'on');
if isempty(dlg_out)
	return
end
pause(0.2);
dlg_out = cellfun(@str2double, dlg_out, 'UniformOutput',false);
slsauto_syntagm_gen(struct('snd_filename',get(handles.snd_filename_edit,'String')), dlg_out{:});


% --- Executes on button press in prosody_btn.
function prosody_btn_Callback(hObject, eventdata, handles)
% hObject    handle to prosody_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slsauto_prosody(struct('snd_filename',get(handles.snd_filename_edit,'String')));


% --- Executes on button press in vu2lab_btn.
function vu2lab_btn_Callback(hObject, eventdata, handles)
% hObject    handle to vu2lab_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dlg_out = inputdlg(	handles.gtxt.translate({'The neighborhood for the nearest local maximum search (s)' ...
							'The local maximum minimum value' 'The segmentation minimum block size (s)'}), ...
					handles.gtxt.translate('Input function parameters'), 1, {'0.029' '1.5' '0.080'}, 'on');
if isempty(dlg_out)
	return
end
pause(0.2);
dlg_out = cellfun(@str2double, dlg_out, 'UniformOutput',false);
slsauto_vu2lab(struct('snd_filename',get(handles.snd_filename_edit,'String')), dlg_out{:});


% --- Executes on button press in lpcanalyse_btn.
function lpcanalyse_btn_Callback(hObject, eventdata, handles)
% hObject    handle to lpcanalyse_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dlg_out = inputdlg(	handles.gtxt.translate({'Frame size (s)' 'Frame shift (s)'}), ...
					handles.gtxt.translate('Input function parameters'), 1, {'0.020' '0.001'}, 'on');
if isempty(dlg_out)
	return
end
pause(0.2);
dlg_out = cellfun(@str2double, dlg_out, 'UniformOutput',false);
try
	if matlabpool('size')==0
		local_jm=findResource('scheduler','type','local');
		if local_jm.ClusterSize>1 && ... 
			strcmp(questdlg(handles.gtxt.translate({'No matlabpool opened' ...
				'Matlabpool usage can significantly reduce analysis time.' ...
				'Open local matlabpool?'}),handles.gtxt.translate('Parallel computations'), ...
				handles.gtxt.translate('Yes'),handles.gtxt.translate('No'),handles.gtxt.translate('Yes')), ...
				handles.gtxt.translate('Yes'))
			matlabpool('local');
		end
		pause(0.2);
	end
catch
end
slsauto_lpc_analyse(struct('snd_filename',get(handles.snd_filename_edit,'String')), dlg_out{:});


% --- Executes on button press in lpcsynth_btn.
function lpcsynth_btn_Callback(hObject, eventdata, handles)
% hObject    handle to lpcsynth_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dlg_out = inputdlg(	handles.gtxt.translate({'The output file length (s)' 'Type of synthesis block boundary (v|u|a)'}), ...
					handles.gtxt.translate('Input function parameters'), 1, {'60' 'v'}, 'on');
if isempty(dlg_out)
	return
end
pause(0.2);
slsauto_lpc_synth(struct('snd_filename',get(handles.snd_filename_edit,'String')), str2double(dlg_out{1}), dlg_out{2});
