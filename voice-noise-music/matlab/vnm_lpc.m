function [a,E]=vnm_lpc(x, N)
	[a,E]=lpc(x,N);
	fix_ind=isnan(E);
	E(fix_ind)=0;
	a(fix_ind,:)=0;
	a(fix_ind,1)=1;

	r=roots(a);
	r_l=abs(r);
	if any(r_l>0.999)
		r_a=angle(r);
		r_l(r_l>0.999)=0.999;
		r=r_l.*exp(r_a*1i);
		a=real(poly(r));
	end
end
