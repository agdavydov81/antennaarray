function vnm_3sec_mixed_signal(signal_file,noise_file, out_directory,SNR_dB)
	[x,fs]=wavread(signal_file);
	[n,fn]=wavread(noise_file);

    if fn~=fs
		n=resample(n,fs,fn);
    end
    
    if length(x)<3*fs
		x = repmat(x, ceil((3*fs)/length(x)), 1);
    end
    
    if length(n)<12*fs
		n = repmat(n, ceil(12*fs/length(n)), 1);
    end
    k=randi(12*fs);
    if(k<fs)
     n=n(1:3*fs);
    else
         if(k>10*fs)
          n=n(end+1-3*fs:end);
         else
          n=n(k-fs+1:k+2*fs);   
         end
    end    
   
	if length(x)>3*fs
		x(3*fs+1:end)=[];
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
	wavwrite(y,fs,[out_directory filesep nsf '_' num2str(SNR_dB) 'dB_(' nnf ').wav']);
end
