function obs=vnm_obs_time(x, alg, algs, etc_info) %#ok<INUSL>
	obs=((0:etc_info.obs_sz-1)'*etc_info.fr_sz(1)+etc_info.fr_sz(2)/2)/algs.obs_general.fs;
end
