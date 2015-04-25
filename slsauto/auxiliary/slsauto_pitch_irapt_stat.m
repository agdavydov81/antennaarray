function slsauto_pitch_irapt_stat(ir0_filename, ir1_filename)
	if nargin<1
		ir0_filename = 'kaz\snd\cut.flac.pitch_021_pitchrapt(bd-).txt';
	end
	if nargin<2
		ir1_filename = 'kaz\snd\cut.flac.pitch_030_irapt(ko-).txt';
	end

	ir0_stat = df_td_stat(load(ir0_filename));
	ir1_stat = df_td_stat(load(ir1_filename));
	
	hx = sort(unique([ir0_stat.hx; ir1_stat.hx]));
	ir0_stat.hy = interp1q([hx(1); ir0_stat.hx; hx(end)], [0; ir0_stat.hy; 1], hx);
	ir1_stat.hy = interp1q([hx(1); ir1_stat.hx; hx(end)], [0; ir1_stat.hy; 1], hx);

	figure('Units','normalized', 'Position',[0 0 1 1]);
	plot(hx,1-ir0_stat.hy,'b', hx,ir1_stat.hy,'r', hx,(1-ir1_stat.hy)-(1-ir0_stat.hy),'m');
	grid('on');
	legend({ir0_filename ir1_filename},'Interpreter','none','Location','NE');
	set(pan, 'Motion','horizontal');
	zoom('xon');
end

function stat = df_td_stat(ir_data)
	ir_data(:,2) = log2(ir_data(:,2));
	diff_data = diff(ir_data);
	frame_shift = min(diff_data(:,1));

	ii = diff_data(:,1)>frame_shift*1.5;
	diff_data(ii,:) = [];

	[stat.hy,stat.hx]=ecdf(abs(diff_data(:,2)/frame_shift));
end
