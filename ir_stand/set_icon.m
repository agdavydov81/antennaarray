function set_icon(btn, icon_filename, left_align)
try
	if nargin<3
		left_align = false;
	end
	[logo_image, logo_map, logo_alpha] = imread(fullfile(fileparts(mfilename('fullpath')), 'icons', icon_filename));
	if ~isempty(logo_map)
		logo_map = reshape(uint8(logo_map * 255), size(logo_map,1), 1, 3);
		logo_image = cell2mat(arrayfun(@(x) logo_map(x+1,:,:), logo_image, 'UniformOutput',false));
	end
	if ~isempty(logo_alpha)
		back_color = repmat(reshape(255*get(0,'defaultUicontrolBackgroundColor'), [1 1 3]), [size(logo_alpha) 1]);
		logo_alpha = repmat(double(logo_alpha)/255,[1 1 3]);
		logo_image = uint8(double(logo_image).*logo_alpha + back_color.*(1-logo_alpha));
	end
	if left_align
		old_units = get(btn, 'Units');
		set(btn, 'Units','Pixels');
		pos = get(btn, 'Position');
		set(btn, 'Units',old_units);
		logo_image1 = repmat(reshape(255*get(0,'defaultUicontrolBackgroundColor'), [1 1 3]), [size(logo_image,1) pos(3)-size(logo_image,2)-10 1]);
		logo_image = [logo_image logo_image1];
	end
	set(btn, 'CData',logo_image);
	if ~left_align
		set(btn, 'String','');
	end
catch
end
