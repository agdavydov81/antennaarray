function vnm_add_noise_to_signal(signal_file,noise_file, out_directory,SNR_dB)
	[x,fs]=wavread(signal_file);
	[n,fn]=wavread(noise_file);

	if fn~=fs
		n=resample(n,fs,fn);
	end

	if length(x)>length(n)
		n = repmat(n, ceil(length(x)/length(n)), 1);
	end
	if length(x)<length(n)
		n(length(x)+1:end)=[];
	end

	SNR=10^(SNR_dB/10);
	SNR0=mean(x.*x)/mean(n.*n);

	a=sqrt(SNR/(SNR+1));
	b=sqrt(SNR0/(SNR+1));
	y=a*x+b*n;

	ym=max(abs(y));
	if ym>0.9
		y = y*0.9/ym;
	end

	[~,nsf]=fileparts(signal_file);
	[~,nnf]=fileparts(noise_file);
	wavwrite(y,fs,[out_directory filesep nsf '_' num2str(SNR_dB) 'dB_' nnf '.wav']);
end
