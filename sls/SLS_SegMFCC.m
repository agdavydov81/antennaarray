function [segments, dist_raw, dist_filt, dist_norm, dist_time]=SLS_SegMFCC(file)
    global seg_config;

    % Convert to MFCCs very close to those genrated by feacalc -sr 22050 -nyq 8000 -dith -hpf -opf htk -delta 0 -plp no -dom cep -com yes -frq mel -filt tri -win 32 -step 16 -cep 20
    mfcc_ = rm_melfcc(file.x*3.3752, file.fs, 'maxfreq',file.fs/2, 'numcep',20, 'nbands',18, 'fbtype','fcmel', 'dcttype',1, 'usecmp',1, 'wintime',seg_config.frame_size, 'hoptime',seg_config.frame_step, 'preemph',0, 'dither',1);

    [segments, dist_raw, dist_filt, dist_norm]=SLS_SegDistCalc(mfcc_');
    win_size=round(seg_config.frame_size*file.fs);
    win_step=round(seg_config.frame_step*file.fs);
    dist_time=(((1:length(dist_raw))-0.5)*win_step+win_size/2)/file.fs;
    segments=round(dist_time(segments)*file.fs);

    if seg_config.display_debug
        subplot(6,1,[3 4]);
        [~,~,spec_stft] = rm_invmelfcc(mfcc_,      file.fs, 'maxfreq',file.fs/2, 'numcep',20, 'nbands',18, 'fbtype','fcmel', 'dcttype',1, 'usecmp',1, 'wintime',seg_config.frame_size, 'hoptime',seg_config.frame_step, 'preemph',0, 'dither',1);
        spec_=10*log10(spec_stft);
        surf(((0:size(spec_,2)-1)*win_step+win_size/2)/file.fs, (0:size(spec_,1)-1)*file.fs/(2*size(spec_,1)), spec_,'EdgeColor','none');
        view([0 90]);
        spec_max=max(max(spec_));
        y_lim=(size(spec_,1)-1)*file.fs/(2*size(spec_,1));
        for i=1:length(segments)
            line([segments(i) segments(i)]/file.fs, [1 y_lim], [spec_max spec_max], 'Color', 'r');
        end
        axis([0, length(file.x)/file.fs, 0, y_lim]);
        ylabel('MFCC спектр сигнала');
        zoom xon;
    end
end
