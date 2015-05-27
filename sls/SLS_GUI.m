function varargout = SLS_GUI(varargin)
    % SLS_GUI M-file for SLS_GUI.fig
    %      SLS_GUI, by itself, creates a new SLS_GUI or raises the existing
    %      singleton*.
    %
    %      H = SLS_GUI returns the handle to a new SLS_GUI or the handle to
    %      the existing singleton*.
    %
    %      SLS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in SLS_GUI.M with the given input arguments.
    %
    %      SLS_GUI('Property','Value',...) creates a new SLS_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before SLS_GUI_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to SLS_GUI_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help SLS_GUI

    % Last Modified by GUIDE v2.5 24-Jan-2009 20:33:22

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @SLS_GUI_OpeningFcn, ...
                       'gui_OutputFcn',  @SLS_GUI_OutputFcn, ...
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
end

% --- Executes just before SLS_GUI is made visible.
function SLS_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
	proj_root=fileparts(mfilename('fullpath'));
	add_paths=strcat([proj_root filesep], [{'auxiliary'} strcat(['thirdpart' filesep], {'rastamat' 'voicebox' 'xml_io_tools'})]);
	addpath(add_paths{:}, '-end');

    handles.output = hObject;
    guidata(hObject, handles);
    global seg_config;
    seg_config.frame_size=              0.050;
    seg_config.frame_step=              0.005;
    seg_config.proc_type=               'PLP';
    seg_config.seg_min_len=             0.070;
    seg_config.seg_dist_threshold=       0.75;
    seg_config.spectrum_max_change_freq=   50;
    seg_config.dist_func=         'euclidean';
    seg_config.dist_avr_time=           0.025;
    seg_config.dist_minkowski_param=        4;
    seg_config.display_debug=               0;
    seg_config=xml_struct_load('SLS_SegCfg.xml',seg_config);

    global class_config;
    class_config.frame_size=              0.050;
    class_config.frame_step=              0.005;
    class_config.proc_type=               'PLP';
    class_config.gen_mean_param=              2;
    class_config.seg_len_factor=              1;
    class_config.dist_func=         'euclidean';
    class_config.dist_minkowski_param=        4;
    class_config.class_num=                  42;
    class_config.class_type=          'K-means';
    class_config.display_debug=               0;
    class_config=xml_struct_load('SLS_ClassCfg.xml',class_config);
end

% --- Outputs from this function are returned to the command line.
function varargout = SLS_GUI_OutputFcn(hObject, eventdata, handles) 
    varargout{1} = handles.output;
end

% --- Executes on button press in btn_FileOpen.
function btn_FileOpen_Callback(hObject, eventdata, handles)
    global file_info;

    [file_name,file_path]=uigetfile({'*.wav','Звуковые файлы (*.wav)';'*.*','Все файлы (*.*)'},'Выберите файл для обработки');
    if file_name==0
        return;
    end
    handles.file.name=fullfile(file_path,file_name);
    [handles.file.x,handles.file.fs_orig]=wavread(handles.file.name);
    handles.file.x(:,2:end)=[];
    handles.file.x=resample(handles.file.x, 11025, handles.file.fs_orig);
    handles.file.fs=11025;
%    handles.file.x=fftfilt([1 -0.95], handles.file.x);
    file_info=sprintf('Файл:%s\nФормат: %d Гц, длинна %.3fс',handles.file.name, handles.file.fs, size(handles.file.x,1)/handles.file.fs);
    set(handles.txt_FileOpen,'String',file_info);
    set(handles.btn_SegmentConfig, 'Enable', 'on');
    set(handles.btn_SegmentDo, 'Enable', 'on');
    handles.segments=round(wav_markers_read(handles.file.name)*handles.file.fs/handles.file.fs_orig);
    set(handles.txt_Segment, 'String', segments_stat(handles.segments, handles.file.fs));
    if ~isempty(handles.segments)
        set(handles.btn_SegmentShow, 'Enable', 'on');
        set(handles.btn_ClassConfig, 'Enable', 'on');
        set(handles.btn_ClassDo, 'Enable', 'on');
    end
    guidata(hObject,handles);
    
    file_info=handles.file;
end

function btn_SegmentConfig_Callback(hObject, eventdata, handles)
    uiwait(SLS_SegCfgDlg());
end

function btn_SegmentDo_Callback(hObject, eventdata, handles)
    global seg_config;
    file=handles.file;
    if seg_config.display_debug
        fig_segm=figure('NumberTitle', 'off', 'Name', [file.name ': этап сегментации'], 'Position', get(0,'ScreenSize'), 'ToolBar','figure');
    end

    switch seg_config.proc_type     % Явное связывание с функциями для корректной сборки mcc
        case 'PLP'
            seg_func=@SLS_SegPLP;
        case 'RastaPLP'
            seg_func=@SLS_SegRastaPLP;
        case 'LSF'
            seg_func=@SLS_SegLSF;
        case 'MFCC'
            seg_func=@SLS_SegMFCC;
        otherwise
            seg_func=str2func(['SLS_Seg' seg_config.proc_type]);
    end
    [handles.segments, dist_raw, dist_filt, dist_norm, dist_time]=seg_func(handles.file);
    wav_markers_write(file.name, round(handles.segments*file.fs_orig/file.fs));
    set(handles.txt_Segment, 'String', segments_stat(handles.segments, handles.file.fs));
    set(handles.btn_SegmentShow, 'Enable', 'on');
    set(handles.btn_ClassConfig, 'Enable', 'on');
    set(handles.btn_ClassDo, 'Enable', 'on');

    if seg_config.display_debug
        subplot(6,1,[1 2]);
        plot((1:length(file.x))/file.fs,file.x);
        grid on;  zoom xon;      ylabel('Cегментируемый сигнал');
        lim_y=ylim();
        for i=1:length(handles.segments)
            line([handles.segments(i) handles.segments(i)]/file.fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([0 length(file.x)/file.fs lim_y(1) lim_y(2)]);

        subplot(6,1,[5 6]);
        plot(dist_time,dist_raw./max(dist_raw),'Color',[0 .5 0]);
        hold on;
        plot(dist_time,dist_filt./max(dist_filt),'b', dist_time,dist_norm,'r');
        hold off;
        legend('Исходное расстояние','Отфильтрованное расстояние','Нормированное расстояние','Location','SouthWest');
        legend boxoff;
        ylabel('Функции расстояния');
        xlabel('Время (с)');
        grid on;    zoom xon;
        lim_y=[0 1];
        for i=1:length(handles.segments)
            line([handles.segments(i) handles.segments(i)]/file.fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([0 length(file.x)/file.fs lim_y(1) lim_y(2)]);

        str_info=['Параметры сегментации: ' struct2str(seg_config) ' Результаты сегментации: ' segments_stat(handles.segments, handles.file.fs)];
        uicontrol('Parent',fig_segm, 'Style','text', 'String',str_info, 'Units','normalized', 'Position',[0 0.95 1 0.05], 'FontSize', 10);
        set(fig_segm, 'Position', get(0,'ScreenSize'));

        set(zoom,'ActionPostCallback',@OnZoomPan);
        set(pan ,'ActionPostCallback',@OnZoomPan);
        zoom xon;
        set(pan, 'Motion', 'horizontal');
    end
    guidata(hObject,handles);
end

function str=struct2str(st)
    st_names = fieldnames(st);
    st_vals =  struct2cell(st);
    str=[];
    for i=1:length(st_names)
        cur_val=st_vals{i};
        if isnumeric(cur_val)
            cur_val=num2str(cur_val);
        else
            cur_val=['"' cur_val '"'];
        end
        str=[str st_names{i} '=' cur_val '; '];
    end
end

function OnZoomPan(hObject,eventdata)
    x_lim=xlim();
    subplot(6,1,[1 2]); xlim(x_lim);
    subplot(6,1,[3 4]); xlim(x_lim);
    subplot(6,1,[5 6]); xlim(x_lim);
end

function seg_str=segments_stat(segments, fs)
    if isempty(segments)
        seg_str=[];
    else
        seg_delay=(segments(2:end)-segments(1:end-1))/fs;
        seg_str=sprintf('Количество сегментов: %d; Средняя длительность: %.3fс; СКО длительности: %.3fс.',length(segments)-1, mean(seg_delay), std(seg_delay));
    end
end

function btn_SegmentShow_Callback(hObject, eventdata, handles)
    figure('NumberTitle', 'off', 'Name', [handles.file.name ': результаты сегментации'], 'Position', get(0,'ScreenSize'));
    plot((1:length(handles.file.x))/handles.file.fs,handles.file.x);
    grid on;  zoom xon;      xlabel('Время (с)');   ylabel('Cегментируемый сигнал');
    set(pan, 'Motion', 'horizontal');
    title(['Результаты сегментации: ' segments_stat(handles.segments, handles.file.fs)]);
    lim_y=ylim();
    for i=1:length(handles.segments)
        line([handles.segments(i) handles.segments(i)]/handles.file.fs, [lim_y(1) lim_y(2)], 'Color', 'r');
    end
    axis([[1 length(handles.file.x)]/handles.file.fs lim_y(1) lim_y(2)]);
end

function btn_ClassConfig_Callback(hObject, eventdata, handles)
    uiwait(SLS_ClassCfgDlg());
end

function btn_ClassDo_Callback(hObject, eventdata, handles)
    global class_config;

    file=handles.file;
    class_points=zeros(length(handles.segments)-1,1);

    samples_window=round(class_config.frame_size*file.fs);
    samples_overlap=round((class_config.frame_size-class_config.frame_step)*file.fs);
    fft_size=2^ceil(log2(samples_window));
    [~, ~, ~, spec_psd] = spectrogram(file.x, samples_window, samples_overlap, fft_size, file.fs);
    spec_=  audspec(spec_psd, file.fs, 18, 'bark', bark2hz(1), bark2hz(19), 1, 1);

    spec_=  exp(rastafilt(log(spec_)));     % Rasta processing

    spec_=  postaud(spec_, bark2hz(19), 'bark');

    lpcas = dolpc(spec_, 12);               % Model order (12) constraint
    spec_ = lpc2spec(lpcas, size(spec_,1));  
    spec_ = 10*log10(spec_');

%    for seg_i=2:length(handles.segments)
%        cur_seg= spec_.x(handles.segments(seg_i-1):handles.segments(seg_i)-1);
%    end
    
%    class_ind=kmeans(class_points, class_config.class_num);

%    if seg_config.display_debug
%        fig_segm=figure('NumberTitle', 'off', 'Name', [file.name ': этап сегментации'], 'Position', get(0,'ScreenSize'));
%    end
%{
    switch seg_config.proc_type     % Явное связывание с функциями для корректной сборки mcc
        case 'PLP'
            seg_func=@SLS_SegPLP;
        case 'RastaPLP'
            seg_func=@SLS_SegRastaPLP;
        case 'LSF'
            seg_func=@SLS_SegLSF;
        case 'MFCC'
            seg_func=@SLS_SegMFCC;
        otherwise
            seg_func=str2func(['SLS_Seg' seg_config.proc_type]);
    end
    [handles.segments, dist_raw, dist_filt, dist_norm, dist_time]=seg_func(handles.file);
    wav_markers_write(file, round(handles.segments*file.fs_orig/file.fs));
    set(handles.txt_Segment, 'String', segments_stat(handles.segments, handles.file.fs));
    set(handles.btn_SegmentShow, 'Enable', 'on');
    set(handles.btn_ClassConfig, 'Enable', 'on');
    set(handles.btn_ClassDo, 'Enable', 'on');

    if seg_config.display_debug
        subplot(6,1,[1 2]);
        plot((1:length(file.x))/file.fs,file.x);
        grid on;  zoom xon;      ylabel('Cегментируемый сигнал');
        lim_y=ylim();
        for i=1:length(handles.segments)
            line([handles.segments(i) handles.segments(i)]/file.fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([0 length(file.x)/file.fs lim_y(1) lim_y(2)]);

        subplot(6,1,[5 6]);
        plot(dist_time,dist_raw./max(dist_raw),'Color',[0 .5 0]);
        hold on;
        plot(dist_time,dist_filt./max(dist_filt),'b', dist_time,dist_norm,'r');
        hold off;
        legend('Исходное расстояние','Отфильтрованное расстояние','Нормированное расстояние','Location','SouthWest');
        legend boxoff;
        ylabel('Функции расстояния');
        xlabel('Время (с)');
        grid on;    zoom xon;
        lim_y=[0 1];
        for i=1:length(handles.segments)
            line([handles.segments(i) handles.segments(i)]/file.fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([0 length(file.x)/file.fs lim_y(1) lim_y(2)]);

        str_info=['Параметры сегментации: ' struct2str(seg_config) ' Результаты сегментации: ' segments_stat(handles.segments, handles.file.fs)];
        uicontrol('Parent',fig_segm, 'Style','text', 'String',str_info, 'Units','normalized', 'Position',[0 0.95 1 0.05], 'FontSize', 10);
        set(fig_segm, 'Position', get(0,'ScreenSize'));
    end
    guidata(hObject,handles);
%}
end

function btn_ClassShow_Callback(hObject, eventdata, handles)
end
