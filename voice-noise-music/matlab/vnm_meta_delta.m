function base=vnm_meta_delta(base, alg, algs)
	delay_sz=max(1, round(alg.delay / algs.obs_general.frame_step));
	dt=delay_sz*diff(base(1).data{1}.time([1 2]));

	for ai=1:numel(alg.obs)
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
				obs=base(bi).data{fi}.(alg.obs{ai});
				base(bi).data{fi}.(['d_' alg.obs{ai}])=(obs(delay_sz+1:end,:)-obs(1:end-delay_sz,:))/dt;
			end
		end
	end
end
