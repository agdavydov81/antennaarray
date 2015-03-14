function obs=vnm_obs_teo(x, alg, algs, etc_info)
	obs=zeros(etc_info.obs_sz, size(alg.bands,1));

	fs=algs.obs_general.fs;
	order=round(alg.order*fs/2)*2;

	for bi=1:size(alg.bands,1)
		f_lo=alg.bands(bi,1);
		f_hi=alg.bands(bi,2);

		bnd=min([f_lo f_hi], fs/2);
		if any([f_lo f_hi]~=bnd)
%			warning('vnm:obs:teo:filter_band','Filter %d band was adjusted from [%d %d] Hz to [%d %d] Hz.', bi, f_lo, f_hi, bnd(1), bnd(2));
		end

		if f_lo>=fs/2
			bnd_b=0;
		else
			if f_hi>=fs/2
				bnd_b=firls(order, [0 f_lo*2/fs+[0 0] 1], [0 0 1 1]);
			else
				bnd_b=firls(order, [0 f_lo*2/fs+[0 0] f_hi*2/fs+[0 0] 1], [0 0 1 1 0 0]);
			end
			bnd_b=bnd_b.*hamming(order+1)';
		end

		bnd_x=filter(bnd_b, 1, [x; zeros(order/2,1)]);	% filtfilt
		bnd_x(1:order/2)=[];
		if alg.band_norm
			bnd_x=bnd_x * fs/(2*diff(bnd));
		end

		bnd_teo=[zeros(1,size(x,2)); bnd_x(2:end-1).^2 - bnd_x(1:end-2).*bnd_x(3:end); zeros(1,size(x,2))];

		obs_ind=0;
		for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
			obs_ind=obs_ind+1;
			obs(obs_ind,bi)=mean(abs(bnd_teo(i:i+etc_info.fr_sz(2)-1)));
		end
	end
end

%{
function teo_test()
	fs=10000;
	t=(0:1000)'/fs;

	x=[ chirp(t, 0, t(end), 5000, 'linear') ...
		sin(2*pi*2500*t).*sin(2*pi*5*t)];

	figure;
	for i=1:size(x,2)
		subplot(size(x,2), 1, i);
		spectrogram(x(:,i), 256, 250, 256, fs, 'yaxis');
	end

	obs = [x(2:end-1,:).^2 - x(1:end-2,:).*x(3:end,:);
	obs = [obs(1,:); obs; obs(end,:)];

	figure;
	subplot(3,1,1);
	plot(x);
	subplot(3,1,2);
	plot([obs hann(size(obs,1))]);
	subplot(3,1,3);
	plot(fmdemod(x, fs/4, fs, fs/4));
end
%}
