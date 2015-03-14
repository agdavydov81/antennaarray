function [bestc,bestg,bestcv] = libsvm_modsel(label,inst, matlabpoolarg)
	% Model selection for (lib)SVM by searching for the best param on a 2D grid
	%
    if nargin>2
        usepool = true;
        if matlabpool('size')>0
			matlabpool('close');
        end
        matlabpool(matlabpoolarg{:});
    else
        usepool = false;
    end

    if iscell(label)
        classes = unique(label);
        label = cellfun(@(x) (find(strcmp(classes, x))), label);
    end

	fold = 10;
	c_begin = -5; c_end = 12; c_step = 2;
	g_begin = 3; g_end = -15; g_step = -2;
	bestcv = 0;
	bestc = 2^c_begin;
	bestg = 2^g_begin;
    tic;
    disp('Main loop started');
    
    shift=-mean(inst);
    factor=1./std(inst);

    inst = ( inst+repmat(shift,size(inst,1),1) ) .* repmat(factor,size(inst,1),1);

	for log2c = c_begin:c_step:c_end
        cur_log2g = g_begin:g_step:g_end;
        cur_cv = zeros(1,length(cur_log2g));
        if usepool
            parfor log2g_i = 1:length(cur_log2g)
                cmd = ['-v ',num2str(fold),' -c ',num2str(2^log2c),' -g ',num2str(2^cur_log2g(log2g_i)), ' -h 0 -q'];
                cur_cv(log2g_i) = libsvmtrain(label,inst,cmd);
            end
        else
            for log2g_i = 1:length(cur_log2g)
                cmd = ['-v ',num2str(fold),' -c ',num2str(2^log2c),' -g ',num2str(2^cur_log2g(log2g_i)), ' -h 0 -q'];
                cur_cv(log2g_i) = libsvmtrain(label,inst,cmd);
            end            
        end
        cv = max(cur_cv);
        log2g = 2^cur_log2g(find(cur_cv == max(cur_cv), 1, 'first'));
        if (cv > bestcv) || ((cv == bestcv) && (2^log2c < bestc) && (2^log2g == bestg))
            bestcv = cv; bestc = 2^log2c; bestg = log2g;
        end
        disp(['~' num2str(toc) ' sec passed... Best cv - ' num2str(bestcv) '; Best c - ' num2str(bestc) '; Best g - ' num2str(bestg)]);
	end
    disp(['Completed in ' num2str(toc) ' seconds!']);
    
    if usepool
        matlabpool('close');
    end
end