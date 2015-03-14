classdef multi_cdf
	%MULTI_CDF classify data by multiple CDF's
	%   Performs classification by calculating Kolmogorov-Smirnov distance
	%   from each 1-D CDF in pack.

	properties
		cdfs; % vector of CDF's structures, contaning fields 'arg' and 'cdf'
	end

	methods
		function dist = distance(obj, data)
			% MULTI_CDF.DISTANCE Calculates distance between object's CDF's and incoming data
			%   dist = distance(data) returns distance between
			%   object's CDF's and incoming data
			%
			%   data - incoming data: each row is single observation
			%          and each column is single dimension
			%   dist - 1-N vector with distances for each CDF (data dimension)

			data_obj=multi_cdf.fit(data, {obj.cdfs.arg});
			dist=zeros(1,length(obj.cdfs));
			for cdf_i=1:length(obj.cdfs)
				dist(cdf_i)=sum(abs(data_obj.cdfs(cdf_i).cdf-obj.cdfs(cdf_i).cdf).*diff(obj.cdfs(cdf_i).arg));
			end
		end

		function plot(obj)
			% MULTI_CDF.PLOT Creates and displays figures with CDF's

			for dim=1:length(obj.cdfs)
				sub_pl=rem(dim-1,4);
				if sub_pl==0
					dim_sub=min(dim+3,length(obj.cdfs));
					figure('Name',sprintf('CDF %d-%d from %d', dim, dim_sub, length(obj.cdfs)), 'NumberTitle','off', 'Units','pixels', 'Position',get(0,'ScreenSize'));
					switch dim_sub-dim
						case 0
							sub_sz=[1 1];
						case 1
							sub_sz=[2 1];
						case 2
							sub_sz=[2 2];
						case 3
							sub_sz=[2 2];
					end
				end

				subplot(sub_sz(1),sub_sz(2),sub_pl+1);
				plot(mean([obj.cdfs(dim).arg(1:end-1) obj.cdfs(dim).arg(2:end)],2), obj.cdfs(dim).cdf);
				grid on;
				ylim([0 1]);
				title(['CDF ' num2str(dim)]);
			end
		end
	end

	methods(Static = true)
		function obj = fit(data, cdf_x)
			% MULTI_CDF.FIT Creates classifier fitted to data
			% obj = multi_cdf.fit(data, cdf_x) creates object fitted to
			% input data.
			%
			% data - Either observations matrix: each row is single observation
			%        and each column is single dimension;
			%        or cell: each cell element is one observation type (dimension);
			% cdf_x - cell of CDF grid for each dimension. If grid not
			%        defined the default grid (quantiles 0.01:0.01:0.99 per
			%        dimension) is used.

			obj=multi_cdf();

			% Put each matrix column in cell
			if isnumeric(data)
				sz=size(data);
				sz=arrayfun(@(x) ones(x,1), sz(2:end), 'UniformOutput',false);
				data=mat2cell(data,size(data,1),sz{:});
			end

			if nargin<2
				cdf_x=cellfun(@(x) quantile(x,transpose(0.01:0.01:0.99)), data, 'UniformOutput',false);
			end

			for dim=1:numel(data)
				cf=histc(data{dim},cdf_x{dim});
				cf=cf(:);

				obj.cdfs(dim).arg=cdf_x{dim};
				obj.cdfs(dim).cdf=cumsum(cf(1:end-1))/length(data{dim});
			end
		end

		function dist=cdfs_dist(cdfs, data)
			% MULTI_CDF.CDFS_DIST Return distance from cell of MULTI_CDF objects to cell of data
			% dist=multi_cdf.cdfs_dist(cdfs, data)

			for data_i=1:length(data)
				cur_dist=cell(1,length(cdfs));
				for cl_i=1:length(cdfs)
					cur_dist{cl_i}=cdfs{cl_i}.distance(data{data_i});
				end
				data{data_i}=cell2mat(cur_dist);
			end
			dist=cell2mat(data);
		end
	end
end
