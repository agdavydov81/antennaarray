function slsauto_vu2lab(cfg, peak_neigh_t, peak_neigh_val, reg_size_t)
	if nargin<2
		peak_neigh_t = 0.029;
	end
	if nargin<3
		peak_neigh_val = 1.5;
	end
	if nargin<4
		reg_size_t = 0.080;
	end
	alg.peak_neigh_t = peak_neigh_t;
	alg.peak_neigh_val = peak_neigh_val;
	alg.reg_size_t = reg_size_t;

	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	fs = x_info.SampleRate;

	power = calc_power_obs(cfg, alg, x, fs);

	[lab_data.lab_vu pitch_vu] = split_pitch_vu(cfg, alg, power); % Начальная сегментация

	[lab_data.lab_syntagm lab_data.lab_lpc lpc] = split_lpc_b(cfg, alg, power, pitch_vu, lab_data.lab_vu); % Cегментация по коэффициенту усиления линейного предсказания

	save_lab(cfg, [lab_data.lab_vu; lab_data.lab_lpc]); % Сохранение результатов

	plot_data(cfg, alg, x,fs, power, pitch_vu, lpc, lab_data);
end

function [lab_syntagm lab_lpc lpc] = split_lpc_b(cfg, alg, power, pitch_vu, lab_vu)
	load(slsauto_getpath(cfg,'lpc'));
	lpc.b = 20*log10(lpc_b);

%	noise_lvl = mean(quantile(lpc.b, [0.03 0.97]));
	noise_lvl = quantile(lpc.b, 0.2);
	lpc.b(lpc.b<noise_lvl) = noise_lvl;

	lpc.time = (lpc_lsf_ind-1)/fs;
	lpc.fs = 1/(lpc.time(2)-lpc.time(1));
	gauss_b =  gaussfilter(100/(lpc.fs/2));
	gauss_bd = conv(gauss_b, [1 -1]*2);
	lpc.b = filter_fir_nodelay(gauss_bd, lpc.b);

	lpc.b = zscore(lpc.b);

	lpc.max_ind = find_local_max(lpc.b,  round(lpc.fs*alg.peak_neigh_t*0.75), alg.peak_neigh_val);
	lpc.min_ind = find_local_max(-lpc.b, round(lpc.fs*alg.peak_neigh_t*0.75), alg.peak_neigh_val);

	extr_t = [        lpc.time(lpc.max_ind)     lpc.b(lpc.max_ind);			lpc.time(lpc.min_ind) -lpc.b(lpc.min_ind)];
	extr_t = [extr_t; power.time(power.max_ind) power.diff(power.max_ind);	power.time(power.min_ind) -power.diff(power.min_ind)];

	[~,si] = sort(extr_t(:,2),'descend');
	extr_t =  extr_t(si, 1);

	lab_syntagm = lab_read(slsauto_getpath(cfg,'lab'));
	lab_syntagm = lab_syntagm(strcmp('#syntagm',{lab_syntagm.string}));
	lab_syntagm_t = [lab_syntagm.begin]';

	pitch_vu_t = pitch_vu(:,1);
	pitch_ind = arrayfun(@(x) find(pitch_vu_t<x,1,'last'), lab_syntagm_t);
	pause_reg_t = [-100 pitch_vu_t(1); pitch_vu_t(pitch_ind) pitch_vu_t(pitch_ind+1); pitch_vu_t(end) lpc.time(end)+100];
	pause_reg_t(:,1) = pause_reg_t(:,1) + alg.peak_neigh_t*2;
	pause_reg_t(:,2) = pause_reg_t(:,2) - alg.peak_neigh_t*2;
	extr_t(arrayfun(@(x) any(pause_reg_t(:,1)<x & x<pause_reg_t(:,2)), extr_t)) = [];

	extr_t = [[lab_vu.begin]'; extr_t];
	extr_t_ind = arrayfun(@(x) find(abs(extr_t-x)<alg.peak_neigh_t,1), extr_t);
	extr_t(extr_t_ind<(1:numel(extr_t))') = nan;
	extr_t(1:numel(lab_vu)) = nan;
	extr_t(isnan(extr_t)) = [];

	lab_lpc = struct('begin',num2cell(extr_t), 'end',num2cell(extr_t), 'string',repmat({'#seg_a'},size(extr_t)));
end

function [lab_vu pitch_vu] = split_pitch_vu(cfg, alg, power)
	pitch_vu = load(slsauto_getpath(cfg,'pitch_vu'));
	pitch_dt = diff(pitch_vu(:,1));
	voc_reg = [0; find(pitch_dt>=min(pitch_dt)*1.5); size(pitch_vu,1)];
	lab_vu(2*(numel(voc_reg)-1),1) = struct('begin',0,'end',0,'string','');
	kill_ind = false(size(lab_vu));
	for vi = 1:numel(voc_reg)-1
		% Уточнение границы V-U: поиск ближайшего локального максимума в power.max_t
		[mv,mi] = min(abs(pitch_vu(voc_reg(vi)+1,1) - power.max_t));
		if mv < alg.peak_neigh_t
			lab_vu(vi*2-1) = struct('begin',power.max_t(mi), 'end',power.max_t(mi), 'string','#seg_v');
		else
			kill_ind(vi*2-1) = true;
		end

		% Уточнение границы U-V: поиск ближайшего локального минимума в power.min_t
		[mv,mi] = min(abs(pitch_vu(voc_reg(vi+1),1) - power.min_t));
		if mv < alg.peak_neigh_t
			lab_vu(vi*2) = struct('begin',power.min_t(mi), 'end',power.min_t(mi), 'string','#seg_u');
		else
			kill_ind(vi*2) = true;
		end
	end
	lab_vu(kill_ind) = [];

	% Правка ошибок в последовательности и объединение коротких участков
	while true
		[mv,mi] = min(diff([lab_vu.begin]));
		if isempty(mi) || mv>=alg.reg_size_t
			break
		end
		[~,mii]=min(abs([peak_val(lab_vu(mi),power) peak_val(lab_vu(mi+1),power)]));
		lab_vu(mi+mii-1) = [];
	end
end

function save_lab(cfg, lab_vu)
	lab = lab_read(slsauto_getpath(cfg,'lab'));
	ref_str = '#seg_';
	lab(strncmp(ref_str,{lab.string},numel(ref_str))) = [];

	lab_filename = slsauto_getpath(cfg,'lab');
	if exist(lab_filename,'file')
		movefile(lab_filename, [lab_filename '.bak']);
	end
	lab_write([lab; lab_vu], lab_filename);
end

function val = peak_val(lab, power)
	if strcmp(lab.string,'#seg_v')
		obs = power.max_t;
		ind = power.max_ind;
	else
		obs = power.min_t;
		ind = power.min_ind;
	end
	val = power.diff(ind(obs==lab.begin));
end

function power = calc_power_obs(cfg, alg, x, fs)
	[power.obs power.time] = obs_power_raw(x, fs, 0.020, 0.001);

	power.noise_lvl = mean(quantile(power.obs, [0.03 0.97]));
	power.obs(power.obs<power.noise_lvl) = power.noise_lvl;

	power_fs = 1/min(diff(power.time));
	b = conv( fir1(round(power_fs/2), [10 100]*2/power_fs), [1 -1]);
	power.diff = filter_fir_nodelay(b, power.obs);
	
	power.diff = zscore(power.diff);

	power.max_ind = find_local_max(power.diff, round(power_fs*alg.peak_neigh_t*0.75), alg.peak_neigh_val);
	power.max_t = power.time(power.max_ind);
	power.min_ind = find_local_max(-power.diff, round(power_fs*alg.peak_neigh_t*0.75), alg.peak_neigh_val);
	power.min_t = power.time(power.min_ind);
end

function [obs_power, obs_time] = obs_power_raw(x, fs, frame_size, frame_shift)
	frame_size  = round(frame_size*fs);
	frame_shift = round(frame_shift*fs);

	obs_sz = fix((size(x,1)-frame_size)/frame_shift+1);

	obs_time  = ((0:obs_sz-1)'*frame_shift+frame_size/2)/fs;
	obs_power = zeros(obs_sz,1);

	obs_ind=0;
	for i=1:frame_shift:size(x,1)-frame_size+1
		cur_x = x(i:i+frame_size-1);
		obs_ind = obs_ind+1;
		obs_power(obs_ind) = mean(cur_x.*cur_x);
	end
	if obs_ind~=size(obs_power,1)
		error('Observation length mismatch.');
	end

	obs_power = 10*log10(obs_power + 1e-100);
end

function extr = find_local_max(x, extr_neigh, extr_val)
	extr = zeros(max(10,round(numel(x)/(2*extr_neigh))),1);
	extr_ind = 0;
	i = 1;
	while i<=numel(x)
		rgn = min(numel(x),max(1,[i-extr_neigh, i+extr_neigh]));
		[~,mi] = max(x(rgn(1):rgn(2)));
		ref_pos = mi+rgn(1)-1;
		if i==ref_pos && x(i)>=extr_val
			extr_ind = extr_ind+1;
			extr(extr_ind) = i;
		end
		if i<ref_pos
			i = ref_pos;
		else
			i = i+1;
		end
	end
	extr(extr_ind+1:end) = [];
end

function plot_data(cfg, alg, x,fs, power, pitch_vu, lpc, lab_data)
	fig = figure('NumberTitle','off', 'Name',slsauto_getpath(cfg,'snd'), 'Units','normalized', 'Position',[0 0 1 1]);
	
	x_lim = [0 (size(x,1)-1)/fs];
	
	subplot(3,1,1);
	plot((0:size(x,1)-1)/fs, x);
	axis([x_lim 1.1*[-1 1]*max(abs(x))]);
	grid('on');

	subplot(3,1,2);
	plot(pitch_vu(:,1), pitch_vu(:,2), 'b.');
	xlim(x_lim);
	grid('on');

	subplot(3,1,3);
	plot(power.time, power.diff);
	xlim(x_lim);
	grid('on');
	hold('on');
	plot(lpc.time, lpc.b, 'r');
	legend({'power.diff' 'lpc.b'}, 'Interpreter','none', 'Location','NE');
	plot([x_lim nan x_lim], alg.peak_neigh_val*[1 1 nan -1 -1], 'm--');

	plot_lab(fig, lab_data);

	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
	set(zoom,'ActionPostCallback',@on_zoom_pan);
	zoom('xon');

	fig_data = guihandles(fig);
	fig_data.user_data.x_len = x_lim(2);
	guidata(fig,fig_data);
end

function plot_lab(fig, lab_data)
	child=get(fig,'Children');
	ax_obj = child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) );
	
	color_ring = {'b' 'k' 'r' 'm' 'g'};

	lab_names = fieldnames(lab_data);
	for li = 1:numel(lab_names)
		lab = lab_data.(lab_names{li});

		lab_x =	[[lab.begin]; [lab.begin]; nan(1,numel(lab))];
		lab_x = lab_x(:);

		for ai = 1:numel(ax_obj)
			ax = ax_obj(ai);
			hold(ax,'on');
			lab_y = repmat([ylim(ax) nan]', numel(lab), 1);
			plot(ax, lab_x, lab_y, color_ring{1});
		end

		color_ring = color_ring([2:end 1]);
	end
end
