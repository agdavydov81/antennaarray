function b = gaussfilter(w_c, order_odd_even)
	if nargin<2
		order_odd_even = 1;
	end

	N = (0.9653582771365725*w_c + 2.258890242724331)./w_c;
	switch order_odd_even
		case 0
			N = round(N);
		case 1
			N = round((N-1)/2)*2+1;
		case 2
			N = round(N/2)*2;
		otherwise
			error('Unknown order_odd_even value.');
	end

	N2 = (N-1)/2;
	x = ((0:fix(N2))-N2)*3/N2;
	b = exp(-0.5*x.^2); % ./(N.*(-0.1762119423292104*w_c + 0.4166173757357399));
	b = [b b(ceil(N2):-1:1)];
	b = b/sum(b);
end
