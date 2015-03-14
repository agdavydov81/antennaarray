function obs=vnm_obs_power(x, alg, algs, etc_info) %#ok<INUSL>
	obs=zeros(etc_info.obs_sz,1);

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		cur_x=x(i:i+etc_info.fr_sz(2)-1);
		obs_ind=obs_ind+1;
		obs(obs_ind)=mean(cur_x.*cur_x);
	end
	if obs_ind~=size(obs,1)
		error('Observation length mismatch.');
	end

	if isfield(alg,'is_db') && alg.is_db
		obs=10*log10(obs + 1e-100);
	end

	if isfield(alg,'is_normalize') && alg.is_normalize
		if isfield(alg,'is_db') && alg.is_db
			obs=obs-max(obs);
		else
			obs=obs/max(obs);
		end
	end
end
