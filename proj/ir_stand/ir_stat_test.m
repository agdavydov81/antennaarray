function q_rel = ir_stat_test(p, sz, N, M)
% https://ru.wikipedia.org/wiki/%D0%91%D0%B8%D0%BD%D0%BE%D0%BC%D0%B8%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5_%D1%80%D0%B0%D1%81%D0%BF%D1%80%D0%B5%D0%B4%D0%B5%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5

if nargin<1
	p = 0.1;
end
if nargin<2
	sz = [100 100];
end
if nargin<3
	N = 1000;
end
if nargin<4
	M = 3;
end

if M==1
	p_med = p;
else
	p_med = 0;
	for i = ceil(M*M/2) : M*M
		p_med = p_med + nchoosek(M*M,i)*(p^i)*((1-p)^(M*M-i));
	end
	p_med1 = 1 - binocdf(floor(M*M/2), M*M, p);
end

graph = zeros(N,1);
for n = 1:N
	pp = rand(sz+M*2)<p;

	pp = medfilt2(pp, [M M]);

	pp(:,[1:M end-M+1:end]) = [];
	pp([1:M end-M+1:end],:) = [];

%	pp = median(rand([sz M*M])<p, 3);

	ss = sum(pp(:));
	graph(n) = ss;
end

qq = quantile(graph,[0.1 0.9]);
qq1 = binoinv([0.1 0.9],numel(pp),p_med);
q_rel = diff(qq)/diff(qq1);

if nargout<1
	figure('Units','normalized', 'Position',[0 0 1 1]);
	subplot(2,1,1);
	plot(graph);
	grid('on');
	subplot(2,1,2);
	[hy,hx]=ecdf(graph);
	[~,mu,sigma] = zscore(graph);
	plot(hx,hy);
	grid('on');
	hold('on');
	plot(hx(1):hx(end),binocdf(hx(1):hx(end),numel(pp),p_med),'r--');
	title(sprintf('mu=%f, sigma=%f, diff=%f',mu,sigma, q_rel ), 'interpreter','none');
	legend('Simulated','Theoretical','Location','NW');
end
