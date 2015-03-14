function base=vnm_meta_vad(base, alg, algs)
%{
	if nargin<1
		algs=vnm_classify_cfg();
		alg=algs.meta_obs(find(strcmp('vad',{algs.meta_obs.type}),1)).params;

		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		file_name=fullfile(dlg_path,dlg_name);
		[x,fs]=wavread(file_name);
		x(:,2:end)=[];
		x=resample(x, algs.obs_general.fs, fs);

		etc_info.fr_sz=round([algs.obs_general.frame_step algs.obs_general.frame_size]*algs.obs_general.fs);
		etc_info.obs_sz=fix((size(x,1)-etc_info.fr_sz(2))/etc_info.fr_sz(1)+1);

		obs.power=vnm_obs_power(x, algs.obs(find(strcmp('power',{algs.obs.type}),1)).params, algs, etc_info);
		obs.pitch=vnm_obs_pitch(x, algs.obs(find(strcmp('pitch',{algs.obs.type}),1)).params, algs, etc_info);
		obs.time=((0:size(obs.power,1)-1)*etc_info.fr_sz(1)+etc_info.fr_sz(2)/2)/algs.obs_general.fs;

		figure('Units','normalized', 'Position',[0 0 1 1]);
		subplot(3,1,1);
		plot((0:size(x,1)-1)/algs.obs_general.fs, x);
		x_lim=[0 (size(x,1)-1)/algs.obs_general.fs];
		axis([x_lim max(abs(x))*[-1.1 1.1]]);
		grid('on');
		ylabel('signal');
		title(file_name, 'Interpreter','none');

		subplot(3,1,2);
		plot(obs.time, obs.power);
		axis([x_lim ylim()]);
		grid on;
		ylabel('power');
		power_val_rg=[min(obs.power) max(obs.power)];
		power_threshold=max(power_val_rg(2)-power_val_rg(1), alg.min_db_range) * alg.db_range_part + power_val_rg(1);
		line(x_lim, power_threshold+[0 0], 'Color','r');

		subplot(3,1,3);
		plot(obs.time, obs.pitch);
		axis([x_lim ylim()]);
		grid on;
		ylabel('pitch');
		
		cur_vad=obs.power>power_threshold;
		if isfield(alg,'pitch')
			cur_vad = cur_vad & obs.pitch;
		end

		[~, vad_reg]=find_regions(cur_vad, ...
										round(alg.min_pause/algs.obs_general.frame_step), ...
										round(alg.min_speech/algs.obs_general.frame_step));
									
		subplot(3,1,1);		plot_regions(obs.time(vad_reg));
		subplot(3,1,2);		plot_regions(obs.time(vad_reg));
		subplot(3,1,3);		plot_regions(obs.time(vad_reg));

		set(zoom,'ActionPostCallback',@on_zoom_pan);
		set(pan ,'ActionPostCallback',@on_zoom_pan);
		zoom xon;
		set(pan, 'Motion', 'horizontal');

		return;
	end
%}
	result_min_sz=0.100/algs.obs_general.frame_step;

	if isfield(alg,'result_min_sz')
		result_min_sz=alg.result_min_sz/algs.obs_general.frame_step;
	end

	for bi=1:size(base,1)
		kill_files=false(size(base(bi).data));
		for fi=1:numel(base(bi).data)
			if isfield(alg,'tone') && alg.tone
				cur_vad=base(bi).data{fi}.pitch>0;
			else
				brd=base(bi).data{fi}.borders;
				ind=brd(:,2)==1 | brd(:,2)==2;
				brd=reshape(brd(ind,1),2,[]);
				cur_vad=false(size(base(bi).data{fi}.time));
				for i=1:size(brd,2)
					cur_vad=cur_vad | (base(bi).data{fi}.time>=brd(1,i) & base(bi).data{fi}.time<brd(2,i));
				end
			end

			if sum(cur_vad)<result_min_sz
				kill_files(fi)=true;
				disp(sprintf('Warning: file [%d] "%s" was removed from base [%d] "%s" by VAD.', fi,base(bi).data{fi}.file_name, bi,base(bi).class)); %#ok<DSPS>
			else
				obs=fields(base(bi).data{fi});
				if any(strcmp(obs,'borders'))
					base(bi).data{fi}=rmfield(base(bi).data{fi},'borders');
					obs(strcmp(obs,'borders'))=[];
				end
				for oi=1:length(obs)
					if size(base(bi).data{fi}.(obs{oi}),1)==size(cur_vad,1)
						base(bi).data{fi}.(obs{oi})(not(cur_vad),:)=[];
					end
				end
			end
		end
		base(bi).data(kill_files)=[];
	end
end
