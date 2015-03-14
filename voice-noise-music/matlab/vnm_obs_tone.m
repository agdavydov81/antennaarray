function obs=vnm_obs_tone(x, alg, algs, etc_info)
	if etc_info.obs_sz==0
		obs=zeros(0,5);
		return
	end

	ncc.neigh=round(algs.obs_general.fs/alg.f0_range(2)/2);
	ncc.frame_size=round(algs.obs_general.fs./alg.f0_range(1))*2+ncc.neigh;

	t0_rg=max(2,min(etc_info.fr_sz(2), round(algs.obs_general.fs./alg.f0_range([2 1]))));
	xc_rg=etc_info.fr_sz(2)+t0_rg; %#ok<NASGU>

	lpc_ord=round(algs.obs_general.fs/1000)+4; %#ok<NASGU>
	freqz_sz=pow2(nextpow2(algs.obs_general.fs/15));
	f1_rg=min(freqz_sz, round(alg.f1_band*2*freqz_sz/algs.obs_general.fs));
	f1_rg=(f1_rg(1):f1_rg(2))+1;
	signal_rg=min(freqz_sz, round(alg.signal_band*2*freqz_sz/algs.obs_general.fs));
	signal_rg=(signal_rg(1):signal_rg(2))+1;

	wnd=hamming(etc_info.fr_sz(2));


	obs_ncc=		zeros(etc_info.obs_sz,1);
	obs_PF1toP=		zeros(etc_info.obs_sz,1);
	obs_HNR=		zeros(etc_info.obs_sz,1);
	obs_PF1db=		zeros(etc_info.obs_sz,1); % very sensetive to scaling factor
%	obs_autocorr=	zeros(etc_info.obs_sz,1);
%	obs_LPCfit=		zeros(etc_info.obs_sz,1);
	
	obs_PF1=		zeros(etc_info.obs_sz,1);
	obs_PS=			zeros(etc_info.obs_sz,1);
	
	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		x_rg=[i i+etc_info.fr_sz(2)-1];
		cur_x=x(x_rg(1):x_rg(2));
		obs_ind=obs_ind+1;

		cur_x=cur_x-mean(cur_x);

%		cur_x=cur_x.*wnd;

%		lpc0=lpc(cur_x,1);
%		cur_x=filter(lpc0,1,cur_x);

		% Normalized unbiased autocorrelation peak value
%		cur_xc=xcorr(cur_x);
%		cur_xc=cur_xc./sqrt(triang(length(cur_xc))); % unbias sqrt
%		obs_autocorr(obs_ind)=max(cur_xc(xc_rg(1):xc_rg(2)))/cur_xc(etc_info.fr_sz(2)); % linear svm rate 0.618827

		% Normalized cross-correlation
		ncc_rg=fix((x_rg(1)+x_rg(2)-ncc.frame_size)/2);
		ncc_rg(2)=ncc_rg(1)+ncc.frame_size;
		ncc_rg_mm=min(size(x,1),max(1,ncc_rg));
		ncc_frame=[zeros(-ncc_rg(1),1); x(ncc_rg_mm(1):ncc_rg_mm(2)); zeros(ncc_rg(2)-size(x,1),1)];
		ncc_frame=cur_x;
		cur_ncc=nccf(ncc_frame, t0_rg(2), 0); %a_fact=0 linear svm rate 0.808088; a_fact=0.005 linear svm rate 0.597684
		cur_ncc_max=find_local_max(cur_ncc, t0_rg+1, ncc.neigh); % !!! t0_rg+1 - MATLAB INDEXING
		obs_ncc(obs_ind)=max([0; cur_ncc_max]);

		%% Power spectrum estimation
		cur_fft=fft(cur_x, 2*freqz_sz);
		cur_fft=cur_fft.*conj(cur_fft)/(2*freqz_sz);
		cur_fft(cur_fft<=0)=realmin;
		
		obs_PF1(obs_ind)=mean(cur_fft(f1_rg));
		obs_PS(obs_ind)= mean(cur_fft(signal_rg));

		%% Mean F1 power
		obs_PF1db(obs_ind)=10*log10(sum(cur_fft(f1_rg))); % linear svm rate 0.600795

		%% Mean F1 power to signal power ratio
		obs_PF1toP(obs_ind)=mean(cur_fft(f1_rg)) / mean(cur_fft(signal_rg)); % linear svm rate 0.588436

		%% Real cepstrum noise estimation
		cur_fft_log=10*log10(cur_fft);
		cur_rceps=ifft(cur_fft_log);
		cur_rceps(t0_rg(1)+1:end-t0_rg(1)+1)=0;
		noise_H_log=real(fft(cur_rceps));
%		noise_H=10.^(noise_H_log/10);

%		disp_cur_frame(cur_x, algs.obs_general.fs, cur_fft, noise_H);

		% Harmonics-to-noise ratio
		harm_ind=false(size(cur_fft_log));
		harm_ind(signal_rg)=true;
		harm_ind=(cur_fft_log>noise_H_log) & harm_ind;
		harm_ind(freqz_sz+1:end)=false;	% symmetric part ignore
%		obs_HNR(obs_ind)=10*log10(sum(cur_fft(harm_ind) - noise_H(harm_ind))/freqz_sz); % linear svm rate 0.618141
%		obs_HNR(obs_ind)=10*log10(sum(cur_fft(harm_ind) ./ (noise_H(harm_ind)+realmin))/freqz_sz); % linear svm rate 0.515009
		obs_HNR(obs_ind)=sum(cur_fft_log(harm_ind) - noise_H_log(harm_ind)) / (signal_rg(end)-signal_rg(1)+1); % linear svm rate 0.614107

		% Prediction effectivity -- dramaticaly vary on different sampling rates
%		[~, cur_err_pwr]=lpc(cur_x,lpc_ord);
%		obs_LPCfit(obs_ind)=10*log10(mean(cur_x.*cur_x))-10*log10((cur_err_pwr+realmin)); % linear svm rate 0.574562
	end

	obs_fs=algs.obs_general.fs/etc_info.fr_sz(1);
	obs_flt=fir1(round(obs_fs/2)*2, 1/obs_fs);
	z_sz=min(round(obs_fs/10),etc_info.obs_sz);
	obs_PS_flt=filter(obs_flt, 1, [obs_PS; zeros(fix(length(obs_flt)/2),1) + median(obs_PS(end-z_sz+1:end))], ...
										   zeros(    length(obs_flt)-1, 1) + median(obs_PS(1:z_sz)) );
	obs_PS_flt(1:fix(length(obs_flt)/2))=[];


	%% Is tone linear SVM
	obs_svm=[obs_ncc   obs_PF1toP   obs_HNR]; % 10*log10(obs_PF1+1e-9)-10*log10(obs_PS_flt+1e-9)];
%{
	is_tone_linear_svm_A=[3.5112262700483958E+000;  -8.3528002392955591E-001;  3.3660106555395583E-004;  7.8507380429211390E-002];
	is_tone_linear_svm_B=-1.2263983576811812E+000;

	is_tone=obs_svm * is_tone_linear_svm_A + is_tone_linear_svm_B > 0;
	med_sz=round(alg.median/algs.obs_general.frame_step/2)*2+1;
	if med_sz>1
		is_tone=medfilt1( medfilt1(double(is_tone), med_sz,[],1), med_sz,[],1)>0.5;
	end

	obs=[is_tone obs_svm];
%}
	obs=obs_svm;
end

function phi=nccf(s, frame_size, a_fact)
%	s=s-mean(s);
%{
	s1=buffer(s, frame_size, frame_size-1, 'nodelay');
	pwr=sum(buffer(s.^2, frame_size, frame_size-1, 'nodelay'));

	phi=(transpose(s1(:,1))*s1) ./ sqrt(a_fact+pwr(1)*pwr);

	vb_nccfd=vb_normxcor(s(1:frame_size),s);
%}
	phi_sz=1+length(s)-frame_size;

	sx=xcorr(s, s(1:frame_size));
	sx=sx(fix(length(sx)/2)+(1:phi_sz));

	ss=cumsum(s.^2);
	ss=ss(frame_size:end)-[0; ss(1:phi_sz-1)];
	phi=sx ./ sqrt(a_fact*frame_size + ss(1)*ss);
end

function [max_val, max_ind]=find_local_max(x, rg, neigh)
	max_ind=[];

	for i=rg(1):rg(2)
		[~,mi]=max(x(i-neigh:i+neigh));
		if mi==neigh+1
			max_ind(end+1)=i; %#ok<AGROW>
		end
%		if(max_ind<=i)
%			i=max_ind+xc_local_max_neigh+1;
%		else
%			i=max_ind;
%		end
	end

	max_val=x(max_ind);
end

%% plot signal and noise spectrum density approximation
function disp_cur_frame(cur_x, fs, cur_fft, noise_H) %#ok<DEFNU>
	subplot(3,1,1);
	plot((0:length(cur_x)-1)/fs, cur_x);
	grid('on');
	axis([0 (length(cur_x)-1)/fs max(abs(cur_x))*1.1*[-1 1]]);

	w=linspace(0,(length(cur_fft)-1)*fs/(2*length(cur_fft)), length(cur_fft));
	subplot(3,1,2);
	plot(w,sqrt(cur_fft),'b', w,sqrt(noise_H),'m');
	grid('on'); xlim([0 fs/2]);

	subplot(3,1,3);
	plot(w,10*log10(cur_fft),'b', w,10*log10(noise_H),'m');
	grid('on'); xlim([0 fs/2]);
end
