function obs=vnm_obs_pitch(x, alg, algs, etc_info) %#ok<INUSD>
	obs=sfs_rapt(x*0.9/max(abs(x)),algs.obs_general.fs, algs.obs_general);

	if isfield(alg,'log') && alg.log
		ind=obs>0;
		obs(ind)=log(obs(ind));
	end
end
