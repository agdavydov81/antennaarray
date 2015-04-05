function slsauto_lpcorderfit(snd_pathname, is_8000)
	if nargin<1 || isempty(snd_pathname)
		snd_pathname = 'White noise';
		fs_orig = 40000;
		x_orig = randn(fs_orig,1);
	else
		[x_orig,fs_orig] = libsndfile_read(snd_pathname);
		fs_orig = fs_orig.SampleRate;
	end
	if nargin<2
		is_8000 = false;
	end

	if is_8000
		x_orig = resample( resample(x_orig,8000,fs_orig), fs_orig,8000);
	end

	fs_list = 8000:2000:30000;
	lpcord_list = 12:2:44;

	[FS, LPCORDER] = ndgrid(fs_list, lpcord_list);
	mf = zeros(size(FS));
	parfor pii = 1:numel(FS) % parfor
		mf(pii) = get_medianlsffreq(resample(x_orig,FS(pii),fs_orig),FS(pii),LPCORDER(pii),10);
	end
	mf = abs(mf-mf(1));

	[~,snd_name,snd_ext] = fileparts(snd_pathname);
	figure('NumberTitle','off', 'Name',[snd_name snd_ext], 'Units','normalized', 'Position',[0 0 1 1]);
	surf(FS,LPCORDER,mf);
	view([0 90]);
	xlabel('Sampling frequency, Hz');
	ylabel('LPC order');
	
	ii = false(size(mf));
	[~,mi] = min(mf,[],1);
	ii(sub2ind(size(ii),mi,1:size(mf,2))) = true;
	[~,mi] = min(mf,[],2);
	ii(sub2ind(size(ii),(1:size(mf,1))',mi)) = true;
	ii(end,:) = false;
	ii(:,end) = false;
	hold('on');
	plot3(FS(ii), LPCORDER(ii), mf(ii), 'ro');
	pp = polyfit(FS(ii)/1000, LPCORDER(ii), 1);
	ff = (min(FS(ii)):max(FS(ii)))';
	plot3(ff, polyval(pp,ff/1000), 1000+zeros(size(ff)), 'm.-');
	plot3(ff, 1.5*ff/1000, 900+zeros(size(ff)), 'yd-');
	
	title([snd_pathname '; Band limit: ' num2str(is_8000) '; Fit polynom: ' num2str(pp)],'interpreter','none');
end

function mf = get_medianlsffreq(x,fs,lpc_order,lsf_ind)
	frame_size = round(0.025*fs);
	frame_shift= round(0.010*fs);

	obs_sz = fix((size(x,1)-frame_size)/frame_shift+1);
	lsf = zeros(obs_sz,lpc_order);
	gain = zeros(obs_sz,1);
	wnd = hamming(frame_size);

	obs_ind=0;
	for i=1:frame_shift:size(x,1)-frame_size+1
		cur_x = x(i:i+frame_size-1).*wnd;
		obs_ind = obs_ind+1;
		[cur_a, cur_err_pwr] = safe_lpc(cur_x, lpc_order);

		lsf(obs_ind,:) = poly2lsf(cur_a);
		gain(obs_ind)  = sqrt(cur_err_pwr);
	end

	mf = median(lsf(:,lsf_ind))*fs/(2*pi);
end

function [a,E] = safe_lpc(x, N)
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
