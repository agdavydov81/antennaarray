function [x,y,z, antenna_center, main_lobe_ind, side_lobe_part, c_angle, c_lvl]=antenna_directivity_diagram(antenna_in)
%ANTENNA_DIRECTIVITY_DIAGRAM Antenna array directivity diagram evaluation.
%   [x,y,z, center, main_lobe_ind, side_lobe_part, c_angle, c_lvl] =
%                                            antenna_directivity_diagram(antenna_in)
%   Estimates antenna_in directivity diagram (x,y,z), finds geometric center
%   (center), separates directivity diagram main lobe from side lobes
%   (main lobe: x(1:main_lobe_ind,:), y(1:main_lobe_ind,:), z(1:main_lobe_ind,:)),
%   calculates side lobes capacity to main lobe capacity ratio (side_lobe_part)
%   and estimates main lobe maximum opening angle (c_angle) at the level (c_lvl).
%
%   antenna_in is the antenna description structure with next fields (and
%   default values in fields absence case).
%   antenna.frequency - analysis frequency in Hz (the default value is 1000 Hz);
%   antenna.c - wave propagation speed in m/s (the default value equals
%                                            331.46 m/s - speed of sound);
%   antenna.points - N by 3 matrix with [X Y Z] nodes coordinates in m;
%   antenna.factor - N by 1 vector with per node multipliers (the default is ones(N,1) );
%   antenna.delay -  N by 1 vector with per node delays in s (the default is zeros(N,1) );
%	antenna.expr - antenna output signal calculation string expression. Next
%	   variables can be used in expression: x - 1xN cell with signals in
%	   nodes; fs - sampling frequency in Hz; pt - copy of antenna.points
%	   and y - resulting signal.
%	   Antenna directivity diagram estimating as RMS of resulting signal (y).
%      The default value is 'y=sum([x{:}],2)'.
%   antenna.src_dist - distance to wave source in m (the default value is 100);
%   antenna.src_points - analysis grid nodes number (the default value is 180);
%   antenna.use_parfor - use parfor instead of for flag. This is suitable
%      for interactive processing (the default value is true).
%
%   See also ANTENNA_DIAGRAM

%	Author: Andrei Davydau
%   E-mail: andrew.aka.manik@gmail.com
%	Copyright 2009-2010 For Fun Inc.
%	Version: 1.0.1.3

	%% Prepare input config
	antenna=struct('expr','y=sum([x{:}],2)', 'frequency',1000, 'c',331.46, 'src_dist',100, 'src_points',180, 'use_parfor',true);

	% Merge default and input values
	ant_in_names=fieldnames(antenna_in);
	for i=1:length(ant_in_names)
		antenna.(ant_in_names{i})=antenna_in.(ant_in_names{i});
	end

	% Set default factor values
	if not(isfield(antenna,'factor'))
		antenna.factor=ones(size(antenna.points,1),1);
	end
	
	% Set default delay values
	if not(isfield(antenna,'delay'))
		antenna.delay=zeros(size(antenna.points,1),1);
	end

	if isa(antenna.expr,'cell')
		antenna.expr=[antenna.expr{:}];
	end
	if size(antenna.expr,1)>1
		antenna.expr=antenna.expr';
		antenna.expr=antenna.expr(1:numel(antenna.expr));
	end
	if isempty(antenna.expr)
		antenna.expr='y=sum([x{:}],2)';
	end

	antenna.lambda=antenna.c/antenna.frequency;	% Длинна волны
	antenna.k=2*pi/antenna.lambda;				% Волновое число

	antenna_center=sum(antenna.points.*repmat(antenna.factor,1,3),1)./(sum(antenna.factor,1)+[0 0 0]);	% Геометрический центр антены

	%% Form estimations points
	[x,y,z]=sphere(antenna.src_points);
	ind=z(:,1)<0;
	x(ind,:)=[];
	y(ind,:)=[];
	z(ind,:)=[];
	ro=zeros(size(x));

	par_xyz=antenna.src_dist.*[x(:) y(:) z(:)]+repmat(antenna_center,numel(x),1);
	par_ro= zeros(size(par_xyz,1),1);

	%% Calculate antenna respond
	if antenna.use_parfor && matlabpool('size')>1
		parfor par_i=1:size(par_xyz,1)
			par_ro(par_i)=antenna_est(par_xyz(par_i,:), antenna);
		end
	else
		for par_i=1:size(par_xyz,1)
			par_ro(par_i)=antenna_est(par_xyz(par_i,:), antenna);
		end
	end
	ro(:)=par_ro(:);

	ro=ro/max(max(ro));
	x=x.*ro;
	y=y.*ro;
	z=z.*ro;

	%% Calculate antenna characteristics
%	[sph_theta,sph_phi,sph_r]=cart2sph(x,y,z);
	x2y2=x.^2+y.^2;
	sph_r=sqrt(x2y2+z.^2);
	pol_rho=sqrt(x2y2);

	sph_r_eps=eps*10;
	mv=max(sph_r(2:end-1,:)<sph_r(1:end-2,:)-sph_r_eps & sph_r(2:end-1,:)<=sph_r(3:end,:)-sph_r_eps,[],2);
	[mmv,mmi]=max(mv(end:-1:1));
	if mmv==0
		main_lobe_ind=1;
	else
		main_lobe_ind=length(mv)-mmi+3;
	end

	side_capacity=find_capacity(x(1:main_lobe_ind,:), y(1:main_lobe_ind,:), z(1:main_lobe_ind,:));
	main_capacity=find_capacity(x(main_lobe_ind:end,:), y(main_lobe_ind:end,:), z(main_lobe_ind:end,:));
	side_lobe_part=side_capacity/(side_capacity+main_capacity);

	c_lvl=0.7;
	c_angle=180;

	main_z=z(main_lobe_ind:end,:);
	lvl_ind=(main_z(1:end-1,:)<=c_lvl & c_lvl<main_z(2:end,:));
	if sum(lvl_ind)==ones(1,size(lvl_ind,2))
		lvl_ind = [lvl_ind; zeros(1,size(lvl_ind,2))>1] | [zeros(1,size(lvl_ind,2))>1; lvl_ind];
		lvl_z=reshape(main_z(lvl_ind),2,[]);
		main_rho=pol_rho(main_lobe_ind:end,:);
		lvl_rho=reshape(main_rho(lvl_ind),2,[]);
		c_lvl_rho=lvl_rho(1,:)+(c_lvl-lvl_z(1,:))./diff(lvl_z).*diff(lvl_rho);
		if mod(size(c_lvl_rho,2),2)
			c_lvl_rho(1)=[];
		end
		c_lvl_rho=reshape(c_lvl_rho,[],2);
		[~,mi]=max(sum(c_lvl_rho,2));
		c_angle=sum(atan2(c_lvl_rho(mi,:),c_lvl))*180/pi;
	end
end

%% One direction point estimation function
function est=antenna_est(src_pt, antenna)
	dist= sqrt(sum(( antenna.points - src_pt(ones(size(antenna.points,1),1),:) ).^2,2)); % Расстояние от точки src_pt до каждой точки antenna.points

	expr_N=20;
	fs=expr_N*antenna.frequency;
	expr_t=(0:expr_N-1)'/fs;

	x=cell(1,length(dist));
 	for i=1:length(dist)
		x{i}=antenna.factor(i)*cos(2*pi*antenna.frequency*(expr_t+antenna.delay(i)) + 2*pi*(dist(i))/antenna.lambda);
	end

	y=antenna_est_expr(antenna.expr, x, fs, antenna.points);
	est=sqrt(mean(y.^2));
end

%% Safe place to call user's code
function y=antenna_est_expr(antenna_expr, x, fs, pt) %#ok<STOUT,INUSD>
	evalc(antenna_expr);
end

%% Find main or side lobe capacity function
function v=find_capacity(x, y, z)
	v=0;

	for i=2:size(x,1)
		for j=2:size(x,2)
			data=[x(i-1,j-1) y(i-1,j-1) z(i-1,j-1);	...
				  x(i,j-1)   y(i,j-1)   z(i,j-1);	...
				  x(i-1,j)   y(i-1,j)   z(i-1,j);	...
				  x(i,j)     y(i,j)     z(i,j)];
			v=v + abs(det(data(1:3,:))) + abs(det(data(2:4,:)));
		end
	end

	v=v/6;
end
