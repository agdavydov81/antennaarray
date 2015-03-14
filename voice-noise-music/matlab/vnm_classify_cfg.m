	function alg=vnm_classify_cfg()
%%	Raw observations configuration
	alg.obs_general=				struct(	'precision','single', ...
											'frame_size',0.030, 'frame_step',0.010, 'fs',8000, ...
											'snr', inf, ...
... %										'preemphasis',0.95, ...
... %										'filter',struct('band',[300 3400], 'order',10), ...
											'rand_ampl',10.^((-20:0.1:20)/20), ...
											'auto_load_cache',true, ...
											'load_file',struct('channel',1) ); % load_file.channel field can be 1(default),2,... or 'merge' or 'concatenate'
	alg.obs=       struct('type','time',	'params',struct(	'param_','value_') );
	alg.obs(end+1)=struct('type','power',	'params',struct(	'is_db',true, 'is_normalize',true) );

	alg.obs(end+1)=struct('type','pitch',	'params',struct('log',true) ); % Значения ЧОТ гораздо лучше описываются лог-нормальным или гамма-распределением, чем нормальным
	
	alg.obs(end+1)=struct('type','tone',	'params',struct('f0_range',[80 500], 'f1_band',[350 2000], 'signal_band',[350 3400], 'median',0.070) );

	alg.obs(end+1)=struct('type','phonfunc','params',struct( 'window','hamming', 'delay',0.040) ); % phonetic function: log-spectral and Itakura–Saito LPC spectrum distances

	alg.obs(end+1)=struct('type','lsf',		'params',struct( 'window','hamming') );

	alg.obs(end+1)=struct('type','lpcc',	'params',struct( 'window','hamming') );
	
	alg.obs(end+1)=struct('type','rceps',	'params',struct( 'window','hamming', 'order',20) );

	alg.obs(end+1)=struct('type','mfcc',	'params',struct( 'window','hamming', 'bands_on_4kHz',23, 'norm_flt',true, 'sum_magnitude',false, 'order',13) );

	alg.obs(end+1)=struct('type','hos',		'params',struct( 'window','hamming') );

%	alg.obs(end+1)=struct('type','teo',		'params',struct( 'bands',[	  20	5300;	 150	 850;	 500	2500;	1500	3500;	2500	4500;
%																		  20     100;	 100	 200;	 200	 300;	 300	 400;	 400	 510;
%																		 510	 630;	 630	 770;	 770	 920;	 920	1080;	1080	1270;
%																		1270    1480;	1480	1720;	1720	2000;	2000	2320;	2320	2700;
%																		2700    3150;	3150	3700],	... %;	3700	4400;	4400	5300],	...
%											'band_norm',true,	'order',0.100) );

	alg.obs(end+1)=struct('type','specrel',	'params',struct('bands',[150 850; 500 2500; 1500 3500; 2500 4500]) );


	%% Meta observations configuration
	alg.meta_obs=struct('type',{},	'params',{});

%	alg.meta_obs=		struct('type','vad',	'params',struct( 'tone',true,	'result_min_sz',0.150) );

%	alg.meta_obs(end+1)=struct('type','split',	'params',struct( 'size',2.5,	'step',2.5) ); % 'last',10.0

%	alg.meta_obs(end+1)=struct('type','intonogram','params',struct(	'obs',{{'power' 'pitch' 'lsf' 'lpcc' 'hos'}}, ... % 'teo'
%												'win_sz',0.300,		'speech_sz',1.0,	'pause_sz',0.100) );

%	obslist={'power'  'pitch'  'lsf'  'lpcc'  'rceps'  'mfcc'  'hos'  'specrel'}; % 'teo' 'rmmfcc'
	obslist={'pitch' 'lsf' 'lpcc' 'hos' 'phonfunc' 'specrel' 'mfcc' 'rceps'};
	d_obslist=strcat('d_',obslist);
%	d_d_obslist=strcat('d_',d_obslist);

	alg.meta_obs(end+1)=struct('type','delta',	'params',struct( 'obs',{obslist},	'delay',0.040) );
	alg.meta_obs(end+1)=struct('type','delta',	'params',struct( 'obs',{d_obslist},	'delay',0.040) );

	alg.meta_obs(end+1)=struct('type','teo',	'params',struct( 'obs',{obslist},	'delay_half',0.040) );
	alg.meta_obs(end+1)=struct('type','teo',	'params',struct( 'obs',{d_obslist},	'delay_half',0.040) );

%	alg.meta_obs(end+1)=struct('type','nomean',	'params',struct( 'obs',{obslist} ) ); % 'teo'

	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{obslist} ) ); % 'teo'
%	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{d_obslist} ) ); % 'd_teo'
%	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{d_d_obslist} ) ); % 'd_d_teo'

	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{obslist} ) ); % 'teo'
%	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{d_obslist} ) ); % 'd_teo'
%	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{d_d_obslist} ) ); % 'd_d_teo'

% 	alg.meta_obs(end+1)=struct('type','stat',	'params',struct(	'obs',{{'power'		'pitch'		'lsf'		'lpcc'		'mfcc'		'hos'		'teo'		'specrel'	...
%														'd_power'	'd_pitch'	'd_lsf'		'd_lpcc'	'd_mfcc'	'd_hos'		'd_teo'		'd_specrel'		...
%														'm_power'	'm_pitch'	'm_lsf'		'm_lpcc'	'd_d_mfcc'	'm_hos'		'm_teo'		'd_d_specrel'}},	...
%														'func',{{'y=std(x);  y(isnan(y)|isinf(y))=0;' 'y=skewness(x);  y(isnan(y)|isinf(y))=0;' 'y=kurtosis(x); y(isnan(y)|isinf(y))=0;' 'y=mean(x)-median(x);  y(isnan(y)|isinf(y))=0;'}} ) );

%	alg.meta_obs(end+1)=struct('type','select_obs','params',struct(	'pick',	{{'file_name'	'time'	'.*pitch' '.*lsf' '.*lpcc'}}));
%																	'del',	{{'power'	'.*d_pitch'}}));

	alg.meta_obs(end+1)=struct('type','isnan',	'params',struct( 'isremove',true, 'verbose',true) );



    libsvm_opt_arg =' -c 512 -g 0.125 -h 0 -q'; %  ' -c 8 -g 0.0078125 -h 0 -q'; %   ' -c 512 -g 0.0019531 -h 0 -q';


%{
	%% Examine observations and feature selection
	alg.examine_obs=struct(		'out_dir','.\vnm_examine_obs', ...
								'make_cdf_pic',true, ...
								'make_cdf_fig',false, ...
								'skip_existed',true, ...
								'objective_func', 'average_recall'); % 'accuracy' or 'average_recall'
%}
	alg.feature_select=struct(	'svm_opt_arg', libsvm_opt_arg,...
								'log_root', '.\vnm_feature_select', ...
								'log_root_parfor', '.\vnm_parfor', ...
								'base_auto_balance', true, ...
								'objective_func', 'average_recall', ... % 'accuracy' or 'average_recall'
								'lrs_opt_arg', struct(	'modsel', true, ...
														'goal_set', 70, ...
														'L',	5, ...
														'R',	3),...
								'train_info', struct(	'K_fold',	10, ...
														'cv_steps',	1));


	%% Classifiers configuration
	alg.classifier.proc=	struct('crossvalidation','K-fold', ... % 'K-fold' 'Random subsampling' 'None'
									'folds',10, ...
									'train_part',0.9, ... % only for 'Random subsampling'
									'save_path','.\emo_proc'); 

	% Перечень видов наблюдений для построения наулучшего классификатора -- пример
	alg.classifier.proc.obs_expr={'x.pitch(:,1)' 'x.d_pitch(:,1)'};

%	alg.classifier.gmm=struct(	'opt_arg',{{4, 'Replicates',3, 'Regularize',1e-6, 'options',statset('MaxIter',10000, 'TolX',1e-6)}});

	alg.classifier.libsvm = struct(	'opt_arg', libsvm_opt_arg);

%	alg.matlabpool={'local'};
end
