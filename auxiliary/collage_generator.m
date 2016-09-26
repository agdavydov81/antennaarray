function collage_generator(root_, image_sz_, image_sz_percentile_, border_sz_, border_sz_is_relative_, rotate_max_, collage_size_, background_color_, edging_color_)
	if nargin < 9
		if nargin < 1;	root = '';						else root = root_;									end
		if nargin < 2;	image_sz = [];					else image_sz = image_sz_;							end
		if nargin < 3;	image_sz_percentile = 5;		else image_sz_percentile = image_sz_percentile_;	end
		if nargin < 4;	border_sz = 0.8;				else border_sz = border_sz_;						end
		if nargin < 5;	border_sz_is_relative = true;	else border_sz_is_relative = border_sz_is_relative_;end
		if nargin < 6;	rotate_max = 30;				else rotate_max = rotate_max_;						end
		if nargin < 7
			collage_size = [9933 14043];
		else
			collage_size = collage_size_;
		end
		if nargin < 8;	background_color = [192 192 192]; else background_color = background_color_;		end
		if nargin < 9;	edging_color = [255 255 255];	else edging_color = edging_color_;					end

		cache_name = [mfilename '_cache.mat'];
		if exist(cache_name, 'file')
			load(cache_name);
		end

		root_last = '';
		while ~exist(root,'dir') && ~isequal(root_last,root)
			root_last = root;
			root = fileparts(root);
		end
		if nargin < 1
			root = uigetdir(root, 'Выберите каталог для обработки');
			if not(root)
				return
			end
		end

		prompt = {	sprintf('One photo size (symbol ''%%'' means percentile \nfrom clusters centroids distance distribution):');
					sprintf('Photo border size (symbol ''%%'' means percent \nfrom image size):');
					'Rotation maximum (+-degree):';
					'Collage width (pixels):';
					'Collage height (pixels):';
					'Background color (R G B):'
					'Photos edging color (R G B):'};
		if isempty(image_sz)
			answer = {[num2str(image_sz_percentile) '%']};
		else
			answer = {num2str(image_sz)};
		end
		answer = [answer arrayfun(@num2str, [border_sz rotate_max collage_size(:)'], 'UniformOutput',false)];
		answer{end+1} = num2str(round(background_color(:)'));
		answer{end+1} = num2str(round(edging_color(:)'));
		if border_sz_is_relative
			answer{2}(end+1) = '%';
		end
		
		answer = inputdlg(prompt, 'Input', 1, answer);
		if isempty(answer)
			return
		end
		
		[image_sz, image_sz_is_relative] = parse_relative(answer{1});
		if image_sz_is_relative
			image_sz_percentile = image_sz;
			image_sz = [];
		end
		[border_sz, border_sz_is_relative] = parse_relative(answer{2});
		
		rotate_max = str2double(answer{3});
		collage_size = cellfun(@str2double, answer(4:5));
		background_color = str2num(answer{6});
		edging_color = str2num(answer{7});

		save(cache_name);
	end

	if exist(fullfile(root,'_back.jpg'), 'file')
		back_img = imread(fullfile(root,'_back.jpg'));
	else
		background_color = reshape(uint8(background_color),[1 1 3]);
		back_img = repmat(background_color, collage_size(2), collage_size(1));
	end

	if exist(fullfile(root,'_mask.jpg'), 'file')
		mask_img = imread(fullfile(root,'_mask.jpg'));
		mask_img = rgb2gray(mask_img)<128;
		if size(back_img,1)~=size(mask_img,1) || size(back_img,2)~=size(mask_img,2)
			error('Inconsistent background and mask sizes.');
		end
	else
		mask_img = true(size(back_img,1), size(back_img,2));
	end

	photos = dir(fullfile(root, '*.jpg'));
	photos([photos.isdir]) = [];
	photos( cellfun(@(x) x(1)=='_', {photos.name}) ) = [];
	if numel(photos) < 1
		error('There are no photos for collage.');
	end
	
	[mask_xy(:,1), mask_xy(:,2)] = ind2sub(size(mask_img), find(mask_img));
	clusters_num = numel(photos);
	decimator = max(1, round(size(mask_xy,1)/(clusters_num*200)));
	mask_xy = mask_xy(1:decimator:end,:);
	[~, points] = kmeans(mask_xy, clusters_num);
	if isempty(image_sz)
		if (numel(photos) < 2)
			row_sz = zeros(size(mask_img,1),1);
			for ri = 1:size(mask_img,1)
				d = diff([false mask_img(ri,:) false]);
				row_sz(ri) = median(find(d==-1) - find(d==1));
			end
			col_sz = zeros(1,size(mask_img,2));
			for ci = 1:size(mask_img,2)
				d = diff([false; mask_img(:,ci); false]);
				col_sz(ci) = median(find(d==-1) - find(d==1));
			end
			image_sz = min(median(row_sz), median(col_sz));
		else
			image_sz = prctile(pdist(points),image_sz_percentile);
		end
	end
	if border_sz_is_relative
		border_sz = round( image_sz * border_sz / 100);
	end
	
	edging_color = reshape(uint8(edging_color),[1 1 3]);
	
	photos = photos(randperm(numel(photos)));
	
	hw = waitbar(0, 'Process images', 'Name','Process images');
	
	tmpdir = tempname();
	mkdir(tmpdir);
	imwrite(back_img, fullfile(tmpdir,'0.png'));
	
	for ri = 1:numel(photos)
		cur_imag = imread(fullfile(root, photos(ri).name));
		cur_imag = imresize(cur_imag, image_sz/max(size(cur_imag)));
		cur_size = size(cur_imag);
		%cur_imag = [255+zeros(border_sz,cur_size(2)+2*border_sz,3,'uint8'); ...
		%			255+zeros(cur_size(1),border_sz,3,'uint8')  cur_imag  255+zeros(cur_size(1),border_sz,3,'uint8'); ...
		%			255+zeros(border_sz,cur_size(2)+2*border_sz,3,'uint8') ];
		cur_imag = [repmat(edging_color,border_sz,cur_size(2)+2*border_sz); ...
					repmat(edging_color,cur_size(1),border_sz)  cur_imag  repmat(edging_color,cur_size(1),border_sz); ...
					repmat(edging_color,border_sz,cur_size(2)+2*border_sz) ];

		cur_rot  = rotate_max*(rand*2-1);

		cur_pos = round(points(ri,:));
%		cur_dist = 0;
%		cur_dist_lim = min([size(cur_imag,1) size(cur_imag,2)]/2);
%		rnd_ind = 0;
%		while (~mask_img(cur_pos(1), cur_pos(2)) || cur_dist<cur_dist_lim) && rnd_ind<1000;
%			cur_pos  = ceil(rand(1,2).*[size(back_img,1) size(back_img,2)]);
%			cur_dist = mask_xy - repmat(cur_pos,size(mask_xy,1),1);
%			cur_dist = sqrt(min(sum(cur_dist.*cur_dist,2)));
%		end
%		if rnd_ind==1000
%			error(['Can''t find place for image "' photos(ri).name '" in 1000 itarations.']);
%		end

		cur_mask = ones(size(cur_imag,1),size(cur_imag,2));
		cur_mask(:,[1 end]) = 0;
		cur_mask([1 end],:) = 0;

		cur_imag = imrotate(cur_imag, cur_rot, 'bicubic');
		cur_mask = imrotate(cur_mask, cur_rot, 'bicubic');
		cur_mask = repmat(cur_mask, [1 1 3]);

		cur_pos = cur_pos - fix([size(cur_imag,1) size(cur_imag,2)]/2);
		if cur_pos(1)<1
			kill_ind = 1:1-cur_pos(1);
			cur_imag(kill_ind,:,:) = [];
			cur_mask(kill_ind,:,:) = [];
			cur_pos(1) = 1;
		end
		if cur_pos(2)<1
			kill_ind = 1:1-cur_pos(2);
			cur_imag(:,kill_ind,:) = [];
			cur_mask(:,kill_ind,:) = [];
			cur_pos(2) = 1;
		end
		
		if cur_pos(1)-1+size(cur_imag,1)-1>size(back_img,1)
			kill_ind = cur_pos(1)-1+size(cur_imag,1)-1-size(back_img,1);
			cur_imag(end-kill_ind:end,:,:) = [];
			cur_mask(end-kill_ind:end,:,:) = [];
		end
		if cur_pos(2)-1+size(cur_imag,2)-1>size(back_img,2)
			kill_ind = cur_pos(2)-1+size(cur_imag,2)-1-size(back_img,2);
			cur_imag(:,end-kill_ind:end,:) = [];
			cur_mask(:,end-kill_ind:end,:) = [];
		end

		cur_ind_x = cur_pos(1)-1+(1:size(cur_imag,1));
		cur_ind_y = cur_pos(2)-1+(1:size(cur_imag,2));
		
		cur_back  = back_img(cur_ind_x, cur_ind_y, :);
%		cur_back(cur_mask) = cur_imag(cur_mask);
		cur_back  = uint8( double(cur_back).*(1-cur_mask) + double(cur_imag).*cur_mask );
		
		layer_imag = zeros(size(back_img),'uint8');
		layer_mask = zeros(size(layer_imag,1),size(layer_imag,2));
		layer_imag(cur_ind_x, cur_ind_y, :) = cur_imag;
		layer_mask(cur_ind_x, cur_ind_y) = cur_mask(:,:,1);
		imwrite(layer_imag, fullfile(tmpdir,sprintf('%d.png',ri)), 'Alpha',layer_mask);

		back_img(cur_ind_x, cur_ind_y, :) = cur_back;

		waitbar_str = sprintf('Process images: %d/%d',ri,size(points,1));
		waitbar(ri/size(points,1), hw, waitbar_str);
		set(hw, 'Name', waitbar_str);
		pause(0.01);
	end
	close(hw);

	imwrite(back_img, fullfile(root, '_collage.jpg'), 'jpg', 'Quality',95);

	names = cell2mat(arrayfun(@(x) sprintf(' %d.png',x), 1:numel(photos), 'UniformOutput',false));
	fh = fopen(fullfile(tmpdir,'dopsd.bat'),'w');
	fprintf(fh, '%s\n', tmpdir(1:2));
	fprintf(fh, 'cd "%s"\n', tmpdir);
	fprintf(fh, 'convert -background none -flatten 0.png %s _blend.png\n', names);
	fprintf(fh, 'convert _blend.png %s -compress RLE "%s"\n', names, fullfile(root, '_collage.psd'));
	fclose(fh);
	[di,do] = dos(fullfile(tmpdir,'dopsd.bat'));

	try
		rmdir(tmpdir, 's');
	catch
	end
end

function [size, is_relative] = parse_relative(str)
	while numel(str)>1 && any(str(end)==sprintf(' \t\b\r\n'))
		str(end) = [];
	end
	
	is_relative = false;
	if numel(str)>1 && str(end) == '%'
		is_relative = true;
		str(end) = [];
	end
	
	size = str2double(str);
end
