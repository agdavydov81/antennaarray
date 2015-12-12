function test_fan_chirp()
	make_chirp_test();

	load('test_fan_chirp.mat','x','fs');
	
	frame_size = 0.030;
	M = round(frame_size*fs/2)*2;
%	F0_min =100;
%	F0_bin = floor(M/2+1)/(fs/2/F0_min);
%	disp(F0_bin);

	cur_frame = x(1:M);
	cur_fc = DFcT(cur_frame, 0, fs);

end

function X = DFcT(x, alpha, fs)
	M = length(x);
	N = length(x);
	X = zeros(size(x));
	Ts = 1/fs;
	alpha_hat = alpha * Ts;

	for k=0:M-1
		sum = 0;
		for n = -(M-1)/2 : (M-1)/2
			sum = sum + x(n+ (M-1)/2+1) * sqrt(abs(1+alpha*n)) * exp(-1i * (2*pi*k/N) * (1+0.5*alpha_hat*n)*n);
		end
		X(k+1) = sum;
	end
end

function make_chirp_test()
	fs = 44100;
	F0 = 150;
	t = 3;

	harm_num = floor(0.9*fs/2/F0);

	t = (0:t*fs-1)'/fs;
	F0 = F0 .* pow2(t) .* (1+0.1*sin(2*pi*6*t)); % Рост ЧОТ на 1 октаву/секунду с модуляцией (вибрато) частотой 6 Гц и амплитудой модуляции 0.1 ЧОТ
	F0 = repmat(F0,1,harm_num) .* repmat(1:harm_num,size(F0,1),1);
	A0 = 1./F0; % Спектральная спотность мощности розового шума
	A0 = A0 .* (1-1./(1+exp(-(  F0/(fs/2) -0.9)*100))); % Сглаживание по амплитуде края спектральной плитности мощности близкого к fs/2
	A0(F0>=fs/2) = 0;
	Phi0 = rand(1,harm_num)*2*pi;

	x = polyharm(fs, size(F0,1), F0, A0, Phi0);
	x = sum(x,2);
	x = 0.9*x/max(abs(x));
	
	wavwrite(x, fs, 'test_fan_chirp.wav');
	save('test_fan_chirp.mat','x','fs','t','harm_num','F0','A0','Phi0','-v7.3')
end

function y=polyharm(fs, len, F0, A, Phi)
	t=(0:len-1)'/fs;

	if nargin<4;	A=ones(size(F0));		end;
	if nargin<5;	Phi=zeros(size(F0));	end;

	if size(F0,1)==1;	F0=repmat(F0,size(t,1),1);	end;
	if size(A,1)==1;	A=repmat(A,size(t,1),1);	end;
	if size(Phi,1)==1;	Phi=repmat(Phi,size(t,1),1);end;

	ff=cumtrapz(t,F0);
	y=A.*cos(2*pi*ff+Phi);
end
