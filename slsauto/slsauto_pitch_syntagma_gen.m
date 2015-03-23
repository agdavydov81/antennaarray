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

%{
	lab_data = lab_read();

	syntagmas_ind = false(size(unvoc_pos));
	for li = 1:numel(lab_data)
		syntagmas_ind( find(unvoc_pos<=lab_data(li).begin,1,'last') ) = true;
		syntagmas_ind( find(unvoc_pos<=lab_data(li).end,1,'last') ) = true;
	end
	syntagmas_ind(end) = [];

	unvoc_dt = diff(unvoc_pos);
	syntagmas_dt = unvoc_dt(syntagmas_ind);
	unvoc_dt(syntagmas_ind) = [];

	figure('NumberTitle','off', 'Name',['Syntagma: ' snd_name snd_ext], 'Units','normalized', 'Position',[0 0 1 1]);
	[unvoc_hy,unvoc_hx] = ecdf(unvoc_dt);
	[sntgm_hy,sntgm_hx] = ecdf(syntagmas_dt);
	plot(unvoc_hx,1-unvoc_hy,'b.-', sntgm_hx,sntgm_hy,'r.-');
	grid('on');
	legend({'Unvocal pause size','Syntagma pause size'},'Location','SE');
	legend('boxoff');
%}
end
