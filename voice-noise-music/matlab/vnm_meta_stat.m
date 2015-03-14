function base=vnm_meta_stat(base, alg, algs) %#ok<INUSD>
	for bi=1:size(base,1)
		for fi=1:numel(base(bi).data)
			for oi=1:length(alg.obs)
				cur_obs=base(bi).data{fi}.(alg.obs{oi});
				for ai=1:length(alg.func)
					base(bi).data{fi}.(['st' num2str(ai) '_' alg.obs{oi}])=stat_expr(alg.func{ai}, cur_obs);
				end
			end
		end
	end
end

function y=stat_expr(expr, x) %#ok<STOUT,INUSD>
	evalc(expr);
end
