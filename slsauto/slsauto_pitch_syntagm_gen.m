function slsauto_pitch_syntagm_gen(cfg, pause_size, pause_meandb)
	if nargin<2 || isempty(pause_size)
		pause_size = 0.5;
	end
	if nargin<3 || isempty(pause_meandb)
		pause_meandb = -30;
	end


	pitch_data = load(slsauto_getpath(cfg,'pitch'));
	pitch_data(:,2) = []; % ЧОТ не нужна
	pitch_dt = diff(pitch_data);
	frame_shift = min(pitch_dt);
	ind = pitch_dt>frame_shift*1.1;
	unvoc_begend = [pitch_data([ind; false]) pitch_data([false; ind])]; % Границы невокализованных участков

	% Ограничение по длительности пауз
	unvoc_begend( diff(unvoc_begend,[],2)<pause_size, : ) = [];

	% Ограничение по средней мощности пауз
	[x,x_info] = libsndfile_read(cfg.snd_pathname);
	x(:,2:end) = [];
	power_meandb = zeros(size(unvoc_begend,1),1);
	for ri = 1:size(unvoc_begend,1)
		cur_rg = max(1,min(numel(x),1+round(unvoc_begend(ri,:)*x_info.SampleRate)));
		cur_x = x(cur_rg(1):cur_rg(2)-1);
		power_meandb(ri) = 10*log10(mean(cur_x.*cur_x));
	end
	unvoc_begend( power_meandb>pause_meandb, : ) = [];
	
	lab_pos = mean(unvoc_begend,2);
	lab_info = struct('begin',num2cell(lab_pos), 'end',num2cell(lab_pos), 'string',repmat({'syntagm'},size(lab_pos)));
	lab_write(lab_info, slsauto_getpath(cfg,'lab'));
end
