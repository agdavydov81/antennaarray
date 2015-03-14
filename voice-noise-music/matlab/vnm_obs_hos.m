function obs=vnm_obs_hos(x, alg, algs, etc_info) %#ok<INUSL>
	obs=zeros(etc_info.obs_sz,2);

	lpc_ord=round(algs.obs_general.fs/1000)+4;
	
	wnd=ones(etc_info.fr_sz(2),1);
	if isfield(alg,'window')
		wnd=window(alg.window, etc_info.fr_sz(2));
	end

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		obs_ind=obs_ind+1;
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;
		if all(cur_x==0)
			continue;
		end

		cur_a=vnm_lpc(cur_x, lpc_ord);
		cur_e=filter(cur_a, 1, cur_x);

		obs(obs_ind,:)=[skewness(cur_e) kurtosis(cur_e)];
	end
end
