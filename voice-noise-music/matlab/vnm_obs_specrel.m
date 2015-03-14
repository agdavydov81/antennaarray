function obs=vnm_obs_specrel(x, alg, algs, etc_info)
	psd=spectrogram(x, etc_info.fr_sz(2), etc_info.fr_sz(2)-etc_info.fr_sz(1)); 
	psd=transpose(psd.*conj(psd));
	if size(psd,1)~=etc_info.obs_sz
		error('vnm:obs:specrel:wrong_size','Calculated %d observations instead of %d in file %s.',size(psd,1),etc_info.obs_sz,etc_info.file_name);
	end

	bands=zeros(etc_info.obs_sz, size(alg.bands,1));
	for i=1:size(alg.bands,1)
		b_rg=round( max(0,min(1,alg.bands(i,:)*2/algs.obs_general.fs)) *size(psd,2))+1;
		bands(:,i)=10*log10(mean(psd(:,b_rg(1):b_rg(2)-1),2)+realmin);
	end

	bn=size(alg.bands,1);
	obs=zeros(etc_info.obs_sz, bn*(bn-1)/2);
	o_i=1;
	for b_i=1:size(alg.bands,1)-1
		for b_j=(b_i+1):size(alg.bands,1)
			obs(:,o_i)=bands(:,b_i)-bands(:,b_j);
			o_i=o_i+1;
		end
	end
end
