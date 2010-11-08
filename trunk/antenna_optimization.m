function antenna_optimization()
	clc;

%	rf2 = @(x)rastriginsfcn(x/10); % objective
%	x0 = [20,30]; % start point away from the minimum
%	problem = createOptimProblem('fmincon', 'objective',rf2, 'x0',x0);%, 'options',optimset('UseParallel','always'));
%	gs = GlobalSearch;
%	[xg fg flg og] = run(gs,problem)

	c=331.46;
	f=1000;
	lambda=c/f;
	antenna_sz=1;
	antenna_sectors_num_seq=[1000:-100:100, 10:100];
	for antenna_sectors_num_i=1:length(antenna_sectors_num_seq)
		antenna_sectors_num=antenna_sectors_num_seq(antenna_sectors_num_i);

	tic;

	objective_fn=@(x)ant_est_fn(x,c,f,antenna_sz,antenna_sectors_num, '');
%{
	xx=0.1:0.01:1;
	yy_obj=zeros(size(xx));
	yy_side=zeros(size(xx));
	yy_angle=zeros(size(xx));
	for ii=1:length(xx)
		[yy_obj(ii), yy_side(ii), yy_angle(ii)]=ant_est_fn(xx(ii),c,f, antenna_sz,antenna_sectors_num, '');
	end

	save('ant_opt.mat', 'xx', 'yy_obj', 'yy_side', 'yy_angle');

	figure;
	subplot(3,1,1);	plot(xx,yy_obj);
	subplot(3,1,2);	plot(xx,yy_side);
	subplot(3,1,3);	plot(xx,yy_angle);
%}
	x0=lambda/10;
	opt_problem = struct('objective',objective_fn, 'x0',x0, 'solver','fminunc', 'options',optimset);

	x = feval(opt_problem.solver, opt_problem);

	fprintf('Solutions is: %d\n',x);

	ant_est_fn(x,c,f,antenna_sz,antenna_sectors_num, sprintf('ant_opt_%d_%d.xml',antenna_sz,antenna_sectors_num));
	
	end

	toc;
end

function [score, side_lobe_part, c_angle]=ant_est_fn(x,c,f, antenna_sz,antenna_sectors_num, save_path)
	antenna.points=[0 0 0];
	for j=1:antenna_sz
		for i=1:antenna_sectors_num
			cur_dir=exp(2*pi*i*1i/antenna_sectors_num);
%			cur_dir=exp(2*pi*1i*(i+(j-1)/antenna_sz)/antenna_sectors_num);
			antenna.points(end+1,:)=[real(cur_dir) imag(cur_dir) 0]*j*x;% (j^(sqrt(2)/2));
		end
	end
	
	antenna.factor=ones(size(antenna.points,1),1);
	antenna.delay=zeros(size(antenna.factor));
	antenna.expr='y=sum([x{:}],2)';
	
	antenna.frequency=f;
	antenna.c=c;

	antenna.src_dist=100;
	antenna.src_points=180;
	antenna.use_parfor=true;
	
	if not(isempty(save_path))
		xml_write(save_path,antenna);
		score=0;
	end

	[~,~,~, ~, ~, side_lobe_part, c_angle, ~]=antenna_directivity_diagram(antenna);
	score=side_lobe_part*100+c_angle;
end
