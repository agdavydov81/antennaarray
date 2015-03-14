function stable = isfilterstable(A)
% stable = isfilterstable(a)
% test IIR filter stability
% see https://ccrma.stanford.edu/~jos/fp/Testing_Filter_Stability_Matlab.html

	N = length(A)-1;	% Order of A(z)
	stable = true;		% stable unless shown otherwise
	A = A(:);			% make sure it's a column vector
	for i=N:-1:1
		rci=A(i+1);
		if abs(rci) >= 1
			stable=false;
			return;
		end
		A = (A(1:i) - rci * A(i+1:-1:2))/(1-rci^2);
		% disp(sprintf('A[%d]=',i)); A(1:i)'
	end
end
