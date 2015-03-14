function vnm_classify(db_path, db_type, alg)
	addpath_recursive(fileparts(mfilename('fullpath')), 'ignore_dirs',{'\.svn' 'private' 'html' 'fspackage' 'FastICA' 'openEAR'});

	if nargin<1
		db_path=uigetdir('','Pick base directory');
		if not(db_path)
			return;
		end
		db_type='berlin';
	end
	db_type=lower(db_type);

	if nargin<3
		alg=vnm_classify_cfg();
	end

	%% Вычисление наблюдений или загрузка даззных из кеша
	disp('vnm_classify: loading base...');
	base=vnm_load_db(db_path, db_type, alg);
	
	%% Определение эффективности отдельных видов надлюдений
	if isfield(alg,'examine_obs')
		disp('vnm_classify: examining observations...');
		if not(isfield(alg.examine_obs,'base_name'))
			alg.examine_obs.base_name=db_type;
		else
			alg.examine_obs.base_name=[db_type '_' alg.examine_obs.base_name];
		end
		vnm_examine_obs(base, db_type, alg);
	end

	%% Формирование наиболее эффективной комбинации признаков
	if isfield(alg,'feature_select')
		disp('vnm_classify: feature selection...');
		alg = vnm_feature_select(base, db_type, alg);
	end

	%% Построение финального классификатора
	if isfield(alg,'classifier') && isfield(alg.classifier,'proc')
		disp('vnm_classify: classifier build...');
		vnm_classifier_proc(base, db_type, alg);
	end
end
