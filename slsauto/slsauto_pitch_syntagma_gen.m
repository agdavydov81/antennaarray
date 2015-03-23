function slsauto_pitch_syntagma_gen(snd_pathname, lab_pathname, pitch_pathname, pause_size)
	pitch_data = load(pitch_pathname);
	pitch_data(pitch_data(:,2)==0,:) = [];
	pitch_data(:,2) = []; % ЧОТ не нужна
	pitch_dt = diff(pitch_data);
	frame_shift = min(pitch_dt);
	ind = pitch_dt>frame_shift*1.1;
	unvoc_begend = [pitch_data([ind; false]) pitch_data([false; ind])]; % Границы невокализованных участков
	ind = diff(unvoc_begend,[],2)>=pause_size;
	lab_pos = mean(unvoc_begend(ind,:),2);
	lab_info = struct('begin',num2cell(lab_pos), 'end',num2cell(lab_pos), 'string',repmat({'syntagma'},size(lab_pos)));
	lab_write(lab_info, lab_pathname);
end
