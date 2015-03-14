function obs = vnm_obs_rceps(x, alg, algs, etc_info) %#ok<INUSL>
	obs=zeros(etc_info.obs_sz,alg.order);

	wnd=ones(etc_info.fr_sz(2),1);
	if isfield(alg,'window')
		wnd=window(alg.window, etc_info.fr_sz(2));
	end
	NFFT=pow2(nextpow2(etc_info.fr_sz(2)));

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;
		obs_ind=obs_ind+1;
		cur_fx=fft(cur_x', NFFT);
		cur_psd=cur_fx.*conj(cur_fx);
		cur_psd(cur_psd==0)=realmin;
		cur_rc=real(ifft(10*log10(cur_psd)));
		obs(obs_ind,:)=cur_rc(1:alg.order);
	end
end
