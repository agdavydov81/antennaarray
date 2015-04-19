function slsauto_pitch_vu2lab(cfg, peak_neigh_t, peak_neigh_val, reg_size_t)
	if nargin<2
		peak_neigh_t = 0.040;
	end
	if nargin<3
		peak_neigh_val = 0.5;
	end
	if nargin<4
		reg_size_t = 0.080;
	end

	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	fs = x_info.SampleRate;
	[power.obs power.time] = obs_power(x, fs, 0.020, 0.001);
	
	power_fs = 1/min(diff(power.time));
	b = conv( fir1(round(power_fs*0.5), 33*2/power_fs), [1 -1]);
	ord2 = fix(numel(b)/2);
	power.diff = filter(b,1,[power.obs; zeros(ord2,1)]);
	power.diff(1:ord2) = [];
	power.max_ind = find_local_max(power.diff, round(power_fs*0.030), peak_neigh_val);
	power.max_t = power.time(power.max_ind);
	power.min_ind = find_local_max(-power.diff, round(power_fs*0.030), peak_neigh_val);
	power.min_t = power.time(power.min_ind);

	pitch_vu = load(slsauto_getpath(cfg,'pitch_vu'));
	pitch_dt = diff(pitch_vu(:,1));
	voc_reg = [0; find(pitch_dt>=min(pitch_dt)*1.5); size(pitch_vu,1)];
	lab_vu(2*(numel(voc_reg)-1),1) = struct('begin',0,'end',0,'string','');
	kill_ind = false(size(lab_vu));
	for vi = 1:numel(voc_reg)-1
		% Уточнение границы V-U: поиск ближайшего локального максимума в power.max_t
		[mv,mi] = min(abs(pitch_vu(voc_reg(vi)+1,1) - power.max_t));
		if mv < peak_neigh_t
			lab_vu(vi*2-1) = struct('begin',power.max_t(mi), 'end',power.max_t(mi), 'string','#pitch_v');
		else
			kill_ind(vi*2-1) = true;
		end

		% Уточнение границы U-V: поиск ближайшего локального минимума в power.min_t
		[mv,mi] = min(abs(pitch_vu(voc_reg(vi+1),1) - power.min_t));
		if mv < peak_neigh_t
			lab_vu(vi*2) = struct('begin',power.min_t(mi), 'end',power.min_t(mi), 'string','#pitch_u');
		else
			kill_ind(vi*2) = true;
		end
	end
	lab_vu(kill_ind) = [];

	% Правка ошибок в последовательности и объединение коротких участков
	while true
		[mv,mi] = min(diff([lab_vu.begin]));
		if isempty(mi) || mv>=reg_size_t
			break
		end
		[~,mii]=min(abs([peak_val(lab_vu(mi),power) peak_val(lab_vu(mi+1),power)]));
		lab_vu(mi+mii-1) = [];
	end

	% Сохранение результатов
	if ~exist(slsauto_getpath(cfg,'lab'),'file')
		lab = struct('begin',[],'end',[],'string',{});
	else
		lab = lab_read(slsauto_getpath(cfg,'lab'));
	end
	lab(strcmp('#pitch_v',{lab.string})) = [];
	lab(strcmp('#pitch_u',{lab.string})) = [];

	lab_write([lab; lab_vu], slsauto_getpath(cfg,'lab'));
	
%	plot_data(cfg, x,fs, power, pitch_vu);
end

function val = peak_val(lab, power)
	if strcmp(lab.string,'#pitch_V')
		obs = power.max_t;
		ind = power.max_ind;
	else
		obs = power.min_t;
		ind = power.min_ind;
	end
	val = power.diff(ind(obs==lab.begin));
end

function [obs_power, obs_time] = obs_power(x, fs, frame_size, frame_shift)
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

function plot_data(cfg, x,fs, power, pitch_vu)
	[~,snd_name] = fileparts(slsauto_getpath(cfg,'snd'));
	fig = figure('NumberTitle','off', 'Name',snd_name, 'Units','normalized', 'Position',[0 0 1 1]);
	
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
	
	set(pan ,'ActionPostCallback',@on_zoom_pan, 'Motion','horizontal');
	set(zoom,'ActionPostCallback',@on_zoom_pan);
	zoom('xon');
	
	fig_data = guihandles(fig);
	fig_data.user_data.x_len = x_lim(2);
	guidata(fig,fig_data);
end
