function [segments, dist_raw, dist_filt, dist_norm, dist_time]=SLS_SegLSF(file)
    global seg_config;
    LPC_order=round(file.fs/1000)+4;

    win_size=round(seg_config.frame_size*file.fs);
    win_step=round(seg_config.frame_step*file.fs);
    
    file_x=fftfilt([1 -0.95],file.x);

    LSF_tracks=zeros(LPC_order, fix((length(file_x)-win_size)/win_step));
    for win_ind=1:size(LSF_tracks,2)
        cur_wave=file_x( (win_ind-1)*win_step + (1:win_size));
        cur_wave=cur_wave.*hamming(length(cur_wave));
        cur_A=aryule(cur_wave,LPC_order);
        cur_LSF=poly2lsf(cur_A);
        LSF_tracks(:,win_ind)=cur_LSF;
    end

    [segments, dist_raw, dist_filt, dist_norm]=SLS_SegDistCalc(LSF_tracks');
    dist_time=(((1:length(dist_raw))-0.5)*win_step+win_size/2)/file.fs;
    segments=round(dist_time(segments)*file.fs);

    if seg_config.display_debug
        subplot(6,1,[3 4]);

        freq_resolution=128;
        LP_spectrum=zeros(freq_resolution, size(LSF_tracks,2));
        for win_ind=1:size(LSF_tracks,2)
            cur_LSF=LSF_tracks(:,win_ind);
            cur_A=lsf2poly(cur_LSF);
            cur_H=freqz(1, cur_A, freq_resolution);
            cur_H=20*log10(abs(cur_H));
            LP_spectrum(:,win_ind)=cur_H;
        end

        LP_spectrum_freq=(0:freq_resolution-1)*file.fs/(2*freq_resolution);
        LP_spectrum_time=((0:size(LSF_tracks,2)-1)*win_step+win_size/2)/file.fs;
        surf(LP_spectrum_time, LP_spectrum_freq, LP_spectrum, 'EdgeColor','none');
        view(0,90);
        
        LP_spectrum_max=max(max(LP_spectrum));
        for i=1:size(LSF_tracks,1)
            line(LP_spectrum_time, LSF_tracks(i,:)*file.fs/(2*pi), ones(size(LP_spectrum_time))*(LP_spectrum_max+1), 'Color','k');
        end

        y_lim=(freq_resolution-1)*file.fs/(2*freq_resolution);
        for i=1:length(segments)
            line([segments(i) segments(i)]/file.fs, [0 y_lim], [LP_spectrum_max LP_spectrum_max]+2, 'Color','r');
        end
        axis([0, length(file_x)/file.fs, 0, y_lim]);
        ylabel('LSF спектр сигнала');
        zoom xon;
    end
end
