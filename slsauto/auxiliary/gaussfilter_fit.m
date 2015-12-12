function [w_c, w_c1, H0, N] = gaussfilter_fit()
	w_c = [];  w_c1=[];   H0=[];  N=[];
%	[N,w_c] = N_fit();

	[w_c, w_c1, H0, N] = norm_fit();
end

function [N,w_c] = N_fit()
	N = 7:255;
	w_c = zeros(size(N));
	for ni = 1:numel(N)
		b = exp(-0.5 * linspace(-3,3,N(ni)).^2)/N(ni);
		[h,w] = freqz(b,1,8192);
		w = w/pi;
		h = abs(h);
		h = h/h(1);
		w_c(ni) = interp1(h,w,0.5);
	end
end

function [w_c, w_c1, H0, N] = norm_fit()
	w_c = (0.01:0.01:0.2)/pi;
	w_c1 = zeros(size(w_c));
	H0 = zeros(size(w_c));
	N = zeros(size(w_c));
	for wi = 1:numel(w_c)
		b = gaussfilter(w_c(wi));
		[h,w] = freqz(b,1,8192);
		w = w/pi;
		h = abs(h);
		H0(wi) = h(1);
		N(wi) = numel(b);
		h = h/h(1);
		w_c1(wi) = interp1(h,w,0.5);
	end
end

function b = gaussfilter(w_c, get_odd_order)
	if nargin<2
		get_odd_order = false;
	end

	N = (0.9653582771365725*w_c + 2.258890242724331)./w_c;
	if get_odd_order
		N = round((N-1)/2)*2+1;
	else
		N = round(N);
	end

	x = linspace(-3,3,N);
	b = exp(-0.5*x.^2)./(N.*(-0.1762119423292104*w_c + 0.4166173757357399));
end
