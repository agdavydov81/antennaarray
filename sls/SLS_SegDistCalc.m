function [segments, dist_raw, dist_filt, dist_norm]=SLS_SegDistCalc(vectors)
    global file_info;
    global seg_config;
    min_segment_size=round( seg_config.seg_min_len / seg_config.frame_step );
    dist_len=size(vectors,1)-1;
    dist_raw=zeros(dist_len,1);
    dist_avr_time=max(1,round(seg_config.dist_avr_time/seg_config.frame_step));
    switch(seg_config.dist_func)
        case 'cityblock'
            for i=1:dist_len
                dv=0;
                dn=min([dist_avr_time, i, size(vectors,1)-i]);
                for j=1:dn
                    dv=dv+sum(abs(vectors(i+j,:)-vectors(i-j+1,:)));
                end
                dist_raw(i)=dv/dn;
            end
        case 'euclidean'
            for i=1:dist_len
                dv=0;
                dn=min([dist_avr_time, i, size(vectors,1)-i]);
                for j=1:dn
                    dv=dv+sqrt(sum((vectors(i+j,:)-vectors(i-j+1,:)).^2));
                end
                dist_raw(i)=dv/dn;
            end
        case 'seuclidean'
            vectors_var=var(vectors);
            vectors_var=1./vectors_var;
            for i=1:dist_len
                dv=0;
                dn=min([dist_avr_time, i, size(vectors,1)-i]);
                for j=1:dn
                    dv=dv+sqrt(sum(vectors_var.*(vectors(i+j,:)-vectors(i-j+1,:)).^2));
                end
                dist_raw(i)=dv/dn;
            end
        case 'mahalanobis'
            vectors_cov=cov(vectors);
            vectors_cov=vectors_cov^-1;
            for i=1:dist_len
                dv=0;
                dn=min([dist_avr_time, i, size(vectors,1)-i]);
                for j=1:dn
                    dval=vectors(i+j,:)-vectors(i-j+1,:);
                    dv=dv+sqrt(dval*vectors_cov*dval');
                end
                dist_raw(i)=dv/dn;
            end
        case 'minkowski'
            for i=1:dist_len
                dv=0;
                dn=min([dist_avr_time, i, size(vectors,1)-i]);
                for j=1:dn
                    dv=dv+sum(abs(vectors(i+j,:)-vectors(i-j+1,:)).^seg_config.dist_minkowski_param).^(1/seg_config.dist_minkowski_param);
                end
                dist_raw(i)=dv/dn;
            end
        otherwise
            dist_array=squareform(pdist(vectors, seg_config.dist_func, seg_config.dist_minkowski_param));
            for i=1:dist_len
                dist_raw(i)=dist_array(i,i+1);
            end
    end
    if seg_config.spectrum_max_change_freq<1/seg_config.frame_step
        dist_filt=filter2way(fir1(512,seg_config.spectrum_max_change_freq*seg_config.frame_step),1,dist_raw);
    else
        dist_filt=dist_raw;
    end

    [path,name]=fileparts(file_info.name);
    fh=fopen(fullfile(path, [name '_spectrum.txt']),'wt');
    fprintf(fh, '%f\t%f\t%f\n', [(0:length(dist_raw)-1)*seg_config.frame_step+seg_config.frame_size/2; dist_raw'./max(dist_raw); dist_filt'./max(dist_filt)]);
    fclose(fh);

    dist_norm=zeros(size(dist_filt));
	for i=1:length(dist_norm)
		dist_norm(i)=dist_filt(i)/max(dist_filt(max(i-min_segment_size,1):min(i+min_segment_size,end)));
	end
    segments=[];
    max_dist=seg_config.seg_dist_threshold*max(dist_norm);
    for i=1:length(dist_norm)
        if dist_norm(i)>max_dist && dist_norm(i)>max(dist_norm(max(i-min_segment_size,1):i-1)) && dist_norm(i)>=max(dist_norm(i+1:min(i+min_segment_size,end)))
            segments(end+1)=i;
        end
    end
end

function y=filter2way(b,a,x)
    max_delay=round(2*max(grpdelay(b,a,1024)));
    y=filter(b,a,[x; zeros(max_delay,size(x,2))]);
    y=filter(b,a,y(end:-1:1));
    y=y(end:-1:max_delay+1);
end
