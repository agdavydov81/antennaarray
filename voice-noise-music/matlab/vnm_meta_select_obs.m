function base=vnm_meta_select_obs(base, alg, algs) %#ok<INUSD>
	fl=fieldnames(base(1).data{1});
	rm_mask=false(size(fl));

	if isfield(alg, 'pick')
		for i=1:numel(alg.pick)
			[reg_beg reg_end]=regexp(fl,alg.pick{i});
			rm_mask = rm_mask | cellfun(@(l,b,e) not(isempty(b))&&b==1&&e==length(l), fl, reg_beg, reg_end);
		end
		rm_mask = not(rm_mask);
	end

	if isfield(alg, 'del')
		for i=1:numel(alg.del)
			[reg_beg reg_end]=regexp(fl, alg.del{i});
			rm_mask = rm_mask | cellfun(@(l,b,e) not(isempty(b))&&b==1&&e==length(l), fl, reg_beg, reg_end);
		end
	end

	if sum(rm_mask)>0
		fl(not(rm_mask))=[];
		for bi=1:numel(base)
			for fi=1:numel(base(bi).data)
				base(bi).data{fi}=rmfield(base(bi).data{fi}, fl);
			end
		end
	end
end
