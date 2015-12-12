function slsauto_prosody(cfg)
	pitch_data = load(slsauto_getpath(cfg,'pitch_vu'));
	lab_data = lab_read(slsauto_getpath(cfg,'lab'));
	lab_data = lab_data(strcmp('#syntagm',{lab_data.string}));
	lab_pos = [0; sort(unique([lab_data.begin]')); pitch_data(end,1)+1];
	f0_median = median(pitch_data(:,2));

	[~,snd_name,snd_ext] = fileparts(slsauto_getpath(cfg,'snd'));
	figure('Toolbar','figure', 'NumberTitle','off', 'Name',[snd_name snd_ext], 'Units','normalized', 'Position',[0 0 1 1]);
	axes_f0_unnorm = axes('Units','normalized', 'Position',[0.06 0.55 0.42 0.40]);
	hold('on');
	grid('on');
	xlabel('Time, sec');
	ylabel('F0, Hz');
	axes_f0_norm   = axes('Units','normalized', 'Position',[0.56 0.55 0.42 0.40]);
	hold('on');
	grid('on');
	xlabel('Normalized length');
	ylabel('Normalized F0');

	pal = lines();
	syntagm_length = nan(size(lab_pos));
	pause_length   = nan(size(lab_pos));
	f0_norm_rms    = nan(size(lab_pos));
	stat.intonogram.arg = linspace(0,1,101);
	stat.intonogram.val = cell(size(lab_pos));
	for li = 1:numel(lab_pos)-1
		cur_ind = (lab_pos(li)<=pitch_data(:,1)) & (pitch_data(:,1)<lab_pos(li+1));
		if isempty(cur_ind)
			continue
		end
		cur_f0 = pitch_data(cur_ind,:);
		cur_f0(:,1) = cur_f0(:,1)-cur_f0(1,1);

		cur_color = pal(randi(size(pal,1)),:);
		plot(axes_f0_unnorm, cur_f0(:,1), cur_f0(:,2), '.', 'Color',cur_color);
		plot(axes_f0_norm, cur_f0(:,1)/cur_f0(end,1), cur_f0(:,2)/f0_median, '.', 'Color',cur_color);
		cur_f0(:,2) = cur_f0(:,2)/f0_median;
		f0_norm_rms(li) = std(cur_f0(:,2));
		stat.intonogram.val{li} = interp1(cur_f0(:,1)/cur_f0(end,1), cur_f0(:,2), stat.intonogram.arg);

		syntagm_length(li) = cur_f0(end,1);
		
		ii = find(cur_ind,1);
		if ii>1
			pause_length(li) = pitch_data(ii,1)-pitch_data(ii-1,1);
		end
	end
	syntagm_length(isnan(syntagm_length)) = [];
	pause_length(isnan(pause_length)) = [];
	f0_norm_rms(isnan(f0_norm_rms)) = [];

	stat.intonogram.arg = stat.intonogram.arg(:);

	stat.intonogram.val = medfilt1(median(cell2mat(stat.intonogram.val),1),11);
	stat.intonogram.val = (stat.intonogram.val(:)-1)*median(f0_norm_rms)/std(stat.intonogram.val)+1;

	stat.intonogram.f0_median = f0_median;
	plot(axes_f0_norm, stat.intonogram.arg, stat.intonogram.val, 'Color','k', 'LineWidth',7);

	axes('Units','normalized', 'Position',[0.06 0.10 0.42 0.40]);
	[stat.syntagm_length.cdf,stat.syntagm_length.arg] = ecdf(syntagm_length);
	[stat.pause_length.cdf,stat.pause_length.arg] = ecdf(pause_length);
	plot(stat.syntagm_length.arg,stat.syntagm_length.cdf,'b.-', stat.pause_length.arg,stat.pause_length.cdf,'r.-');
	grid('on');
	xlabel('Time, sec');
	ylabel('CDF');
	legend({'Syntagm length','Pause length'},'Location','SE');

	xml_filename = slsauto_getpath(cfg,'prosody');
	if exist(xml_filename,'file')
		movefile(xml_filename, [xml_filename '.bak']);
	end
	xml_write(xml_filename, stat, 'prosody');
end
