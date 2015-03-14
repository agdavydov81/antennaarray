function obs = vnm_obs_lpcc(x, alg, algs, etc_info)
	lpc_ord=round(algs.obs_general.fs/1000)+4;
	lpcc_ord=lpc_ord+4;

	obs=zeros(etc_info.obs_sz,lpcc_ord);
	
	wnd=ones(etc_info.fr_sz(2),1);
	if isfield(alg,'window')
		wnd=window(alg.window, etc_info.fr_sz(2));
	end

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		obs_ind=obs_ind+1;
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;

		[cur_a, cur_err_pwr]=vnm_lpc(cur_x, lpc_ord);
		if cur_err_pwr>0
			obs(obs_ind,:)=poly2cc(cur_a, cur_err_pwr, lpcc_ord);
		end
	end
end
