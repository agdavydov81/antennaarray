function obs = vnm_obs_mfcc(x, alg, algs, etc_info)
	obs=zeros(etc_info.obs_sz,alg.order);

	wnd=ones(etc_info.fr_sz(2),1);
	if isfield(alg,'window')
		wnd=window(alg.window, etc_info.fr_sz(2));
	end
	NFFT=pow2(nextpow2(etc_info.fr_sz(2)));
	NFFT2=NFFT/2+1;

	frq=linspace(0,algs.obs_general.fs/2,NFFT2);
	mel=hz2mel(frq)*alg.bands_on_4kHz/hz2mel(4000);

	band_filters=zeros(alg.bands_on_4kHz-1, NFFT2);
	for bi=1:size(band_filters,1)
		ind=mel>bi-1 & mel<=bi;		band_filters(bi,ind)=mel(ind)+1-bi;
		ind=mel>bi  & mel<bi+1;		band_filters(bi,ind)=bi+1-mel(ind);
		if alg.norm_flt
			band_filters(bi,:)=band_filters(bi,:)/sum(band_filters(bi,:));
		end
	end

	dctm=dctmtx(alg.bands_on_4kHz-1);
	dctm(alg.order+1:end,:)=[];

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;
		obs_ind=obs_ind+1;
		cur_fx=fft(cur_x, NFFT);
		cur_fx=cur_fx(1:NFFT2); % symmetric FFT one (left) half

		cur_fx=cur_fx.*conj(cur_fx); % power spectrum
		if alg.sum_magnitude
			cur_fx=sqrt(cur_fx);
		end
		
		sum_fft=band_filters*cur_fx; % spectrum -> auditory filterbanks

		sum_fft(sum_fft==0)=realmin;
		sum_fft=log(sum_fft);

		obs(obs_ind,:)=dctm*sum_fft;% dctm*sum_fft;
	end
end

function mel=hz2mel(f)
	mel=2595*log10(1+f/700);
end
