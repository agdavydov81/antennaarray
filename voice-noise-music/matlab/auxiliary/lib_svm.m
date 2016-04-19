classdef lib_svm
	%LIB_SVM Multiclass SVM.
	%   Wrapper class for LIBSVM functions.
	%
	%   Chih-Chung Chang and Chih-Jen Lin, LIBSVM : a library for support vector machines.
	%   ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011.
	%   Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm.
	%
	%   See also lib_svm/train lib_svm/find_cost_gamma lib_svm/rate_prediction lib_svm/classify

	properties
		data_scale;
		classes;
		model;
	end

	methods(Access='protected')
		function obj=lib_svm()
		end
	end

	methods(Static)
		function obj=train(data, data_classes, libsvm_opt_arg)
			%train Performs libsvmtrain call and model selection procedure
			%   obj = LIB_SVM.TRAIN(data, data_classes) builds a classifier object obj. 
			%   obj = LIB_SVM.TRAIN(data, data_classes, libsvm_opt_arg) builds a
			%   classifier object obj. data is a numeric matrix of predictor data. Rows
			%   of data correspond to observations; columns correspond to features.
			%   data_classes is a column vector that contains the known class labels
			%   for data. data_classes is a grouping variable, i.e., it can be a
			%   categorical, numeric, or logical vector; a cell vector of strings; or a
			%   character matrix with each row representing a class label (see help for
			%   groupingvariable). Each element of data_classes specifies the group the
			%   corresponding row of data belongs to. data and data_classes must have
			%   the same number of rows. libsvm_opt_arg must be a string containing
			%   following options combination.
			%
			%   libsvm_opt_arg:
			%   -s svm_type : set type of SVM (default 0)
			%       0 -- C-SVC
			%       1 -- nu-SVC
			%       2 -- one-class SVM
			%       3 -- epsilon-SVR
			%       4 -- nu-SVR
			%   -t kernel_type : set type of kernel function (default 2)
			%       0 -- linear: u'*v
			%       1 -- polynomial: (gamma*u'*v + coef0)^degree
			%       2 -- radial basis function: exp(-gamma*|u-v|^2)
			%       3 -- sigmoid: tanh(gamma*u'*v + coef0)
			%       4 -- precomputed kernel (kernel values in training_set_file)
			%   -d degree : set degree in kernel function (default 3)
			%   -g gamma : set gamma in kernel function (default 1/num_features)
			%   -r coef0 : set coef0 in kernel function (default 0)
			%   -c cost : set the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
			%   -n nu : set the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
			%   -p epsilon : set the epsilon in loss function of epsilon-SVR (default 0.1)
			%   -m cachesize : set cache memory size in MB (default 100)
			%   -e epsilon : set tolerance of termination criterion (default 0.001)
			%   -h shrinking: whether to use the shrinking heuristics, 0 or 1 (default 1)
			%   -b probability_estimates: whether to train a SVC or SVR model for probability
			%          estimates, 0 or 1 (default 0)
			%   -wi weight: set the parameter C of class i to weight*C, for C-SVC (default 1)
			%   -v n: n-fold cross validation mode - randomly splits the data into n parts 
			%         and calculates cross validation accuracy/mean squared error on them.
			%   -q : quiet mode (no outputs)
			%   -rnd n : random generator seed (time by default)
			%   -max_iter n : stopping train maximum iterations number
			%
			%   See also lib_svm/find_cost_gamma lib_svm/rate_prediction lib_svm/classify
			obj=lib_svm;

			[cl_ind, ~, obj.classes]=grp2idx(data_classes);

			obj.data_scale.shift=-mean(data);
			obj.data_scale.factor=1./std(data);

			data = ( data+repmat(obj.data_scale.shift,size(data,1),1) ) .* repmat(obj.data_scale.factor,size(data,1),1);
			
			if nargin<3
				libsvm_opt_arg='';
			end

			obj.model = libsvmtrain(cl_ind, data, libsvm_opt_arg); %	train classifier
		end
		
		function [cost, gamma, predict]=find_cost_gamma(data, data_classes, varargin)
			%find_cost_gamma Performs libsvmtrain call for best cost and gamma parallel estimating
			%   [cost, gamma, predict] = find_cost_gamma(data, data_classes, ...).
			%   For description of obj, data and data_classes variables see lib_svm/train
			%   function description.
			%   Next optional arguments are supported:
			%   find_cost_gamma(..., 'autoscale',autoscale_flag) - if autoscale_flag is set, than
			%     before training the data is automatically scaled to zeros mean and unary variance.
			%   find_cost_gamma(..., 'fold',fold_number) - use fold_number-fold
			%     cross-validation to estimate best cost and gamma parameters. By
			%     default 10-fold cross-validation performed.
			%   find_cost_gamma(..., 'cost', cost_test) - set the list of cost parameters to
			%     be checked to find best cost-gamma combination. By default
			%     cost_test=pow2(-5:2:15).
			%   find_cost_gamma(..., 'gamma', gamma_test) - set the list of gamma parameters
			%     to be checked to find best cost-gamma combination. By default to
			%     gamma_test=pow2(-15:2:3).
			%   find_cost_gamma(..., 'opt_arg', libsvm_opt_arg) - set the optional libsvm
			%     argurments passed directly to libsvmtrain function.
			%
			%
			%   see also lib_svm/train lib_svm/rate_prediction lib_svm/classify

			[cl_ind, ~, obj_classes]=grp2idx(data_classes);

			opt_arg=' -h 0 -q';
			fold = 10;
			cost=pow2(-5:2:15);
			gamma=pow2(-15:2:3);
			autoscale=true;
			for i=1:2:length(varargin)
				if isa(varargin{i},'char')
					switch lower(varargin{i})
						case 'autoscale'
							autoscale=varargin{i+1};
						case 'fold'
							fold=varargin{i+1};
						case 'cost'
							cost=varargin{i+1};
						case 'gamma'
							gamma=varargin{i+1};
						case 'opt_arg'
							opt_arg=varargin{i+1};
					end
				end
			end

			if autoscale
				shift=-mean(data);
				factor=1./std(data);

				data = ( data+repmat(shift,size(data,1),1) ) .* repmat(factor,size(data,1),1);
			end

			% make cost-gamma all combinations
			cost_sz=numel(cost);
			gamma_sz=numel(gamma);
			cost=repmat(cost(:), gamma_sz, 1);
			gamma=reshape(repmat(gamma(:)', cost_sz, 1), length(cost),1);

			rand_ind=randperm(size(cost,1)); % Balance calculation load 
			gamma=gamma(rand_ind);
			cost=cost(rand_ind);

			predict=cell(size(cost));

			parfor i=1:size(cost,1)
				cmd = ['-v ',num2str(fold),' -c ',num2str(cost(i)),' -g ',num2str(gamma(i)), ' ' opt_arg];
				predict{i} = libsvmtrain(cl_ind, data, cmd);
			end

			predict = cellfun(@(x) obj_classes(x), predict, 'UniformOutput',false);

			% resort back
			[~,back_ind] = sort(rand_ind);
			cost =    cost(back_ind);
			gamma =   gamma(back_ind);
			predict = predict(back_ind);
		end
		
		function [accuracy, average_recall, asymm_est_cur, conf_mat, order, conf_mat_norm]=rate_prediction(g,ghat,varargin)
			%rate_prediction estimate classification rate.
			%   [accuracy, average_recall, asymm_est, conf_mat, order, conf_mat_norm] =
			%                            rate_prediction(G,GHAT)
			%                            rate_prediction(G,GHAT,'order',order)
			%   Input variables:
			%     G - reference classifications values;
			%     GHAT - predicted classifications values;
			%     order - vector containing group labels and whose values can be
			%         compared to those in G or GHAT using the equality operator.
			%   Output variables:
			%     accuracy - part of correct classification results (trace of
			%         the confusion matrix divided by G elements number);
			%     average_recall - average recall (mean of the normalized confusion
			%         matrix diagonal elements);
			%     asymm_est - normalized confusion matrix asymmetry estimation in range -1..1.
			%         Where 1 means all elements concentrated in upper triangular part
			%         of the normalized confusion matrix, and -1 means all elements
			%         concentrated in lower triangular part of the normalized confusion matrix.
			%     conf_mat -  confusion matrix;
			%     order - elements order in the confusion matrix;
			%     conf_mat_norm - per line normalized confusion matrix;
			%
			%   See also lib_svm/train lib_svm/find_cost_gamma lib_svm/classify confusionmat
			
			if isa(ghat,'cell') && strcmp(class(ghat{1}),class(g))
				conf_mat=cell(size(ghat));
				order=cell(size(ghat));

				accuracy=zeros(size(ghat));
				average_recall=zeros(size(ghat));
				asymm_est=zeros(size(ghat));

				for ci=1:numel(ghat)
					[conf_mat{ci}, order{ci}]=confusionmat(g, ghat{ci}, varargin{:});

					cm_sum=sum(conf_mat{ci},2);
					cm_sum(cm_sum==0)=1;
					conf_mat_norm=conf_mat{ci}./repmat(cm_sum,1,length(cm_sum));

					accuracy(ci)=trace(conf_mat{ci})/size(g,1);

					average_recall(ci)=mean(diag(conf_mat_norm));

					asymm_est_cur=conf_mat_norm-conf_mat_norm';
					asymm_est(ci)=sum(asymm_est_cur(triu(true(size(asymm_est_cur)),1)))/(size(asymm_est_cur,1)-1);
				end
				
			else
				[conf_mat, order]=confusionmat(g, ghat, varargin{:});

				cm_sum=sum(conf_mat,2);
				cm_sum(cm_sum==0)=1;
				conf_mat_norm=conf_mat./repmat(cm_sum,1,size(conf_mat,2));

				accuracy=trace(conf_mat)/size(g,1);

				average_recall=mean(diag(conf_mat_norm));

				asymm_est_cur=conf_mat_norm-conf_mat_norm';
				asymm_est_cur=sum(asymm_est_cur(triu(true(size(asymm_est_cur)),1)))/(size(asymm_est_cur,1)-1);
			end
		end
	end
	

	methods
		function cl_res=classify(obj, sample)
			%classify Classify data using libsvmpredict
			%   CL_RES=lib_svm.classify(SAMPLE) classifies each row in SAMPLE using the
			%   support vector machine classifier created using lib_svm.train, and
			%   returns the predicted class level CL_RES. SAMPLE must have the same
			%   number of columns as the data used to train the classifier in
			%   lib_svm.train. CL_RES indicates the group to which each row of SAMPLE is assigned.
			%
			%   See also lib_svm/train lib_svm/TRAIN_BEST

			sample = ( sample+repmat(obj.data_scale.shift,size(sample,1),1) ) .* repmat(obj.data_scale.factor,size(sample,1),1);

			label_vector = zeros(size(sample, 1), 1); % just a stub for libsvmpredict
			[cl_res_wrk accuracy decision_val] = libsvmpredict(label_vector, sample, obj.model); %#ok<NASGU,ASGLU>

			cl_res=obj.classes(cl_res_wrk);
		end
	end
end
