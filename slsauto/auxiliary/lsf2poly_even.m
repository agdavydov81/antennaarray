function a = lsf2poly_even(f)
	m = size(f,2);
	if rem(m,2)
		error('This routine works only for even LSF size.');
	end

	p = zeros(size(f)+[0 1]);
	q = zeros(size(f)+[0 1]);
	a = zeros(size(f)+[0 1]);

	a(:,1) = 1;
	mq = m/2;
	p(:,1) = 1;
	q(:,1) = 1;
	for n = 1:mq
		nor = n*2;
		c1 = 2*cos(f(:,nor));
		c2 = 2*cos(f(:,nor-1));
		for i = nor+1:-1:3
			q(:,i) = q(:,i) + q(:,i-2) - c1 .* q(:,i-1);
			p(:,i) = p(:,i) + p(:,i-2) - c2 .* p(:,i-1);
		end
		q(:,2) = q(:,2) - c1;
		p(:,2) = p(:,2) - c2;
	end
	a(:,2) = 0.5 * (p(:,2) + q(:,2));
	for i = 2:m
		a(:,i+1) = 0.5 * (p(:,i) + p(:,i+1) + q(:,i+1) - q(:,i));
	end
end
