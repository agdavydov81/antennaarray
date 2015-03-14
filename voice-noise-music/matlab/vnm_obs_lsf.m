function obs=vnm_obs_lsf(x, alg, algs, etc_info)
	lpc_ord=round(algs.obs_general.fs/1000)+4;

	obs=zeros(etc_info.obs_sz,lpc_ord);

	wnd=ones(etc_info.fr_sz(2),1);
	if isfield(alg,'window')
		wnd=window(alg.window, etc_info.fr_sz(2));
	end

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;
		obs_ind=obs_ind+1;
		cur_a=vnm_lpc(cur_x, lpc_ord);
		obs(obs_ind,:)=poly2lsf(cur_a);
	end
end
