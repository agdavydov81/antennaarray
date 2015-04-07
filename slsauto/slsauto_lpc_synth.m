function y = slsauto_lpc_synth(e, a, b)
	y = zeros(size(e));
	if isempty(e)
		return
	end

	[~,Z] = filter(b(1,:),a(1,:),0);
	for ii = 1:size(e,1)
		[y(ii),Z] = filter(b(ii,:),a(ii,:),e(ii),Z);
	end
end
