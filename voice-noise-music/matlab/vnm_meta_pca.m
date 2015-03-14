function base=vnm_meta_pca(base, alg, algs) %#ok<INUSD>
	%% Collect all observations
	all_obs={};
	for base_i=1:size(base,1)
		if isfield(alg, 'obs_make')
			cur_obs=cellfun(@(x) make_file_obs(x, alg.obs_make), base(base_i).data, 'UniformOutput',false);
		else
			cur_obs=base(base_i).data;
		end
		all_obs=[all_obs; cur_obs]; %#ok<AGROW>
	end

	all_obs=cell2mat(all_obs);

	%% Remove some observation types
	all_obs=remove_fields(all_obs, alg);

	%% Make observation 'name#channel' strings in all_names variable
	obs_name=fieldnames(all_obs);
	obs_sz_name=obs_name{1};
	all_obs_sz=arrayfun(@(x) size(x.(obs_sz_name),1), all_obs);

	obs_name_ch=num2cell(structfun(@(x) size(x,2), all_obs(1)));
	all_names=cellfun(@(x,y) cellfun(@(x1) [x '#' num2str(x1)], num2cell(1:y), 'UniformOutput',false), obs_name, obs_name_ch, 'UniformOutput',false);
	all_names=[all_names{:}];

	%% Convert all observations to matrix
	all_obs= cell2mat(struct2cell(all_obs)');

	%% Data normalization
	if isfield(alg,'norm_std') && alg.norm_std
		all_obs=zscore(all_obs);
	end

	%% Perform PCA
	[pc,score,latent,tsquare] = princomp(all_obs); %#ok<NASGU>

	%% Save only inportant factors
	score(:,alg.factors_num+1:end)=[];

	if isfield(alg,'verbose_output') && alg.verbose_output
		fprintf('vnm_meta_pca: %d factors covers %f variances\nvnm_meta_pca: normalized variances: ', alg.factors_num, sum(latent(1:alg.factors_num))/sum(latent));
		arrayfun(@(x) fprintf('%f,  ',x), latent/sum(latent));
		fprintf('\nvnm_meta_pca: best factors: ');
		[mv,mi]=max(pc);
		cellfun(@(x,y) fprintf('%s(%f)  ',x,y), all_names(mi), num2cell(mv));
		fprintf('\n')
	end

	for base_i=1:size(base,1)
		for file_i=1:numel(base(base_i).data)
			obs_num=all_obs_sz(1);
			base(base_i).data{file_i}.pca=score(1:obs_num,:);
			score(1:obs_num,:)=[];
			all_obs_sz(1)=[];
		end
	end

	if not(isempty(score)) || not(isempty(all_obs_sz))
		error('vnm:meta:pca', 'Error of data incorporation.');
	end
end

function all_obs=remove_fields(all_obs, alg)
	% Remove some observation types
	obs_names=fieldnames(all_obs);
	obs_rm_mask=false(size(obs_names));

	if isfield(alg, 'obs_pick')
		for i=1:numel(alg.obs_pick)
			obs_rm_mask = obs_rm_mask | cellfun(@(x) numel(x)==1 && x==1, regexp(obs_names, alg.obs_pick{i}));
		end
		obs_rm_mask = not(obs_rm_mask);
	end

	if isfield(alg, 'obs_del')
		for i=1:numel(alg.obs_del)
			obs_rm_mask = obs_rm_mask | cellfun(@(x) numel(x)==1 && x==1, regexp(obs_names, alg.obs_del{i}));
		end
	end

	if sum(obs_rm_mask)>0
		obs_names(not(obs_rm_mask))=[];
		all_obs=rmfield(all_obs, obs_names);
	end
end

function y=make_file_obs(x, expr) %#ok<STOUT,INUSL>
	evalc(expr);
end
