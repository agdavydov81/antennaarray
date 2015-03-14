function alg = vnm_feature_select(base, db_type, alg)
%VNM_FEATURE_SELECT	Plus-L Minus-R Feature Selection (LRS)
%
% 	Sequential feature selection procedure which consists of L forward
% 	search and R backward elimination (to avoid nesting) substeps on
% 	each step of the algorithm. Uses multiclass SVM classifier based on
% 	libSVM functions and K-fold cross-validation for estimation of
% 	classification efficacy. RBF is used as a kernel function in
% 	SVM-classifier.
%
%	Configuration should be determined in "alg" structure:
%	libsvm_opt_arg = ' -c 10 -g 0.002 -h 0 -q';
% 	alg.feature_select=struct(	'svm_opt_arg', libsvm_opt_arg,...
% 								'stat_func','wks', 'logging', true,...
% 								'lrs_opt_arg', struct(	'modsel', true, ...
% 														'goal_set', 25, ...
% 														'L',	5, ...
% 														'R',	3),...
% 								'train_info', struct(	'K_fold',	20, ...
% 														'cv_steps',	1));
%	'svm_opt_arg'	libSVM comand prompt parameters
%	'stat_func'		statistical functional applied to data (could be 'mean'
%					or 'wks')
%	'logging'		enable\disable logging of subproducts (default enabled)
%	'lrs_opt_arg'	defines the parameters of LRS algorithm:
%			'modsel'	perform model selection procedure after each step
%						(default true)
% 			'goal_set'	approximate number of features in goal set
%						(default 10)
% 			'L'			number of forward substeps on each iteration
%						(default 1)
% 			'R'			number of backward substeps on each iteration
%						(default 0)
%						L>R => Forward Selection (starts from empty set and
%						sequetially adds features maximizing classification
%						efficiency)
%						L<R => Backward Elimination (starts from full set
%						and sequentially eliminates features with minimal
%						classification efficiency)
%	'train_info'	details of K-fold cross-validation procedure
%			'K_fold'	K-value. 10-fold cross-validation is usually
%						recommended, but the exact K value for robust work
%						of the SFS should be defined manually (default 20)
%			'cv_steps'	number of repetitions of defined cross-validation
%						procedure with averaging of the results obtained
%						(default 1)
%
% 	For detailed description see:
%
%		Plus-L Minus-R Feature Selection:
% 	Steams, S.D. (1976). On selecting features for pattern classifiers. 
% 	Third Internat. Conf. on Pattern Recognition, Coronado, CA, 
% 	pp. 71-75.
% 
% 	Pudil, P.,  Novovicova, J. and Kittler, J. (1994). Floating
% 	search methods in feature selection. Pattern Recognition
% 	Letters, 15, pp. 1119-1125.
%
%		libSVM:
%   Chih-Chung Chang and Chih-Jen Lin, LIBSVM : a library for support
%   vector machines. ACM Transactions on Intelligent Systems and
%   Technology, 2:27:1--27:27, 2011. Software available at
%   http://www.csie.ntu.edu.tw/~cjlin/libsvm.
%
%		K-fold cross-validation:
% 	Kohavi, R. (1995). A study of cross-validation and bootstrap for
% 	accuracy estimation and model selection. In: Proceedings of the
% 	Fourteenth International Joint Conference on Artificial Intelligence
% 	(pp. 1137–1143). San Francisco, CA: Morgan Kaufmann.


	obs_del = {'time' 'file_range'}; % observations which should be removed from the base

	if isfield(alg.feature_select,'log_root')
		sfs_log_root=alg.feature_select.log_root;
	else
		sfs_log_root='.';
	end

	if isfield(alg.feature_select,'log_root_parfor')
		sfs_log_root_parfor=alg.feature_select.log_root_parfor;
	else
		sfs_log_root_parfor='';
	end
	
	sfs_log_root=[sfs_log_root filesep db_type];	% folder to store obtained results
	save_st_arg={[sfs_log_root filesep '_sfs_state.mat'],'alg','L_i','R_i','best_fs', ...
			'best_rates','best_rr','best_svm_opt_arg','svm_opt_arg','cur_best','cur_step','-v7.3'};

	if exist(save_st_arg{1},'file')
		cache=load(save_st_arg{1},'alg');
		alg_cur=alg;
		alg_cur.feature_select.log_root_parfor='';
		cache.alg.feature_select.log_root_parfor='';
		if not(isequal(alg_cur.feature_select, cache.alg.feature_select))
			error('vnm:feature_select:continue', 'Can''t resume calculation: algorithms are differents.');
		end
		clear('alg_cur');
	else
		mkdir(sfs_log_root);
		mkdir(sfs_log_root_parfor);
	end

	feature_list = fieldnames(base(1).data{1});
	feature_list(cellfun(@(x) not(isnumeric(base(1).data{1}.(x))), feature_list))=[];
	for del_i=1:length(obs_del)
		feature_list(strcmp(feature_list, obs_del{del_i}))=[];
	end

	f_list = {};
	for f_i=1:length(feature_list)
		f_sz = size(base(1).data{1}.(feature_list{f_i}), 2);
		for l_i=1:f_sz
			f_list{end+1,1} = {feature_list{f_i} l_i}; %#ok<AGROW>
		end
	end

	%% matlabpool start
	usepool = isfield(alg,'matlabpool');
	if usepool
		if matlabpool('size')>0
			matlabpool('close');
		end
		matlabpool(alg.matlabpool{:});
		spmd
			addpath_recursive(regexp(path(),'[^;]*','match','once'), 'ignore_dirs',{'\.svn' 'private' 'html' 'fspackage' 'FastICA' 'openEAR'});
			dos(['"' which('matlab_idle.bat') '"']);
		end
	end

	%% Prepare data matrix
	data_matrix_cache = [sfs_log_root filesep '_data_matrix_cache.mat'];
	if exist(data_matrix_cache, 'file')
		load(data_matrix_cache); % load cached result
	else
		% prepare data matrix
		[X Y cdf_data] = prepare_data_wks(base, f_list);
		save(data_matrix_cache, 'X', 'Y', 'cdf_data', '-v7.3');
	end

	if ~isfield(alg.feature_select, 'autoscale') || (alg.feature_select.autoscale)
		shift=cell(size(X));
		factor=cell(size(X));
		for X_i = 1:length(X)
			shift{X_i}=-mean(X{X_i});
			factor{X_i}=1./std(X{X_i});

			X{X_i} = ( X{X_i}+repmat(shift{X_i},size(X{X_i},1),1) ) .* repmat(factor{X_i},size(X{X_i},1),1);
		end
	end

	%% WRAPPER LRS: Plus-L Minus-R Selection
	best_fs = [];
	best_rr = 0;
	best_svm_opt_arg = '';
	cur_best.fs = [];
	cur_best.rate = 0;

	if isfield(alg.feature_select,'train_info')
		train_info=alg.feature_select.train_info;
	else
		train_info=struct(	'K_fold',	20, ...
							'cv_steps',	1);
	end

	if isfield(alg.feature_select,'svm_opt_arg')
		svm_opt_arg = alg.feature_select.svm_opt_arg;
	else
		svm_opt_arg = ' -c 10 -g 0.002 -h 0 -q';
	end

	if alg.feature_select.base_auto_balance
		svm_opt_arg = [svm_opt_arg make_weight_string(Y)];
	end

	modsel = true; goal_set = 10; L=1; R=0; % defaults
	if isfield(alg.feature_select,'lrs_opt_arg')
		% alg.feature_select.lrs_opt_arg.modsel determines if it is
		% necessary to perform model selection procedure after each
		% step
		modsel = alg.feature_select.lrs_opt_arg.modsel;			

		% alg.feature_select.lrs_opt_arg.max_steps contains information
		% about the depth of sequential forward search procedure
		goal_set = alg.feature_select.lrs_opt_arg.goal_set;

		% L & R are the number of forward and backward steps on each
		% iteration
		L = alg.feature_select.lrs_opt_arg.L;
		R = alg.feature_select.lrs_opt_arg.R;
	end
	if goal_set >= length(f_list)
		error('vnm:feature_select','The size of the goal feature set should be smaller than total number of features');
	end
	if L == R
		error('vnm:feature_select','In LRS options L==R. ');
	end

	%% SFS main loop BEGIN
	cur_step = 1;
	if L<R
		cur_best.fs = 1:length(f_list);
		best_rates = cell(ceil((length(f_list)-goal_set)/(R-L)),1);
	else
		best_rates = cell(ceil(goal_set/(L-R)),1);
	end

	L_i=1;
	R_i=1;
	if exist(save_st_arg{1},'file')
		alg_in=alg;
		load(save_st_arg{1});
		if isfield(alg_in,'matlabpool')
			alg.matlabpool=alg_in.matlabpool;
		else
			if isfield(alg,'matlabpool')
				alg = rmfield(alg,'matlabpool');
			end
		end
	end


	%% main loop
	while ((length(cur_best.fs)<goal_set)&&(L>R)) || ((length(cur_best.fs)>goal_set)&&(L<R))
		disp(['SFS: Step ' num2str(cur_step)]);
		mkdir([sfs_log_root filesep 'Step' num2str(cur_step)]);
		%% forward search
		% try to improve classification efficiency of the current set
		% by addition of L suitable features
		%
		disp('SFS: Forward search...');
		if L_i<=L
			for L_i = L_i:L
				save(save_st_arg{:});

				f_list_X = '';
				for ii=1:length(cur_best.fs)
					f_list_X = [ f_list_X ' ''x.' f_list{cur_best.fs(ii)}{1} '(:,' num2str(f_list{cur_best.fs(ii)}{2}) ')''' ]; %#ok<AGROW>
				end
				size_X = size(X, 2);
				exam_log=cell(size_X,1);

				parfor fs_i=1:size_X % parfor
					if ~any(cur_best.fs == fs_i) %#ok<PFBNS>
						parfor_cache=[sfs_log_root_parfor filesep db_type '_step' num2str(cur_step) '_forward' num2str(L_i) '_parfor' num2str(fs_i) '.mat'];
						if not(isempty(sfs_log_root_parfor)) && exist(parfor_cache,'file')
							exam_obs=load_parfor_cache(parfor_cache);
						else
							cur_fs = [cur_best.fs, fs_i];
							exam_obs=struct('fs', cur_fs, 'f_list', [f_list_X ' ''x.' f_list{fs_i}{1} '(:,' num2str(f_list{fs_i}{2}) ')''' ]);
							exam_obs.rate=examine_fset([X{cur_fs}], Y, train_info, svm_opt_arg, alg); %#ok<PFBNS>
							if not(isempty(sfs_log_root_parfor))
								save_parfor_cache(parfor_cache, exam_obs);
							end
						end
						exam_log{fs_i}=exam_obs;
					end
				end

				if not(isempty(sfs_log_root_parfor))
					delete([sfs_log_root_parfor filesep db_type '_step' num2str(cur_step) '_forward' num2str(L_i) '_parfor*.mat']);
				end

				exam_log(cellfun(@isempty, exam_log))=[];
				exam_log=cell2mat(exam_log);
				[~,si]=sort([exam_log.rate],'descend');
				exam_log=exam_log(si);
				cur_best = exam_log(1);
				if (cur_best.rate > best_rr)
					best_rr = cur_best.rate;
					best_fs = cur_best.fs;
					best_svm_opt_arg = svm_opt_arg;
				end

				cur_log_root=[sfs_log_root filesep 'Step' num2str(cur_step) filesep];
				cur_log_name=[db_type '_step' num2str(cur_step) '_forward' num2str(L_i)];

				fh=fopen([cur_log_root cur_log_name '.txt'],'w');
				fprintf(fh, 'svm_opt_arg = ''%s''\n', svm_opt_arg);
				arrayfun(@(x) fprintf(fh, '%0.5f : %s\n', x.rate, x.f_list(:)), exam_log);
				fclose(fh);
			end
			L_i=L_i+1; %#ok<NASGU>
		end

		%% backward search
		% eliminating of R least important features from the current
		% set
		%
		disp('SFS: Backward search...');
		if R_i<=R
			for R_i = R_i:R
				save(save_st_arg{:});

				exam_log=cell(length(cur_best.fs),1);

				for jj = 1:length(cur_best.fs)
					f_list_X = '';
					tmp_fs = cur_best.fs;
					tmp_fs(jj)=[];
					for ii=1:length(tmp_fs)
						f_list_X = [ f_list_X ' ''x.' f_list{tmp_fs(ii)}{1} '(:,' num2str(f_list{tmp_fs(ii)}{2}) ')''' ]; %#ok<AGROW>
					end
					exam_log{jj}.fs = tmp_fs;
					exam_log{jj}.f_list = f_list_X;
				end

				parfor fs_i=1:length(cur_best.fs)
					parfor_cache=[sfs_log_root_parfor filesep db_type '_step' num2str(cur_step) '_backward' num2str(R_i) '_parfor' num2str(fs_i) '.mat'];
					if not(isempty(sfs_log_root_parfor)) && exist(parfor_cache,'file')
						exam_obs=load_parfor_cache(parfor_cache);
					else
						tmp_fs = cur_best.fs; %#ok<PFBNS>
						tmp_fs(fs_i) = [];
						exam_obs=examine_fset([X{tmp_fs}], Y, train_info, svm_opt_arg, alg); %#ok<PFBNS>
						if not(isempty(sfs_log_root_parfor))
							save_parfor_cache(parfor_cache, exam_obs);
						end
					end
					exam_log{fs_i}.rate=exam_obs;
				end

				if not(isempty(sfs_log_root_parfor))
					delete([sfs_log_root_parfor filesep db_type '_step' num2str(cur_step) '_backward' num2str(R_i) '_parfor*.mat']);
				end

				exam_log=cell2mat(exam_log);
				[~,si]=sort([exam_log.rate],'descend');
				exam_log=exam_log(si);
				cur_best = exam_log(1);
				if (cur_best.rate > best_rr)
					best_rr = cur_best.rate;
					best_fs = cur_best.fs;
					best_svm_opt_arg = svm_opt_arg;
				end

				cur_log_root=[sfs_log_root filesep 'Step' num2str(cur_step) filesep];
				cur_log_name=[db_type '_step' num2str(cur_step) '_backward' num2str(R_i)];

				fh=fopen([cur_log_root cur_log_name '.txt'],'w');
				fprintf(fh, 'svm_opt_arg = ''%s''\n', svm_opt_arg);
				arrayfun(@(x) fprintf(fh, '%0.5f : %s\n', x.rate, x.f_list(:)), exam_log);
				fclose(fh);
			end
			R_i=R_i+1; %#ok<NASGU>
		end

		save(save_st_arg{:});

		% Model selection for optimization of classifier performance
		if modsel
			disp('SFS: Model selection...');
			[svm_opt_arg cur_best.rate] = libsvm_modsel(Y, [X{cur_best.fs}], train_info, svm_opt_arg, alg);

			fh=fopen([sfs_log_root filesep 'Step' num2str(cur_step) filesep ...
					db_type '_step' num2str(cur_step) '_model_selection.txt'],'w');
			fprintf(fh, 'svm_opt_arg = ''%s''\n', svm_opt_arg);
			fclose(fh);
		end

		disp(['SFS: Step ' num2str(cur_step) ' complete! RR ~ ' num2str(cur_best.rate)])

		best_rates{cur_step} = cur_best;
		best_rates{cur_step}.svm_opt_arg = svm_opt_arg;
		best_rates{cur_step}.step = cur_step;

		if (cur_best.rate > best_rr)
			best_rr = cur_best.rate;
			best_fs = cur_best.fs;
			best_svm_opt_arg = svm_opt_arg;
		end
		cur_step = cur_step + 1;

		L_i=1;
		R_i=1;
	end
	% SFS main loop END
	save(save_st_arg{:});

	f_list = f_list(best_fs);
	f_list_str = cellfun(@(x) (['x.' x{1} '(:,' num2str(x{2}) ')']), f_list, 'UniformOutput', false)';
	alg.classifier.proc.obs_expr = f_list_str;
	if isfield(alg.classifier, 'libsvm')
		alg.classifier.libsvm.opt_arg = svm_opt_arg;
	end

	% Summary of the SFS procedure:
	% Store the best feature set, model parameters and the same for the
	% each step.
	fh=fopen([sfs_log_root filesep '_all_steps_best.txt'],'w');
	fprintf(fh, 'Best: fnum - %.0f, RR ~ %0.5f, svm_opt_arg = ''%s''; features : %s\n\n', length(best_fs), best_rr, best_svm_opt_arg, ...
		sprintf('''%s'' ', f_list_str{1:end}));
	cellfun(@(x) fprintf(fh, 'Step %.0f, fnum - %.0f, RR ~ %0.5f, svm_opt_arg = ''%s''; features : %s\n', x.step ,length(x.fs), x.rate, x.svm_opt_arg, x.f_list(2:end)), best_rates);
	fclose(fh);

	if usepool
		matlabpool('close');
	end		
end

function exam_obs=load_parfor_cache(parfor_cache) %#ok<STOUT>
	load(parfor_cache);
end

function save_parfor_cache(parfor_cache, exam_obs) %#ok<INUSD>
	save(parfor_cache, 'exam_obs', '-v7.3');
end

%% wks - based data matrix preparation
function [X Y cdf_data] = prepare_data_wks(base, f_list)
	disp('SFS: Generating CDF data...'); tic;

	Y=cell2mat(arrayfun(@(x,x_sz) zeros(length(x.data),1)+x_sz, base, (1:length(base))', 'UniformOutput',false));

	X=cell(1,length(f_list));

	h = waitbar(0);
	cdf_data=cell(length(f_list),1);
	base_data = vertcat(base.data);
	for flist_i = 1:length(f_list)
		if all(cellfun(@(x) size(x.(f_list{flist_i}{1}),1)==1, base_data))
			% Это скорее всего статистические данные -- для каждого файла
			% есть только одно значени, а не вектор значений
			X{flist_i}=double( cellfun(@(x) x.(f_list{flist_i}{1})(:,f_list{flist_i}{2}), base_data) );

		else
			% Make median CDF's
			cl_cdf=cell(size(base));
			cl_obs=cell(size(base));
			for cl_i=1:numel(base)
				cl_obs{cl_i}=cellfun(@(x) x.(f_list{flist_i}{1})(:,f_list{flist_i}{2}), base(cl_i).data, 'UniformOutput',false);

				cl_obs_arg={quantile(cell2mat(cl_obs{cl_i}), linspace(0.05,0.95,250)')};

				files_cdf=cell2mat(cellfun(@(x) multi_cdf.fit(x,cl_obs_arg).cdfs.cdf, cl_obs{cl_i}', 'UniformOutput',false));

				cl_cdf{cl_i}=multi_cdf;
				cl_cdf{cl_i}.cdfs.arg=cl_obs_arg{1};
				cl_cdf{cl_i}.cdfs.cdf=median(files_cdf,2);
			end

			cdf_data{flist_i}=cl_cdf;
			X_cur=cell(1,length(cl_cdf));
			cl_obs=vertcat(cl_obs{:});
			parfor cl_i=1:length(cl_cdf) % parfor
				X_cur{cl_i} = parfor_cdfs_dist(cl_cdf(cl_i),cl_obs);
			end
			X{flist_i}=cell2mat(X_cur);
		end

		a = toc*((length(f_list)/flist_i)-1);
		rem_str=sprintf('%d%%; %02d:%02d:%02d remaining...',fix(flist_i*100/length(f_list)), fix(a/3600), fix(rem(a,3600)/60), fix(rem(rem(a,3600),60)));
		set(h, 'Name',rem_str);
		waitbar(flist_i/length(f_list),h,['CDF Generating ' rem_str]);
	end
	close(h);
	disp('SFS: Generating CDF data ... completed');
	pause(0.2);
end

function X = parfor_cdfs_dist(cl_cdf_i, cl_obs)
	X=multi_cdf.cdfs_dist(cl_cdf_i,cl_obs);
end

%%	libSVM wrapper
function classifier_rate=examine_fset(X, Y, train_info, svm_opt_arg, alg)
	% '-v K' option means that K-fold cross-validation will be applied.
	% 10-fold cross-validation is recommended, but the exact K value for
	% robust work of the SFS should be defined manually (default 20)

	cl_rate = zeros(train_info.cv_steps,1);
	for ii = 1:train_info.cv_steps
		Y_hat = libsvmtrain(Y, X, ['-v ' num2str(train_info.K_fold) ' ' svm_opt_arg]);
		[rate_accuracy, rate_average_recall]=lib_svm.rate_prediction(Y,Y_hat);
		switch alg.feature_select.objective_func
			case 'accuracy'
				cl_rate(ii) = rate_accuracy;
			case 'average_recall'
				cl_rate(ii) = rate_average_recall;
			otherwise
				error('Unknown objectibe function.');
		end
	end
	classifier_rate = mean(cl_rate);
end

%% MODEL SELECTION for libSVM
% Model selection for (lib)SVM by searching for the best param on a 2D grid
% @@@ Could be optimized!
%
function [svm_opt_arg best_rate] = libsvm_modsel(label, inst, train_info, svm_opt_arg, alg)
	float_regexp= '[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?';
	svm_opt_arg = regexp(svm_opt_arg, ['-g ' float_regexp], 'split');
	svm_opt_arg = regexp([svm_opt_arg{:}], ['-c ' float_regexp], 'split');
	svm_opt_arg = [svm_opt_arg{:}];
	svm_opt_arg(strfind(svm_opt_arg, '  '))='';

	label = grp2idx(label);

	fold = train_info.K_fold;

	cost=pow2(-5:2:15);
	gamma=pow2(-15:2:3);

	% make cost-gamma all combinations
	cost_sz=numel(cost);
	gamma_sz=numel(gamma);
	cost=repmat(cost(:), gamma_sz, 1);
	gamma=reshape(repmat(gamma(:)', cost_sz, 1), length(cost),1);

	rand_ind=randperm(size(cost,1)); % Balance calculation load 
	gamma=gamma(rand_ind);
	cost=cost(rand_ind);

	rate=zeros(size(cost));

	parfor i=1:size(cost,1)
		cmd = ['-v ',num2str(fold),' -c ',num2str(cost(i)),' -g ',num2str(gamma(i)), svm_opt_arg];
		label_hat = libsvmtrain(label,inst,cmd);
		[rate_accuracy, rate_average_recall]=parfor_rate_prediction(label,label_hat);
		switch alg.feature_select.objective_func %#ok<PFBNS>
			case 'accuracy'
				rate(i) = rate_accuracy;
			case 'average_recall'
				rate(i) = rate_average_recall;
			otherwise
				error('Unknown objectibe function.');
		end
	end

	[best_rate,mi]=max(rate);
	best_cost=cost(mi);
	best_gamma=gamma(mi);

	svm_opt_arg = [' -c ',num2str(best_cost),' -g ',num2str(best_gamma), svm_opt_arg];
end

function [rate_accuracy, rate_average_recall]=parfor_rate_prediction(label,label_hat)
	[rate_accuracy, rate_average_recall]=lib_svm.rate_prediction(label,label_hat);
end

function svm_weight_str=make_weight_string(Y)
	[cl_ind, cl_names, cl_vals]=grp2idx(Y);
	cl_size=arrayfun(@(x) sum(cl_ind==x), 1:length(cl_vals));
	svm_weight_str=cell2mat(cellfun(@(cl_i,cl_w) sprintf(' -w%s %e',cl_i,cl_w), cl_names(:)', num2cell(min(cl_size)./cl_size(:)'), 'UniformOutput',false));
end

