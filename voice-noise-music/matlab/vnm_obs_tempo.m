function [obs_tempo, tempo_t, tempo_val]=vnm_obs_tempo(x, alg1, etc_info)
	%% Configure algorithm
	if (nargin < 3)
		alg = alg1;
	elseif isfield(etc_info,'alg')
		alg=etc_info.alg;
	else
		alg.obs_general=	struct(	'frame_size',0.020, 'frame_step',0.005, 'fs',alg1.obs_general.fs);
		alg.obs.power=		struct(	'is_db',true, 'is_normalize',true);
		alg.meta.vad=		struct(	'power_quantile',0.25, 'power_threshold',-20, 'min_pause',0.300, 'min_speech',0.300);

		alg.obs.tone=		struct(	'window','rectwin', 'do_lpc',false, 'f0_range',[80 800], ...
									'power_quantile',0.25, 'median',0.040, 'threshold',0.7, 'min_reg_sz',0.040);
		alg.meta_obs.delta=	struct( 'obs',{{'tone'}},	'delay',0.020);

		alg.obs.pirogov=	struct(	'avr',0.020,	'diff',0.040,	'max_threshold',0.7,	'max_neighborhood',0.060,	'reg_sz',[0.045 0.250]);

		alg.obs.tempo=		alg1.obs.tempo;
	end

	fr_sz=round([alg1.obs_general.frame_step alg1.obs_general.frame_size]*alg1.obs_general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);

	%% Calculate power
	obs.power=vnm_obs_power(x, alg, etc_info);
	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
	obs.time=((0:size(obs.power,1)-1)'*fr_sz(1)+fr_sz(2)/2)/alg.obs_general.fs;

	%% VAD and speech regions
	[obs.vad, obs.speech_reg]=find_regions(obs.power > max( quantile(obs.power,alg.meta.vad.power_quantile), alg.meta.vad.power_threshold ), ...
								round(alg.meta.vad.min_pause/alg.obs_general.frame_step), ...
								round(alg.meta.vad.min_speech/alg.obs_general.frame_step));

	borders=struct('val',obs.speech_reg(:), 'style',{{'Color','r', 'LineWidth',2}}, 'name','VAD');

	%% Calculate tone
	obs.tone=vnm_obs_tone(x, alg, etc_info);
	obs.tone(obs.power < quantile(obs.power(obs.vad),alg.obs.tone.power_quantile))=0;
	obs.tone=medfilt1(obs.tone, round(alg.obs.tone.median/alg.obs_general.frame_step), [], 1);

	%% Calculate tone delta
	base=vnm_meta_delta({'none', {obs}}, alg);
	obs=base(1).data{1};

	%% Find d_tone boundaries
	min_reg_sz=round(alg.obs.tempo.min_reg_sz/alg.obs_general.frame_step);
	extr_ind_lo=find_local_extremums(obs.d_tone, @min, min_reg_sz);
	extr_ind_lo(obs.d_tone(extr_ind_lo)>alg.obs.tempo.d_tone_thresholds(1))=[];
	extr_ind_hi=find_local_extremums(obs.d_tone, @max, min_reg_sz);
	extr_ind_hi(obs.d_tone(extr_ind_hi)<alg.obs.tempo.d_tone_thresholds(2))=[];

	% Take only maximum valued extremums
	extr_ind=[extr_ind_lo; extr_ind_hi];
	[~,si]=sort(abs(obs.d_tone(extr_ind)),1,'descend');
	borders(end+1,1)=struct('val',merge_borders(borders, extr_ind(si), min_reg_sz), ...
							'style',{{'Color','m'}}, 'name','d_tone boundaries');

	%% Pirogov function borders
	[~,obs.pirogov.bord, obs.pirogov.bord_ind, obs.pirogov.obs]=vnm_obs_pirogov(x, alg, etc_info);

	%% Merge Pirogov and other borders
	[~,si]=sort(abs(obs.pirogov.obs(obs.pirogov.bord_ind)),1,'descend');
	borders(end+1,1)=struct('val',merge_borders(borders, obs.pirogov.bord_ind(si), min_reg_sz), ...
							'style',{{'Color','k'}}, 'name','Pirogov function');

	%% Prepare results
	for bi=1:length(borders)
		borders(bi).val=obs.time(borders(bi).val);
	end


	figure('Name','tempo', 'Units','normalized', 'Position',[0 0 1 1]);
	x_t=(0:size(x,1)-1)/alg.obs_general.fs;
	subplot(2,1,1);
	plot(x_t, x);
	grid('on');
	axis([x_t([1 end]) [-1 1]*1.1*max(abs(x))]);
	zoom('xon');
	pan('xon');

	for i=1:length(borders)
		cur_brd=borders(i).val;
		cur_style=borders(i).style;
		for j=1:length(cur_brd)
			line([0 0]+cur_brd(j), ylim(), cur_style{:});
		end
	end
	
	subplot(2,1,2);
	cur_palette=lines();


	%% Collect phones in VAD regions
	vad_borders=reshape(borders(1).val',[],2);
	phones_borders=sort(vertcat(borders.val));

	phones_time=zeros(size(phones_borders,1)-size(vad_borders,1),1);
	phones_len=zeros(size(phones_time));
	phones_ind=0;
	for vi=1:size(vad_borders,1)
		cur_borders = phones_borders( phones_borders>=vad_borders(vi,1) & phones_borders<=vad_borders(vi,2) );
		cur_ind=phones_ind+(1:length(cur_borders)-1);
		phones_ind=cur_ind(end);
		phones_time(cur_ind)=(cur_borders(1:end-1)+cur_borders(2:end))/2;
		phones_len(cur_ind)=diff(cur_borders);
	end
	phones_time(phones_ind+1:end)=[];
	phones_len(phones_ind+1:end)=[];
	
	if isempty(phones_len)
		fprintf('File %s tempo calculation error. Return fake values.\n', etc_info.file_name);
		obs_tempo=0;
		tempo_t=[];
		tempo_val=[];
		return
	end

	%% Calculate tempo
	phones_cum_len=[0; cumsum(phones_len)];

	tempo_val=zeros(size(phones_len));
	tempo_t=  zeros(size(phones_len));
	for i=1:length(phones_len)
		cur_ind=phones_cum_len>=phones_cum_len(i) & phones_cum_len<phones_cum_len(i)+ alg.obs.tempo.phones_median;
		if cur_ind(end) && i>1
			del_ind=tempo_val==0;
			tempo_val(del_ind)=[];
			tempo_t(del_ind)=[];
			break;
		end
		cur_ind(end)=[];
		cur_phn=phones_len(cur_ind);
		cur_t=phones_time(cur_ind);

		[hy,hx]=ecdf(1./cur_phn);
		plot(hx,hy, 'Color',cur_palette(randi(size(cur_palette,1)),:));
		hold('on');

		tempo_val(i)=1/median(cur_phn);
		[~,mi]=min(abs(mean(cur_t([1 end]))-cur_t));
		tempo_t(i)=cur_t(mi);
	end

	grid('on');
	zoom('xon');
	pan('xon');
%	xlim([0.05 0.2]);
	xlim([4 18]);

	%% Save results
	orig.fr_sz=round([alg1.obs_general.frame_step alg1.obs_general.frame_size]*alg1.obs_general.fs);
	orig.obs_sz=fix((size(x,1)-orig.fr_sz(2))/orig.fr_sz(1)+1);
	orig.time=((0:orig.obs_sz-1)'*orig.fr_sz(1)+orig.fr_sz(2)/2)/alg1.obs_general.fs;

%	obs_tempo=interp1q([0; tempo_t; orig.time(end)+0.1], [tempo_val(1); tempo_val; tempo_val(end)], orig.time);
	obs_tempo=tempo_val;
end

function extr=find_local_extremums(x, extr_fn, extr_neigh)
	extr=[];
	for i=1:length(x)
		rgn=min(length(x),max(1,[i-extr_neigh, i+extr_neigh]));
		[~,mi]=feval(extr_fn, x(rgn(1):rgn(2)));
		if i==mi+rgn(1)-1
			extr(end+1,1)=i; %#ok<AGROW>
		end
	end
end

function extr_new=merge_borders(borders, extr, min_reg_sz)
	vad_regs=reshape(borders(1).val,[],2);
	extr_ok=vertcat(borders.val);
	extr_new=[];

	for i=1:length(extr)
		if any(vad_regs(:,1)<extr(i) & extr(i)<vad_regs(:,2)) && not(any(abs(extr_ok-extr(i))<min_reg_sz))
			extr_ok(end+1,1)=extr(i); %#ok<AGROW>
			extr_new(end+1,1)=extr(i); %#ok<AGROW>
		end
	end

	extr_new=sort(extr_new);
end
