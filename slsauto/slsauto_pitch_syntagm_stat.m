function slsauto_pitch_syntagm_stat(cfg)
	pitch_data = load(slsauto_getpath(cfg,'pitch'));
	pitch_data(:,2) = []; % ЧОТ не нужна
	pitch_dt = diff(pitch_data);
	frame_shift = min(pitch_dt);
	ind = pitch_dt>frame_shift*1.1;
	unvoc_begend = [pitch_data([ind; false]) pitch_data([false; ind])]; % Границы невокализованных участков

	lab_data = lab_read(slsauto_getpath(cfg,'lab'));
	lab_data = lab_data(strcmp('#syntagm',{lab_data.string}));

	%% Вычисление статистики по длительности пауз
	syntagmas_ind = false(size(unvoc_begend,1),1);
	for li = 1:numel(lab_data)
		syntagmas_ind( (unvoc_begend(:,1)<=lab_data(li).begin) & (lab_data(li).begin<unvoc_begend(:,2)) ) = true;
		syntagmas_ind( (unvoc_begend(:,1)<=lab_data(li).end)   & (lab_data(li).end  <unvoc_begend(:,2)) ) = true;
	end

	unvoc_dt = diff(unvoc_begend,[],2);
	syntagmas_dt = unvoc_dt(syntagmas_ind);
	unvoc_dt(syntagmas_ind) = [];
	
	%% Вычисление статистики по средней мощности пауз
	[x,x_info] = libsndfile_read(slsauto_getpath(cfg,'snd'));
	x(:,2:end) = [];
	power_meandb = zeros(size(unvoc_begend,1),1);
	for ri = 1:size(unvoc_begend,1)
		cur_rg = max(1,min(numel(x),1+round(unvoc_begend(ri,:)*x_info.SampleRate)));
		cur_x = x(cur_rg(1):cur_rg(2)-1);
		power_meandb(ri) = 10*log10(mean(cur_x.*cur_x));
	end
	syntagmas_meandb = power_meandb(syntagmas_ind);
	unvoc_meandb =power_meandb(~syntagmas_ind);

	%% Отображение результатов
	[~,snd_name,snd_ext] = fileparts(slsauto_getpath(cfg,'snd'));
	figure('Toolbar','figure', 'NumberTitle','off', 'Name',[snd_name snd_ext], 'Units','normalized', 'Position',[0 0 1 1]);

	% Pause-Power PDF
	axes('Units','normalized', 'Position',[0.06 0.55 0.42 0.40]);
	plot(unvoc_dt,unvoc_meandb,'b+', syntagmas_dt,syntagmas_meandb,'ro');
	grid('on');
	xlabel('Pause length (sec)');
	ylabel('Pause mean power (db)');
	legend({'Unvocal pause','Syntagm pause'},'Location','NE');

	% Pause CDF
	axes('Units','normalized', 'Position',[0.06 0.10 0.42 0.40]);
	[pau_hy,pau_hx] = ecdf(unvoc_dt);
	[syn_hy,syn_hx] = ecdf(syntagmas_dt);
	plot(pau_hx,1-pau_hy,'b.-', syn_hx,syn_hy,'r.-');
	grid('on');
	xlabel('Pause length (sec)');
	ylabel('CDF');
	legend({'Unvocal pause','Syntagm pause'},'Location','SE');

	% Power CDF
	axes('Units','normalized', 'Position',[0.56 0.55 0.42 0.40]);
	[pau_hy,pau_hx] = ecdf(unvoc_meandb);
	[syn_hy,syn_hx] = ecdf(syntagmas_meandb);
	plot(pau_hx,pau_hy,'b.-', syn_hx,1-syn_hy,'r.-');
	grid('on');
	xlabel('Pause mean power (db)');
	ylabel('CDF');
	legend({'Unvocal pause','Syntagm pause'},'Location','SE');
end
