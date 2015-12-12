function y = filter_fir_nodelay(b, x, delay)
	n = numel(b);
	if nargin<3
		delay = fix(n/2);

		b_ = abs(b);
		if max( (b_(1:delay) - b_(end:-1:end-delay+1))./b_(1:delay) ) > 1e-5
			error('This function supports automatic group delay only for symmetric filters. Try filtfilt.');
		end
	end

	y = filter(b,1,[repmat(x(1,:),n-1,1); x; repmat(x(end,:),delay,1)]);
	y(1:delay+n-1,:) = [];
end
