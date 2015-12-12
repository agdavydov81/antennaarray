function [segments, dist_raw, dist_filt, dist_norm, dist_time]=SLS_SegRastaPLP(file)
    global seg_config;

    samples_window=round(seg_config.frame_size*file.fs);
    samples_overlap=round((seg_config.frame_size-seg_config.frame_step)*file.fs);
    fft_size=2^ceil(log2(samples_window));
    [~, ~, spec_time, spec_psd] = spectrogram(file.x, samples_window, samples_overlap, fft_size, file.fs);
    spec_=  rm_audspec(spec_psd, file.fs, 18, 'bark', rm_bark2hz(1), rm_bark2hz(19), 1, 1);

    spec_=  exp(rm_rastafilt(log(spec_)));     % Rasta processing

    spec_=  rm_postaud(spec_, rm_bark2hz(19), 'bark');

    lpcas = rm_dolpc(spec_, 12);               % Model order (12) constraint
    spec_ = rm_lpc2spec(lpcas, size(spec_,1));  

    [segments, dist_raw, dist_filt, dist_norm]=SLS_SegDistCalc(spec_');
    dist_time=spec_time(1:end-1);
    segments=round(dist_time(segments)*file.fs);

    if seg_config.display_debug
        subplot(6,1,[3 4]);
        surf(spec_time,rm_bark2hz(1:size(spec_,1)),10*log10(spec_),'EdgeColor','none');
        spec_max=max(max(spec_));
        for i=1:length(segments)
            line([segments(i) segments(i)]/file.fs, [rm_bark2hz(1) rm_bark2hz(18)], [spec_max spec_max], 'Color', 'r');
        end
        view([0 90]);
        axis([0, length(file.x)/file.fs, rm_bark2hz(1), rm_bark2hz(18)]);
        ylabel('Rasta-PLP спектр сигнала');
        zoom xon;
    end
end
