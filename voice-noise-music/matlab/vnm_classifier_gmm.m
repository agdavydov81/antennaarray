classdef emo_classifier_gmm
	%EMO_CLASSIFIER_GMM Kolmogorov-Smirnov distance GMM classifier
	%   Calculates Kolmogorov-Smirnov distances between cumulative distribution
	%   functions and classify incoming objects by these distances by GMM

	%   Author(s): A.G.Davydov
	%   $Revision: 1.0.0.2 $  $Date: 2012/10/15 22:45:05 $ 

	properties
		classes;
		cdf;
		gmm;
	end

	methods(Access='protected')
		function obj=emo_classifier_gmm()
		end
	end

	methods(Static)
		function obj=train(train_dat, train_grp, etc_data, cl_alg)
			obj=emo_classifier_gmm;

			opt_arg={};
			if nargin>=4 && isfield(cl_alg, 'opt_arg')
				opt_arg=cl_alg.opt_arg;
			end

			obj.classes=etc_data.cl_name;
			obj.cdf=	etc_data.cl_cdf;

			obj.gmm=cell(numel(obj.classes),1);
			for cl_i=1:numel(obj.classes)
				if isa(train_grp,'cell')
					ii = cellfun(@(x) isequal(x,obj.classes{cl_i}), train_grp);
				else
					ii = train_grp==etc_data(cl_i);
				end
				obj.gmm{cl_i}=gmdistribution.fit(multi_cdf.cdfs_dist(obj.cdf(cl_i), train_dat(ii)), opt_arg{:});
			end
		end
	end

	methods
		function cl_res=classify(obj, test_dat)
			cl_res=cell(size(test_dat));
			for obs_i=1:numel(test_dat)
				cur_pdf=zeros(size(obj.gmm));
				for cl_i=1:numel(obj.gmm)
					cur_pdf(cl_i)=obj.gmm{cl_i}.pdf( multi_cdf.cdfs_dist(obj.cdf(cl_i),test_dat(obs_i)));
				end
				[~,mi]=max(cur_pdf);
				cl_res(obs_i)=obj.classes(mi);
			end
		end
	end
end
