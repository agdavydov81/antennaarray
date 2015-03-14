function vnm_classifier_proc(base, db_type, alg)
	usepool = isfield(alg,'matlabpool') && not(strcmpi(alg.classifier.proc.crossvalidation,'none')) && alg.classifier.proc.folds>1;
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
	
	%% Генерация наблюдений из базы для всех строящихся классификаторов
	cl_obs=cell(size(base));
	for cl_i=1:numel(base)
		cl_obs{cl_i} = cellfun(@(x) make_file_obs(x, alg.classifier.proc.obs_expr), base(cl_i).data, 'UniformOutput',false);
		cl_obs{cl_i} = cl_obs{cl_i}(randperm(numel(cl_obs{cl_i}))); % randomize data order inside each class
	end
	cl_grp = cellfun(@(x,i) repmat({base(i).class},length(x),1), cl_obs, num2cell(1:length(cl_obs))', 'UniformOutput',false);
	
	train_part=0.5;
	if isfield(alg.classifier.proc,'train_part')
		train_part=alg.classifier.proc.train_part;
	end
	cl_sz=cellfun(@length, cl_obs);
	train_info.train_sz=round(cl_sz*train_part);

	%% Цикл построения классификаторов
	algs=lower(fieldnames(alg.classifier));
	algs(strcmp('proc',algs))=[];
	for a_i=1:numel(algs)
		clf_name=algs{a_i};

		%% make some common and useful data for classifiers
		etc_data=make_etc_data({base.class}, cl_obs);

		%% Процедура перекрестной проверки классификатора
		if not(strcmpi(alg.classifier.proc.crossvalidation,'none'))
			cl_confs=cell(1,1,alg.classifier.proc.folds);

			if usepool
				parfor K=1:alg.classifier.proc.folds
					cl_confs{K}=make_and_examine_classifier(K, cl_obs, etc_data, train_info, clf_name, alg);
				end
			else
				for K=1:alg.classifier.proc.folds
					cl_confs{K}=make_and_examine_classifier(K, cl_obs, etc_data, train_info, clf_name, alg);
				end
			end

			conf_mat = sum(cell2mat(cl_confs),3);

			cm_sum=sum(conf_mat,2);
			cm_sum(cm_sum==0)=1;
			conf_mat_norm=conf_mat./repmat(cm_sum,1,size(conf_mat,2));

			fprintf(['Classifier ' db_type '.' clf_name '\n']);
			fprintf('    Cross-validation accuracy %f, average recall %f\n', trace(conf_mat)/sum(conf_mat(:)), mean(diag(conf_mat_norm)));
			disp('    Confusion matrix');
			disp([{''} etc_data.cl_name'; etc_data.cl_name num2cell(conf_mat)]);

			disp('    Normalized confusion matrix');
			disp([{''} etc_data.cl_name'; etc_data.cl_name num2cell(conf_mat_norm)]);
		end

		%% Построение классификатора по всем данным и его сохранение
		cl_obj=feval(['vnm_classifier_' clf_name '.train'], vertcat(cl_obs{:}), vertcat(cl_grp{:}), etc_data, alg.classifier.(clf_name));

		cl_obj=struct('info',struct('type',clf_name, 'base_type',db_type, 'alg',alg), 'obj',cl_obj);
		save_classifier(cl_obj);
	end

	if usepool
		matlabpool('close');
	end
end

function y=make_file_obs(x, expr) %#ok<INUSL>
	y = cellfun(@(y) eval(y), expr, 'UniformOutput',false);
end

function save_classifier(classifier)
	if isfield(classifier.info.alg.classifier.proc,'save_path')
		cl_save_path=[classifier.info.alg.classifier.proc.save_path filesep];
	else
		cl_save_path='.';
	end

	save([cl_save_path filesep 'vnm_' classifier.info.base_type '_' classifier.info.type '.mat'], 'classifier', '-v7.3');
end

function cl_conf=make_and_examine_classifier(K, cl_obs, etc_data, train_info, clf_name, alg)
	% prepare train and test sets
	train_dat = cell(size(cl_obs));		train_grp = cell(size(cl_obs));
	test_dat =  cell(size(cl_obs));		test_grp =  cell(size(cl_obs));

	for cl_i = 1:length(cl_obs)
		switch lower(alg.classifier.proc.crossvalidation)
			case 'random subsampling'
				train_set = false(size(cl_obs{cl_i}));
				train_set(randperm(length(cl_obs{cl_i}), train_info.train_sz(cl_i))) = true;
			case 'k-fold'
				train_set = true(size(cl_obs{cl_i}));
				rg = round(length(train_set)*[(K-1) K]/alg.classifier.proc.folds);
				train_set(rg(1)+1:rg(2)) = false;
			otherwise
				error('emo:classifier:proc', 'Unknown cross-validation algorithm name.');
		end
		train_dat{cl_i} = cl_obs{cl_i}(train_set);
		test_dat{cl_i} =  cl_obs{cl_i}(not(train_set));
		
		train_grp{cl_i} = repmat(etc_data.cl_name(cl_i), length(train_dat{cl_i}), 1);
		test_grp{cl_i} =  repmat(etc_data.cl_name(cl_i), length(test_dat{cl_i}), 1);
	end

	train_dat = vertcat(train_dat{:});		train_grp = vertcat(train_grp{:});
	test_dat =  vertcat(test_dat{:});		test_grp =  vertcat(test_grp{:});

	% randomize data order in train and test sets
	rnd_ind=randperm(length(train_dat));	train_dat=train_dat(rnd_ind);	train_grp=train_grp(rnd_ind);
	rnd_ind=randperm(length(test_dat));		test_dat=test_dat(rnd_ind);		test_grp=test_grp(rnd_ind);

	% train classifier and test its prediction
	cl_objs_K=feval(['vnm_classifier_' clf_name '.train'], train_dat, train_grp, etc_data, alg.classifier.(clf_name));

	cl_conf = confusionmat(test_grp, cl_objs_K.classify(test_dat), 'Order',etc_data.cl_name);
end

function etc_data=make_etc_data(classes, cl_obs)
	etc_data.cl_name=classes(:);

	% Построение медианных функций распределения
	etc_data.cl_cdf = cell(length(etc_data.cl_name),1);
	for cl_i = 1:length(etc_data.cl_cdf)
		cl_obs_cat = vertcat(cl_obs{cl_i}{:});

		cl_obs_arg = cell(1,size(cl_obs_cat,2));
		for j=1:size(cl_obs_cat,2)
			cl_obs_arg{j} = quantile(cell2mat(cl_obs_cat(:,j)), linspace(0.05,0.95,250)');
		end

		cl_obs_cdf = cellfun(@(x) multi_cdf.fit(x,cl_obs_arg), cl_obs{cl_i}', 'UniformOutput',false);

		etc_data.cl_cdf{cl_i} = multi_cdf;
		etc_data.cl_cdf{cl_i}.cdfs = struct('arg',{}, 'cdf',{});

		for j=1:size(cl_obs_cat,2)
			etc_data.cl_cdf{cl_i}.cdfs(j) = struct('arg',cl_obs_arg{j}, 'cdf',median(cell2mat(cellfun(@(x) x.cdfs(j).cdf, cl_obs_cdf, 'UniformOutput',false)),2));
		end
	end
end
