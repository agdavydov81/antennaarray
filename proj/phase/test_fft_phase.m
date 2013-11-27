function test_fft_phase()
	test_OLA();
end

function test_OLA()
	fft_sz = 512;
	fft_sz2 = fft_sz/2+1;

	[x, fs] = wavread('test_fan_chirp44.wav'); x(1:1000)=[];  x(10001:end)=[];
%{
	fs = 1000; t = (0:fs-1)'/fs;
	for f_i = 1:fft_sz/2
		x = x + cos(2*pi*f_i/(fft_sz/2)*t + 0.1);
	end
%	x = cos(2*pi*10*(0:fs-1)'/fs+0.1);
	X = exp(2*pi*1i*(0:fft_sz-1)' + 2*pi*rand(fft_sz,1));
	x = ifft([X; 0; conj(X(end:-1:2))]);
%}

	fi = 20;
	fc = (fi-1)*fs/fft_sz;
	fb = fs/fft_sz;

	t = (0:size(x,1)-1)'/fs;
	x = 0.8*cos(2*pi*fc*t + sin(2*pi*0.5*fb*t));
	wavwrite(x,fs,'xxxx.wav');

	S1 = spectrogram_phased_buf(x, rectwin(fft_sz), fft_sz-1);
	S2 = spectrogram_phased_buf(x, hamming(fft_sz), fft_sz-1);
	S3 = spectrogram_phased_buf(x, blackmanharris(fft_sz), fft_sz-1);

%	figure('Units','normalized', 'Position',[0 0 1 1]);
%	subplot(1,2,1); imagesc(angle(S1)); axis('xy'); colormap(gray); subplot(1,2,2); imagesc(angle(S2)); axis('xy'); colormap(gray);

	figure('Units','normalized', 'Position',[0 0 1 1]);
	subplot(3,1,1);
	bb = fir1(fft_sz, (fc+fb.*[-1 1]/2)/(fs/2), rectwin(fft_sz+1));			plot(filtfilt(bb,1,x),'b');
	hold('on');
	bb = fir1(fft_sz, (fc+fb.*[-1 1]/2)/(fs/2), hamming(fft_sz+1));			plot(filtfilt(bb,1,x),'r');
	bb = fir1(fft_sz, (fc+fb.*[-1 1]/2)/(fs/2), blackmanharris(fft_sz+1));	plot(filtfilt(bb,1,x),'g');
	
	subplot(3,1,2);
	plot(abs(S1(fi,:)).*cos(2*pi*fs*fi/fft_sz*(0:size(S1,2)-1)/fs + angle(S1(fi,:))),'b');
	hold('on');
	plot(abs(S2(fi,:)).*cos(2*pi*fs*fi/fft_sz*(0:size(S2,2)-1)/fs + angle(S2(fi,:))),'r');
	plot(abs(S3(fi,:)).*cos(2*pi*fs*fi/fft_sz*(0:size(S3,2)-1)/fs + angle(S3(fi,:))),'g');

	subplot(3,1,3);
	plot(angle(S1(fi,:)),'b');
	hold('on');
	plot(angle(S2(fi,:)),'r');
	plot(angle(S3(fi,:)),'g');
end

function test_generation()
	fft_sz = 512;
	k = 2;
	
	[x fs] = wavread('test_fan_chirp44.wav');
	
	xn = stretch(ones(size(x)), fft_sz, k);
	x = stretch(x, fft_sz, k);
	
	x = x./xn;

	wavwrite(x*0.9/max(abs(x)), fs, 16, 'test_fft_phase_out.wav')
end

function x1 = stretch(x, fft_sz, k)
%	fs = fft_sz*4;
%	t = (0:fs*3-1)/fs;
	
%	x = zeros(10000,1);
%	x(3:32:end) = 1;

%	x = sin(2*pi*16*t+0.1) + sin(2*pi*32*t+0.3);

%	x = repmat(1:10,1,100);	x = x(:);

%	x(10001:end) = [];
%	x = ones(size(x));

	win = hamming(fft_sz);
%	S = spectrogram(x, win, length(win)-1);
	S = spectrogram_phased_buf(x, win, length(win)*3/4);

%	Sa = abs(S);
%	Sp = angle(S);
%	for i=1:size(Sp,1)
%		Sp(i,:)=unwrap(Sp(i,:)) - 2*pi*(i-1)*(0:size(Sp,2)-1)/fft_sz;
%	end

%	imwrite(Sp-min(Sp(:))/(max(Sp(:))-min(Sp(:))), 'phease_test_.png', 'PNG');
	
%	return;
	
%	figure('Name','Ordinary FFT', 'NumberTitle','off', 'Units','normalized', 'Position',[0 0 1 1]);
%	subplot(1,2,1);		imagesc(20*log10(Sa));		axis('xy');
%	subplot(1,2,2);		imagesc(Sp);				axis('xy');

%	figure('Name','Phased FFT', 'NumberTitle','off', 'Units','normalized', 'Position',[0 0 1 1]);
%	subplot(1,2,1);		imagesc(20*log10(abs(S_mod)));	axis('xy');
%	subplot(1,2,2);		imagesc(angle(S_mod));			axis('xy');

	S = transpose(S);
	Sa = abs(S);
	Sp = unwrap(angle(S));
	Sp(:,[1 end]) = unwrap(Sp(:,[1 end])*2)/2;
	
	i0 = 0:size(Sa,1)-1;
	i1 = linspace(0,size(Sa,1)-1, size(Sa,1)*k*fft_sz/4);
	Sa = interp1(i0, Sa, i1, 'spline');
	Sp = interp1(i0, Sp, i1, 'spline');

	x1 = spec_synth(Sa, Sp);

%	figure('Name','Phase comparision', 'NumberTitle','off', 'Units','normalized', 'Position',[0 0 1 1]);
%	subplot(1,2,1);		plot(unwrap(Sp((16:16:end-32)+1,:)'));
%	subplot(1,2,2);		plot(unwrap(angle(S_mod((16:16:end-32)+1,:))'));
end

function S = spectrogram_phased_buf(x, win, hop)
	if numel(win)==1
%		win = rectwin(win);
		win = hamming(win);
	end
	N = length(win);
	N2 = fix(N/2)+1;
	shift_sz = N-hop;
	frames = fix((length(x)-N) / shift_sz) + 1;

	S = zeros(N2, frames);
	
	for fr_i = 1:frames
		start_ind = (fr_i-1)*shift_sz;

		cur_x = x(start_ind + (1:N));
		cur_x = cur_x .* win(:);

		rot_sz = rem(start_ind, N);
		cur_x = [cur_x(end-rot_sz+1:end); cur_x(1:end-rot_sz)];

%		cur_x = cur_x .* win(:);
		
		fx = fft(cur_x);
		S(:,fr_i) = fx(1:N2);
	end
end

function x = spec_synth(Sa, Sp)
	x = zeros(size(Sa,1),1);

	t_ind = transpose(0:size(Sa,1)-1) + round((size(Sa,2)-1));
	for i = 1:size(Sa,2)
		x = x + Sa(:,i).*cos(pi* (i-1) *  t_ind / (size(Sa,2)-1) + Sp(:,i));
	end
end
