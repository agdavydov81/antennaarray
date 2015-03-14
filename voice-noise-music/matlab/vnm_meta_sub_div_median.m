function base=vnm_meta_sub_div_median(base, alg, algs) %#ok<INUSD>
	for ai=1:numel(alg.obs)
		for bi=1:size(base,1)
			for fi=1:numel(base(bi).data)
				obs=base(bi).data{fi}.(alg.obs{ai});
				obs_median=repmat(median(obs,1),size(obs,1),1);
				base(bi).data{fi}.(['sdm_' alg.obs{ai}])=(obs-obs_median)./(obs_median+eps);
			end
		end
	end
end
