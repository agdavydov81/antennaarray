function base=vnm_meta_nomean(base, alg, algs) %#ok<INUSD>
	for ai=1:numel(alg.obs)
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
				obs=base(bi).data{fi}.(alg.obs{ai});
				base(bi).data{fi}.(['m_' alg.obs{ai}])=obs-repmat(mean(obs,1),size(obs,1),1);
			end
		end
	end
end
