function ir_test_mod(haudioplayer, eventStruct)
% subfunction
%if ~ haudioplayer.UserData.stopPlayback
%  play(haudioplayer);
	ir_test_mod_lin();
end

function ir_test_mod_xxx()
	
%	ir_test_mod_lin();
end

function ir_test_mod_lin()
	f1=1000;
	f2=8000;
	ss=2;
	T=10;
	fs = 20000;
	
	t=(0:fs*T-1)'/fs;
	
	f_n = acos(cos(t*pi/ss))/pi;
	
	f_ref = (f2-f1)*f_n+f1;
	
	f_ref = f1*(f2/f1).^(f_n);
	
	ff_ref = cumsum(f_ref)/fs;
	ff_ref = rem(ff_ref,1);

	subplot(3,1,1);
	plot(t,f_ref,'b');
	
	subplot(3,1,2);
	plot(t,ff_ref,'b');
	
	subplot(3,1,3);
	x = 0.95*cos(2*pi*ff_ref);
	plot(t,x);
	wavwrite(x, fs, 'ir_test_mod.wav');
end

function ir_test_mod_log()
	f1=1000;
	f2=8000;
	ss=1;
	T=3;
	fs = 20000;

	t=(0:fs*T-1)'/fs;

	f_ref = f1*(f2/f1).^(t/ss);

	semilogy(t,f_ref,'b');
end
