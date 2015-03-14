function base=vnm_meta_isnan(base, alg, algs) %#ok<INUSD>
	if not(isfield(alg,'verbose'))
		alg.verbose=false;
	end
	if not(isfield(alg,'isremove'))
		alg.isremove=true;
	end
	
	obs_type=fieldnames(base(1).data{1});

	for bi=1:numel(base)
		kill_files=false(size(base(bi).data));
		for fi=1:numel(base(bi).data)
			for oi=1:numel(obs_type)
				cur_obs=base(bi).data{fi}.(obs_type{oi});
				anynan=any(isnan(cur_obs(:)) | isinf(cur_obs(:)));

				if anynan
					if alg.verbose
						if alg.isremove
							fprintf('Warning: file [%d] "%s" was removed from base [%d] "%s" because contain NAN or INF values in field "%s".\n', fi,base(bi).data{fi}.file_name, bi,base(bi).class, obs_type{oi});
						else
							fprintf('Warning: file [%d] "%s" in base [%d] "%s" contain NAN or INF values in field "%s".\n', fi,base(bi).data{fi}.file_name, bi,base(bi).class, obs_type{oi});
						end
					end

					if alg.isremove
						kill_files(fi)=true;
					end
					break;
				end
			end
		end
		base(bi).data(kill_files)=[];
	end
end
