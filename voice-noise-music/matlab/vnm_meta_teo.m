function base=vnm_meta_teo(base, alg, algs)
	delay_sz=max(1, round(alg.delay_half / algs.obs_general.frame_step));

	for ai=1:numel(alg.obs)
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
				obs=base(bi).data{fi}.(alg.obs{ai});
				t_obs=	obs(delay_sz+1:end-delay_sz,:).^2 -	...
						obs(1:end-delay_sz*2,:).*obs(delay_sz*2+1:end,:);
				base(bi).data{fi}.(['t_' alg.obs{ai}]) = ...
						[repmat(t_obs(1,:),delay_sz,1); t_obs; repmat(t_obs(end,:),delay_sz,1)];
			end
		end
	end
end
