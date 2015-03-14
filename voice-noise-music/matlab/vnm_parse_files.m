function flist=vnm_parse_files(flist, alg)
	if isempty(flist)
		return;
	end
	if isfield(alg.obs_general,'skip_parsing') && alg.obs_general.skip_parsing
		return;
	end

	fs=alg.obs_general.fs;
	snr=inf;
	if isfield(alg.obs_general,'snr')
		snr=alg.obs_general.snr;
	end
	preemphasis=0;
	if isfield(alg.obs_general,'preemphasis') && alg.obs_general.preemphasis>0
		preemphasis=alg.obs_general.preemphasis;
	end
	filt_ord=0;
	filt_b=[];
	filt_a=[];
	if isfield(alg.obs_general,'filter') && alg.obs_general.filter.order>0
		filt_band_lo=alg.obs_general.filter.band(1);
		filt_band_hi=alg.obs_general.filter.band(2);
		filt_ord=alg.obs_general.filter.order;

		if filt_band_hi>=fs/2-100
			filt_info = { filt_band_lo*2/fs, 'high' };
		else
			filt_info = { [filt_band_lo filt_band_hi]*2/fs };
		end

		while filt_ord>0
			[filt_b, filt_a]=butter(filt_ord, filt_info{:});
			if isfilterstable(filt_a)
				break;
			else
				filt_ord=filt_ord-1;
			end
		end
		if filt_ord~=alg.obs_general.filter.order
			warning('vnm:vnm_parse_files:fiter_order', 'Filter order was decreased from %d to %d.', alg.obs_general.filter.order, filt_ord);
		end
	end

	rand_ampl=[];
	if isfield(alg.obs_general,'rand_ampl')
		rand_ampl=alg.obs_general.rand_ampl;
	end

	if isfield(alg,'matlabpool')
		parfor i=1:length(flist) % parfor
			flist{i}=parfor_for_body(flist{i}, fs, rand_ampl, snr, preemphasis, filt_ord, filt_b, filt_a, alg);
		end
	else
		for i=1:length(flist)
			flist{i}=parfor_for_body(flist{i}, fs, rand_ampl, snr, preemphasis, filt_ord, filt_b, filt_a, alg);
		end
	end
end

function flist_i=parfor_for_body(flist_i, fs, rand_ampl, snr, preemphasis, filt_ord, filt_b, filt_a, alg)
	if not(isfield(alg,'obs'))
		return;
	end

	[cur_x, cur_fs]=vb_readwav(flist_i.file_name);
	if isempty(cur_x)
		cur_x=nan(100,1);
		disp(sprintf('File %s have no data.', flist_i.file_name)); %#ok<DSPS>
	end

	if size(cur_x,2)>1
		if isfield(alg.obs_general,'load_file') && isfield(alg.obs_general.load_file,'channel')
			if isnumeric(alg.obs_general.load_file.channel)
				if alg.obs_general.load_file.channel>size(cur_x,2)
					error('vnm:parse_files:load_file', 'No channel %d in file %s. File have only %d channels.', alg.obs_general.load_file.channel, flist_i.file_name, size(cur_x,2));
				end
				cur_x=cur_x(:,alg.obs_general.load_file.channel);
			else
				switch alg.obs_general.load_file.channel
					case 'merge'
						cur_x=sum(cur_x,2);
					case 'concatenate'
						cur_x=cur_x(:);
					otherwise
						error('vnm:parse_files:load_file', 'Unknown load file option.');
				end
			end
		else
			cur_x(:,2:end)=[];
		end
	end

	if isfield(flist_i, 'file_range')
        file_range=[max(1,round(flist_i.file_range(1)*cur_fs))  min(size(cur_x,1),round(flist_i.file_range(2)*cur_fs))];
		cur_x=cur_x(file_range(1):file_range(2));
%		flist_i=rmfield(flist_i,'file_range');
	end
	if cur_fs~=fs
		cur_x=resample(cur_x, fs, cur_fs);
	end

	if not(isempty(rand_ampl))
		ramp=1;
		if isa(rand_ampl,'logical')
			if rand_ampl %% Старое поведение: усиление от 0.1 до 10 раз
				ramp=20*(rand-0.5);
				if ramp>=0
					ramp=ramp+1;
				else
					ramp=1/(-ramp+1);
				end
			end
		else
			ramp=rand_ampl(randi(numel(rand_ampl),1));
		end
		if ramp~=1
			cur_x=cur_x*ramp;
		end
	end

	if not(isinf(snr))
		cur_x=awgn(cur_x, snr, 'measured');
	end
	if preemphasis>0
		cur_x=filter([1 -preemphasis], 1, cur_x);
	end
	if filt_ord>0
		if size(cur_x,1)<length(filt_b)*3/2
			cur_x=filter(filt_b, filt_a, cur_x);
		else
			cur_x=filtfilt(filt_b, filt_a, cur_x);
		end
	end

	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
	obs_sz=fix((size(cur_x,1)-fr_sz(2))/fr_sz(1)+1);

	for ai=1:length(alg.obs)
		if exist('file_range','var')
			fname=sprintf('%s*%d:%d',flist_i.file_name,file_range(1),file_range(2));
		else
			fname=flist_i.file_name;
		end
		flist_i.(alg.obs(ai).type)=feval(['vnm_obs_' alg.obs(ai).type], cur_x, alg.obs(ai).params, alg, struct('file_name',fname, 'fr_sz',fr_sz, 'obs_sz',obs_sz));
		flist_i.(alg.obs(ai).type)=feval(alg.obs_general.precision,flist_i.(alg.obs(ai).type));
	end
end
