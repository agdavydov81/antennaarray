classdef vnm_classifier_libsvm
	%EMO_CLASSIFIER_LIBSVM Gini distance SVM classifier
	%   Calculates Gini distances between cumulative distribution
	%   functions and classify incoming objects by these distances using
	%   libSVM.
    %   Supports multi-class classification tasks.

	properties
		cdf;
		svm;
	end

	methods(Access='protected')
		function obj=vnm_classifier_libsvm()
		end
	end

	methods(Static)
		function obj=train(train_dat, train_grp, etc_data, cl_alg)
			obj=vnm_classifier_libsvm;

			obj.cdf=etc_data.cl_cdf;

			opt_arg='';
			if nargin>=4 && isfield(cl_alg, 'opt_arg')
				opt_arg=cl_alg.opt_arg;
			end
			obj.svm=lib_svm.train(multi_cdf.cdfs_dist(obj.cdf,train_dat), train_grp, opt_arg);
		end
	end

	methods
		function cl_res=classify(obj, test_dat)
			cl_res=obj.svm.classify(multi_cdf.cdfs_dist(obj.cdf,test_dat));
		end
	end
end