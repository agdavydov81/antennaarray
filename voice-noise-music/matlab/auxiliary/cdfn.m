classdef cdfn
	%CDFN classify data by multidimensional CDF
	%   Performs classification by calculating Kolmogorov-Smirnov distance
	%   from multidimensional CDF.

	properties
		cdf;
		arg;
	end

	methods
		function dist = distance(obj, data, dist_fn)
			% CDFN.DISTANCE Calculates distance between object's N-dim CDF and incoming data
			%   dist = distance(obj, data, dist_fn) returns distance
			%   between object's CDF and incoming data CDF
			%
			%   obj - reference object
			%   data - incoming data: each row is single observation
			%          and each column is single dimension
			%   dist_fn - function for calculating CDF_ref - CDF_data (the default value is 'mean')
			%   dist - final weighted distance

			if size(data,2)~=length(obj.cdfs)
				error('cdfn:dist:dimension', 'Data dimension mismatch %d instead of %d.',size(data,2), length(obj.cdfs));
			end
			if nargin<3
				dist_fn='mean';
			end

			data_obj=cdfn.fit(data, {obj.cdfs.arg});
			diff=abs([obj.cdfs.cdf]-[data_obj.cdfs.cdf]);

			diff=feval(dist_fn, diff);

			dist=diff*vertcat(obj.cdfs.factor);
		end

		function plot(obj)
			% CDFN.PLOT displays 1-D or 2-D CDF's

			switch length(obj.arg)
				case 1
					plot(obj.arg, obj.cdf);
				case 2
					surf(obj.arg{1}, obj.arg{2}, obj.cdf);
				otherwise
			end
		end
	end

	methods(Static = true)
		function obj = fit(data, cdf_x)
			% CDFN.FIT Creates classifier fitted to data
			% obj = cdfn.fit(data, cdf_x) creates object fitted to
			% input data.
			%
			% data - observations matrix: each row is single observation
			%        and each column is single dimension;
			% cdf_x - cell of CDF grid for each dimension. If grid not
			%        defined the default grid (quantiles 0.05:0.05:0.95 per
			%        dimension) is used.

			obj=cdfn();
			if nargin<2
				[obj.cdf,obj.arg]=ecdfn(data);
			else
				[obj.cdf,obj.arg]=ecdfn(data, cdf_x);
			end
		end
	end
end
