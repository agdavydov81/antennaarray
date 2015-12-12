function SLS_main(file_name_in, synth_time, file_name_out)
    if nargin<1
        [file_name,file_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
        if file_name==0
            return;
        end
        file_name_in=fullfile(file_path,file_name);
    end

    if nargin<2;    synth_time=10;                  end

    [x,fs]=wavread(file_name_in);
	x(:,2:end)=[];

    segments_borders=SLS_segment_wave_by_specrum(x, fs, 0.070, 0.75, 1);
%{
    [file_name,file_path]=uiputfile({'*.wav','Wave files (*.wav)'},'Выберите файл для сохранения исходного рассегментированного файла',[file_name_in(1:end-4), '_synth', file_name_in(end-3:end)]);
    if file_name
        file_name_marks=fullfile(file_path,file_name);
        wavwrite(x, fs, 16, file_name_marks);
		wav_markers_write(file_name_marks, segments_borders);
    end
%}
    segmengs_types=SLS_classify_segments(x, fs, segments_borders);

    segmengs_statistics=SLS_make_statistic(x, fs, segments_borders, segmengs_types);

    [synth_wave,synth_marks]=SLS_generate_wave(x, fs, segments_borders, segmengs_types, segmengs_statistics, synth_time);

    if nargin<3
        [file_name,file_path]=uiputfile({'*.wav','Wave files (*.wav)'},'Выберите файл для сохранения',[file_name_in(1:end-4), '_synth', file_name_in(end-3:end)]);
        if file_name==0
            return;
        end
        file_name_out=fullfile(file_path,file_name);
    end
    wavwrite(synth_wave, fs, 16, file_name_out);
    wav_markers_write(file_name_out, synth_marks);
end

function segments_borders=SLS_segment_wave_by_specrum(x, fs, min_segment_size, max_dist_percent, display_debug)
    frame_size=0.025;               % sec.
    frame_step=0.001;               % sec.
    spectrum_change_frequency=50;   % Hz

    min_segment_size=round(min_segment_size/frame_step);
    samples_window=round(frame_size*fs);
    samples_overlap=round((frame_size-frame_step)*fs);
    fft_size=2^ceil(log2(samples_window));
    [spec_fft, spec_freq, spec_time, spec_psd] = spectrogram(x, samples_window, samples_overlap, fft_size, fs);
    spec_aud = audspec(spec_psd, fs, 18, 'bark', bark2hz(1), bark2hz(19), 1, 1);
    spec_plp = postaud(spec_aud, bark2hz(19), 'bark');
    dist_raw=zeros(1,size(spec_plp,2)-1);
    for i=1:size(spec_plp,2)-1
        dist_raw(i)=mean(abs(spec_plp(:,i+1)-spec_plp(:,i)));
    end
    if spectrum_change_frequency<1/frame_step
        dist_filt=filter2way(fir1(512,spectrum_change_frequency*frame_step),1,dist_raw');
    end
    dist_norm=zeros(size(dist_filt));
	for i=1:length(dist_norm)
		dist_norm(i)=dist_filt(i)/max(dist_filt(max(i-min_segment_size,1):min(i+min_segment_size,end)));
	end
    segments_borders=[];
    max_dist=max_dist_percent*max(dist_norm);
    for i=1:length(dist_norm)
        if dist_norm(i)>max_dist && dist_norm(i)>max(dist_norm(max(i-min_segment_size,1):i-1)) && dist_norm(i)>=max(dist_norm(i+1:min(i+min_segment_size,end)))
            segments_borders(end+1)=i;
        end
    end
    segments_borders=round(spec_time(segments_borders)*fs);

    if display_debug
        scr_sz=get(0,'ScreenSize');
        figure('NumberTitle', 'off', 'Name', 'Segmentation stage', 'Position', scr_sz);

        subplot(6,1,[1 2]);
        plot((1:length(x))/fs,x);
        grid on;
        lim_y=ylim();
        for i=1:length(segments_borders)
            line([segments_borders(i) segments_borders(i)]/fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([1/fs length(x)/fs lim_y(1) lim_y(2)]);

        subplot(6,1,[3 4]);
        surf(spec_time,bark2hz(1:size(spec_plp,1)),10*log10(spec_plp),'EdgeColor','none');
        spec_plp_max=max(max(spec_plp));
        for i=1:length(segments_borders)
            line([segments_borders(i) segments_borders(i)]/fs, [bark2hz(1) bark2hz(18)], [spec_plp_max spec_plp_max], 'Color', 'r');
        end
        view([0 90]);
        axis([1/fs, length(x)/fs, bark2hz(1), bark2hz(18)]);

        subplot(6,1,[5 6]);
        plot(spec_time(1:end-1),dist_raw./max(dist_raw),'g', spec_time(1:end-1),dist_filt./max(dist_filt),'b', spec_time(1:end-1),dist_norm,'r');
        grid on;
        lim_y=ylim();
        for i=1:length(segments_borders)
            line([segments_borders(i) segments_borders(i)]/fs, [lim_y(1) lim_y(2)], 'Color', 'r');
        end
        axis([1/fs length(x)/fs lim_y(1) lim_y(2)]);
    end
end

function segmengs_types=SLS_classify_segments(x,fs,segments_borders)
    segmengs_types=1:length(segments_borders)-1;
end

function segmengs_statistics=SLS_make_statistic(x,fs,segments_borders,segmengs_types)
    vocab_size=max(segmengs_types)+1;
    segmengs_statistics=zeros(vocab_size, vocab_size);

    segmengs_statistics(vocab_size,segmengs_types(1))=1;
    for i=2:length(segmengs_types)
        segmengs_statistics(segmengs_types(i-1), segmengs_types(i)) = segmengs_statistics(segmengs_types(i-1), segmengs_types(i)) + 1;
    end
    segmengs_statistics(segmengs_types(end), end) = segmengs_statistics(segmengs_types(end), end) + 1;

    for i=1:size(segmengs_statistics)
        segmengs_statistics(i,:) = segmengs_statistics(i,:)/sum(segmengs_statistics(i,:));
    end
end

function [synth_wave, synth_marks]=SLS_generate_wave(x, fs, segments_borders, segmengs_types, segmengs_statistics, synth_time)
    synth_wave=[];
    synth_marks=[];
    last_element=size(segmengs_statistics,1);
    while length(synth_wave)<synth_time*fs
        distrib=segmengs_statistics(last_element, :);
        sum=0;
        for i=1:length(distrib)
            sum=sum+distrib(i);
            distrib(i)=sum;
        end
        type=1;
        r_val=rand(1);
        while r_val>distrib(type)
            type=type+1;
        end
        last_element=type;

        if type>=size(segmengs_statistics,1)
            continue;
        end
        type_bord=find(segmengs_types==type);
        type_bord=type_bord(1);
        synth_wave = [synth_wave; x(segments_borders(type_bord):segments_borders(type_bord+1)-1)];
        synth_marks(end+1) = length(synth_wave)-1;
    end
end

function y=filter2way(b,a,x)
    max_delay=round(2*max(grpdelay(b,a,1024)));
    y=filter(b,a,[x; zeros(max_delay,size(x,2))]);
    y=filter(b,a,y(end:-1:1));
    y=y(end:-1:max_delay+1);
end
