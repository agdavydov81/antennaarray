function base=vnm_meta_split(base, alg, algs)
	stat_sz=max(1,round([alg.step alg.size]/algs.obs_general.frame_step));
	last_sz=0;
	if isfield(alg,'last') && all(alg.last~=[0 inf -inf nan])
		last_sz=max(1,round(alg.last/algs.obs_general.frame_step));
	end

	for bi=1:size(base,1)
		cut_files=[];
		for fi=1:numel(base(bi).data)
			cur_obj=base(bi).data{fi};
			obs=fields(cur_obj);
			obs_sz=size(cur_obj.time,1);

			non_split_obs_ind=structfun(@(x) size(x,1)~=obs_sz, cur_obj);
			obs_non_split=obs(non_split_obs_ind);
			obs_non_split(strcmp(obs_non_split,'file_name'))=[];
			obs(non_split_obs_ind)=[];

			if last_sz>0
				if obs_sz>last_sz
					cur_ind=obs_sz-last_sz+1:obs_sz;
					for oi=1:length(obs)
						cur_obj.(obs{oi})=cur_obj.(obs{oi})(cur_ind,:);
					end
					if isfield(alg.obs,'power') && isfield(alg.obs.power,'is_normalize') && alg.obs.power.is_normalize
						if isfield(alg.obs.power,'is_db') && alg.obs.power.is_db
							cur_obj.power=cur_obj.power-max(cur_obj.power);
						else
							cur_obj.power=cur_obj.power/max(cur_obj.power);
						end
					end
					cur_obj.file_name=[cur_obj.file_name '#last'];
					base(bi).data{end+1,1}=cur_obj;
				end
			else
				if obs_sz>=sum(stat_sz)
					obs_ind_sz=length(1:stat_sz(1):obs_sz-stat_sz(2)+1);
					for obs_i=1:stat_sz(1):obs_sz-stat_sz(2)+1
						cur_obj=base(bi).data{fi};
						cur_ind=obs_i:obs_i+stat_sz(2)-1;
						for oi=1:length(obs_non_split)
							nsobs_sz=size(cur_obj.(obs_non_split{oi}),1);
							nsobs_rg=min(nsobs_sz,max(1,round(cur_ind([1 end])*nsobs_sz/obs_sz)));
							if nsobs_sz>obs_ind_sz
								cur_obj.(obs_non_split{oi}) = cur_obj.(obs_non_split{oi})(nsobs_rg(1):nsobs_rg(2),:);
							end
						end
						for oi=1:length(obs)
							cur_obj.(obs{oi})=cur_obj.(obs{oi})(cur_ind,:);
						end

						if isfield(algs,'obs')
							obs_power_ind=find(strcmp('power',{algs.obs.type}),1);
							if not(isempty(obs_power_ind))
								alg_obs_power=algs.obs(obs_power_ind).params;
								if isfield(alg_obs_power,'is_normalize') && alg_obs_power.is_normalize
									if isfield(alg_obs_power,'is_db') && alg_obs_power.is_db
										cur_obj.power=cur_obj.power-max(cur_obj.power);
									else
										cur_obj.power=cur_obj.power/max(cur_obj.power);
									end
								end
							end
						end

						cur_obj.file_name=[cur_obj.file_name '#' num2str(obs_i)];
						base(bi).data{end+1,1}=cur_obj;
					end
					cut_files(end+1)=fi; %#ok<AGROW>
				end
			end
		end
		base(bi).data(cut_files)=[];
	end
end
