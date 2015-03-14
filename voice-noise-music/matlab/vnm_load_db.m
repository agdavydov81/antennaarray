function base=vnm_load_db(db_path, db_type, alg)
	cache.obs= struct('file',['vnm_cache_' db_type '_obs.mat'],  'is_loaded',false);
	cache.meta=struct('file',['vnm_cache_' db_type '_meta.mat'], 'is_loaded',false);

	auto_load_cache = isfield(alg.obs_general,'auto_load_cache') && alg.obs_general.auto_load_cache;

	if exist(cache.meta.file,'file')
		cache_val=load(cache.meta.file);
		if	size(cache_val.base,2)==1 && ...
			isequal(alg.obs_general, cache_val.alg.obs_general) && ...
			(isfield(alg,'obs') && isfield(cache_val.alg,'obs') && isequal(alg.obs, cache_val.alg.obs) || ~isfield(alg,'obs') && ~isfield(cache_val.alg,'obs')) && ...
			isequal(alg.meta_obs, cache_val.alg.meta_obs) && ...
			strcmp(db_path, cache_val.db_path) && ...
			( auto_load_cache || strcmp(questdlg('Open cached meta observations?','Cached results','Yes','No','Yes'),'Yes') )
			base=cache_val.base;
			cache.obs.is_loaded=true;
			cache.meta.is_loaded=true;
		end
		pause(0.2);
	end

	if not(cache.obs.is_loaded) && exist(cache.obs.file,'file')
		cache_val=load(cache.obs.file);
		if	size(cache_val.base,2)==1 && ...
			isequal(alg.obs_general, cache_val.alg.obs_general) && ...
			(isfield(alg,'obs') && isfield(cache_val.alg,'obs') && isequal(alg.obs, cache_val.alg.obs) || ~isfield(alg,'obs') && ~isfield(cache_val.alg,'obs')) && ...
			strcmp(db_path, cache_val.db_path) && ...
			( auto_load_cache || strcmp(questdlg('Open cached raw observations?','Cached results','Yes','No','Yes'),'Yes') )
			base=cache_val.base;
			cache.obs.is_loaded=true;
		end
		pause(0.2);
	end

	if exist('cache_val','var')
		clear('cache_val');
	end

	if not(cache.obs.is_loaded)
		disp('CACHE: raw observations is wrong or not exists. Recalculation ...');
		usepool = isfield(alg,'matlabpool');
		if usepool
			if matlabpool('size')>0
				matlabpool('close');
			end
			matlabpool(alg.matlabpool{:});
		end
		spmd
			addpath_recursive(regexp(path(),'[^;]*','match','once'), 'ignore_dirs',{'\.svn' 'private' 'html' 'fspackage' 'FastICA' 'openEAR'});
			dos(['"' which('matlab_idle.bat') '"']);
		end
		[base alg]=feval(['vnm_parse_' db_type], db_path, alg);
		if usepool
			matlabpool('close');
		end
		save(cache.obs.file,'base','db_path','alg','-v7.3');
	end

	if not(cache.meta.is_loaded)
		disp('CACHE: meta observations is wrong or not exists. Recalculation ...');
		if isfield(alg,'meta_obs')
			for ai=1:length(alg.meta_obs)
				base=feval(['vnm_meta_' alg.meta_obs(ai).type], base, alg.meta_obs(ai).params, alg);
			end
		end
		save(cache.meta.file,'base','db_path','alg','-v7.3');
	end
end
