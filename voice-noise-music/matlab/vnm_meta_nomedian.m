function base=vnm_meta_nomedian(base, alg, algs) %#ok<INUSD>
	for ai=1:numel(alg.obs)
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
				obs=base(bi).data{fi}.(alg.obs{ai});
				base(bi).data{fi}.(['md_' alg.obs{ai}])=obs-repmat(median(obs,1),size(obs,1),1);
			end
		end
	end
end
