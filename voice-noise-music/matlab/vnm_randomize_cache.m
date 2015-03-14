function vnm_randomize_cache(cache_path_in, cache_path_out)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.mat','MATLAB files (*.mat)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		cache_path_in=fullfile(dlg_path,dlg_name);
	end
	if nargin<2
		[cur_path,cur_name,cur_ext]=fileparts(cache_path_in);
		[dlg_name,dlg_path]=uiputfile({'*.mat','MATLAB files (*.mat)'}, 'Выберите файл для сохранения', ...
										fullfile(cur_path,[cur_name '_randn',cur_ext]));
		if dlg_name==0
			return
		end
		cache_path_out=fullfile(dlg_path, dlg_name);
	end
	
	cache = load(cache_path_in);

	%% Open local matlabpool
	do_close_pool = false;
	if matlabpool('size')==0
		local_jm=findResource('scheduler','type','local');
		if local_jm.ClusterSize>1
			matlabpool('local');
			do_close_pool = true;
		end
	end
	
	%% Replace all fields in cache to random values
	for bi=1:numel(cache.base)
		if do_close_pool
			base_data = cache.base(bi).data;
			parfor fi=1:numel(base_data)
				base_data{fi} = randomize_object(base_data{fi});
			end
			cache.base(bi).data = base_data;
		else
			for fi=1:numel(base_data)
				base_data{fi} = randomize_object(base_data{fi});
			end
		end
	end

	%% Close opened matlabpool
	if do_close_pool
		matlabpool('close');
	end

	%% Move variables from 'cache' variable to workspace for saving
	cache_vars = fieldnames(cache);
	for ii = 1:length(cache_vars)
		eval([cache_vars{ii} '=cache.' cache_vars{ii} ';']);
	end

	save(cache_path_out,cache_vars{:},'-v7.3');
end

function cur_obj = randomize_object(cur_obj)
	cur_fn = fieldnames(cur_obj);

	% Do not replace not_numeric, 'time' and 'file_range' fields
	cur_fn(cellfun(@(x) not(isnumeric(cur_obj.(x))), cur_fn))=[];
	cur_fn(strcmp('time',cur_fn))=[];
	cur_fn(strcmp('file_range',cur_fn))=[];

	for fni=1:numel(cur_fn)
		cur_obj.(cur_fn{fni}) = randn(size(cur_obj.(cur_fn{fni})),class(cur_obj.(cur_fn{fni})));
	end
end
