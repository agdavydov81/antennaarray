function xc=xcorr_up(x, scale)
	if nargin<1
		x=randn(10,1);
	end
	if nargin<2
		scale=16;
	end

	x_next2=2^nextpow2(size(x,1));
	fx=fft(x, 2*x_next2);
	fx=fx.*conj(fx);
	fx(x_next2+2:end)=[];
	if scale>1
		fx(end)=fx(end)/2;
	end
	fx=[fx; zeros(x_next2*(scale-1),1)];
	fx=[fx; fx(end-1:-1:2)];
	xc=scale*ifft(fx);
	xc((length(x)-1)*scale+2:end)=[];
	xc=xc./sqrt((length(x)*scale:-1:scale)'/length(x)/scale);

	if nargout<1
		xc_ref=xcorr(x);
		xc_ref=xc_ref./sqrt(triang(length(xc_ref)));
		xc_ref(1:length(x)-1)=[];

		figure('Name','xcorr_up test', 'Units','normalized', 'Position',[0 0 1 1]);
		t=0:length(xc_ref)-1;
		plot(t,xc_ref,'b+-');
		hold on;
		t_up=(0:length(xc)-1)/scale;
		plot(t_up,xc,'k');
		plot(t_up,spline(t,xc_ref,t_up),'m');
		grid on;
		legend('Original xcorr','MY FFT interpolation','Spline interpolation');

		clear xc;
	end
end
