function varargout = photo_proc(varargin)
% PHOTO_PROC MATLAB code for photo_proc.fig
%      PHOTO_PROC, by itself, creates a new PHOTO_PROC or raises the existing
%      singleton*.
%
%      H = PHOTO_PROC returns the handle to a new PHOTO_PROC or the handle to
%      the existing singleton*.
%
%      PHOTO_PROC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHOTO_PROC.M with the given input arguments.
%
%      PHOTO_PROC('Property','Value',...) creates a new PHOTO_PROC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before photo_proc_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to photo_proc_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help photo_proc

% Last Modified by GUIDE v2.5 29-Mar-2014 17:35:10

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @photo_proc_OpeningFcn, ...
                   'gui_OutputFcn',  @photo_proc_OutputFcn, ...
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


% --- Executes just before photo_proc is made visible.
function photo_proc_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to photo_proc (see VARARGIN)

% Choose default command line output for photo_proc
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes photo_proc wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = photo_proc_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btn_open.
function btn_open_Callback(hObject, eventdata, handles)
% hObject    handle to btn_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	default_name = '';
	if isfield(handles,'filename')
		default_name = handles.filename;
	end
	[dlg_name,dlg_path]=uigetfile({'*.jpg','Jpeg files (*.jpg)'},'Выберите файл для обработки',default_name);
	if dlg_name==0
		return;
	end
	handles.filename = fullfile(dlg_path,dlg_name);
	im = imread(handles.filename);
	if size(im,3)==1
		im = repmat(im, [1 1 3]);
	end
	im = im(end:-1:1,:,:);
	image(im, 'Parent',handles.axes_photo);
	axis('xy');
	handles.im = im;
	handles.line = line([0 0],[0 0],'Color','r','LineWidth',1);
	handles.corners = {};
	guidata(hObject, handles);

	
% --- Executes on button press in btn_crop.
function btn_crop_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1


% --- Executes on button press in btn_leftdown.
function btn_leftdown_Callback(hObject, eventdata, handles)
% hObject    handle to btn_leftdown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btn_leftdown


% --- Executes on button press in btn_corner.
function btn_corner_Callback(hObject, eventdata, handles)
% hObject    handle to btn_corner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btn_corner


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	if ~isfield(handles,'line')
		return
	end

	cur_pt = get(hObject, 'CurrentPoint');
	ax_pos = get(handles.axes_photo,'Position');
	if  cur_pt(1)<ax_pos(1) || cur_pt(1)>ax_pos(1)+ax_pos(3) || ...
		cur_pt(2)<ax_pos(2) || cur_pt(2)>ax_pos(2)+ax_pos(4)
			return
	end
	ax = axis();
	cur_pt(1) = (cur_pt(1)-ax_pos(1))*(ax(2)-ax(1))/ax_pos(3);
	cur_pt(2) = (cur_pt(2)-ax_pos(2))*(ax(4)-ax(3))/ax_pos(4);
	handles.rect_pt = [cur_pt cur_pt+1];
	guidata(hObject, handles);

	set(handles.line, 'XData',handles.rect_pt([1 3 3 1 1]),'YData',handles.rect_pt([2 2 4 4 2]));


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	if ~isfield(handles,'line')
		return
	end

	if isfield(handles,'rect_pt')
		cur_pt = get(hObject, 'CurrentPoint');
		ax_pos = get(handles.axes_photo,'Position');
		if  cur_pt(1)<ax_pos(1) || cur_pt(1)>ax_pos(1)+ax_pos(3) || ...
			cur_pt(2)<ax_pos(2) || cur_pt(2)>ax_pos(2)+ax_pos(4)
				return
		end
		ax = axis();
		cur_pt(1) = (cur_pt(1)-ax_pos(1))*(ax(2)-ax(1))/ax_pos(3);
		cur_pt(2) = (cur_pt(2)-ax_pos(2))*(ax(4)-ax(3))/ax_pos(4);
		handles.rect_pt([3 4]) = cur_pt;
		guidata(hObject, handles);

		pp = [handles.rect_pt mean(handles.rect_pt([1 3])) mean(handles.rect_pt([2 4]))];
		set(handles.line, 'XData',pp([1 3 3 1 1 5 5 3 3 1]),'YData',pp([2 2 4 4 2 2 4 4 6 6]));
	end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	if ~isfield(handles,'rect_pt')
		return
	end

	set(handles.line, 'XData',[0 0 0 0 0],'YData',[0 0 0 0 0]);
	rect_pt = round(handles.rect_pt);
	rect_pt([1 3]) = sort(rect_pt([1 3]));
	rect_pt([2 4]) = sort(rect_pt([2 4]));
 	rect_pt([1 2]) = max([rect_pt([1 2]); [1 1]]);
 	rect_pt([3 4]) = min([rect_pt([3 4]); size(handles.im,2), size(handles.im,1)]);
	handles = rmfield(handles,'rect_pt');
	guidata(hObject, handles);

	if get(handles.btn_crop,'Value')
		set(handles.btn_crop,'Value',0);
		handles.im = handles.im(rect_pt(2):rect_pt(4), rect_pt(1):rect_pt(3), :);
		image(handles.im, 'Parent',handles.axes_photo);
		axis('xy');
		handles.line = line([0 0],[0 0],'Color','r','LineWidth',1);
		guidata(hObject, handles);
	end

	if get(handles.btn_leftdown,'Value')
		set(handles.btn_leftdown,'Value', 0);
		cur_pt = round((rect_pt([1 2]) + rect_pt([3 4]))/2);
		im_sz = size(handles.im);
		guidata(hObject, handles);
		switch double(cur_pt(1)>im_sz(2)/2)*10 + double(cur_pt(2)>im_sz(1)/2)
			case 00
				rot_angle = 0;
			case 01
				rot_angle = -90;
			case 11
				rot_angle = 180;
			case 10
				rot_angle = 90;
			otherwise
				error('Somethis is wrong.');
		end
		if rot_angle~=0
			handles.im = imrotate(handles.im, rot_angle);
			image(handles.im, 'Parent',handles.axes_photo);
			axis('xy');
			handles.line = line([0 0],[0 0],'Color','r','LineWidth',1);
			guidata(hObject, handles);
		end
		draw_corners(handles);
	end
	
	if get(handles.btn_corner,'Value')
		set(handles.btn_corner,'Value', 0);
		cur_pt = round((rect_pt([1 2]) + rect_pt([3 4]))/2);
		handles.corners{end+1} = cur_pt;
		guidata(hObject, handles);
		draw_corners(handles);
	end
	
	
function draw_corners(handles)
	for ci = handles.corners
		line('XData',ci{1}(1)+50*[-1 1 1 -1 -1 0 0 1 1 -1],'YData',ci{1}(2)+50*[-1 -1 1 1 -1 -1 1 1 0 0], 'Color','m','LineWidth',1);
	end

	
% --- Executes on button press in btn_save.
function btn_save_Callback(hObject, eventdata, handles)
% hObject    handle to btn_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	[pathstr, name] = fileparts(handles.filename);
	cnt = 1;
	while 1
		cur_filename = fullfile(pathstr,sprintf('%s_%02d.jpg',name,cnt));
		if ~exist(cur_filename,'file')
			break
		end
		cnt = cnt + 1;
	end

	[dlg_name,dlg_path]=uiputfile({'*.jpg','Jpeg files (*.jpg)'},'Выберите файл для сохранения',cur_filename);
	if dlg_name==0
		return;
	end
	imwrite(handles.im(end:-1:1,:,:), fullfile(dlg_path,dlg_name),'jpg','Quality',95);


% --- Executes on button press in btn_corners_remove.
function btn_corners_remove_Callback(hObject, eventdata, handles)
% hObject    handle to btn_corners_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	handles.corners = {};
	image(handles.im, 'Parent',handles.axes_photo);
	axis('xy');
	handles.line = line([0 0],[0 0],'Color','r','LineWidth',1);
	guidata(hObject, handles);
	draw_corners(handles);


% --- Executes on button press in btn_rotate.
function btn_rotate_Callback(hObject, eventdata, handles)
% hObject    handle to btn_rotate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
	pt0 = find_corner(handles,0,0);
	pt1 = find_corner(handles,0,1);
	pt3 = find_corner(handles,1,1);
	pt2 = find_corner(handles,1,0);

	angles = [find_angle(pt0, pt2) find_angle(pt1, pt3) find_angle(pt2, pt3)-90 find_angle(pt0, pt1)-90];
	if ~isempty(angles)
		handles.im = imrotate(handles.im, mean(angles), 'bilinear');
		image(handles.im, 'Parent',handles.axes_photo);
		axis('xy');
		handles.line = line([0 0],[0 0],'Color','r','LineWidth',1);
		guidata(hObject, handles);
		btn_corners_remove_Callback(hObject, eventdata, handles);
	end


function pt = find_corner(handles,x_up,y_up)
	cor = vertcat(handles.corners{:});
	ind_x = cor(:,1) < size(handles.im,2)/2;
	ind_y = cor(:,2) < size(handles.im,1)/2;
	if x_up
		ind_x = not(ind_x);
	end
	if y_up
		ind_y = not(ind_y);
	end
	pt = cor(ind_x & ind_y, :);


function a = find_angle(pt0, pt2)
	if isempty(pt0) || isempty(pt2)
		a = [];
	else
		dd = pt2-pt0;
		a = atan2(dd(2), dd(1))*180/pi;
	end
