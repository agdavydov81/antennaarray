function obs=vnm_obs_phonfunc(x, alg, algs, etc_info)
	obs=zeros(etc_info.obs_sz,4);

	lpc_ord=round(algs.obs_general.fs/1000)+4;
	wnd=hamming(etc_info.fr_sz(2));
	freqz_sz=pow2(round(log2(algs.obs_general.fs/2/20)));

	delay_sz=max(1, round(alg.delay / algs.obs_general.frame_step));
	delay_sz_l=fix(delay_sz/2);
	
	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*wnd;
		obs_ind=obs_ind+1;

		if all(cur_x==0)
			cur_H=zeros(freqz_sz,1);
		else
			[cur_a,cur_e]=vnm_lpc(cur_x, lpc_ord);
			cur_H=freqz(sqrt(cur_e), cur_a, freqz_sz);
			cur_H=cur_H.*conj(cur_H);
		end

		if obs_ind==1
			freqz_fifo=repmat(cur_H, 1, delay_sz);
		end

		last_H=freqz_fifo(:,1);
		freqz_fifo(:,delay_sz+1)=cur_H;
		freqz_fifo(:,1)=[];
		
		if(obs_ind-delay_sz_l>0)
			cur_rel=cur_H./last_H;
			cur_back_rel=last_H./cur_H;
			
			ind=cur_H==0 | last_H==0;
			cur_rel(ind)=[];
			cur_back_rel(ind)=[];

			if not(isempty(cur_rel))
				LS=sqrt(mean( (10*log10(cur_rel)).^2 )); % Log-spectral distance [http://en.wikipedia.org/wiki/Log-spectral_distance]

				IS_ab=10*log10(mean(cur_rel-log(cur_rel)-1)); % Itakura–Saito distance [http://en.wikipedia.org/wiki/Itakura-Saito_distance]
				IS_ba=10*log10(mean(cur_back_rel-log(cur_back_rel)-1));

				obs(obs_ind-delay_sz_l,:)=[LS  IS_ab IS_ba  IS_ab-IS_ba];
			end
		end
	end
end
