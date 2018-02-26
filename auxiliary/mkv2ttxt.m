function mkv2ttxt(target)
	if nargin < 1
		cache_name = [mfilename '_cache.mat'];
		target = '';
		if exist(cache_name, 'file')
			load(cache_name);
		end
		target_last = '';
		while ~exist(target,'dir') && ~isequal(target_last,target)
			target_last = target;
			target = fileparts(target);
		end
		target = uigetdir(target, 'Select processing directory');
		if not(target)
			return
		end
		save(cache_name);
	end

	if exist(target,'file') == 2
		process_file(target);
	end
	if exist(target,'dir')
		process_directory(target);
	end
end

function process_directory(root)
	list = [dir(fullfile(root,'*.mkv')); dir(fullfile(root,'*.xml'))];
	list([list.isdir]) = [];
	
	for li = 1:numel(list)
		process_file(fullfile(root,list(li).name));
	end
	
	list = dir(root);
	list(~[list.isdir]) = [];
	list( arrayfun(@(x) any(strcmp(x.name,{'.' '..'})), list) ) = [];
	
	for li = 1:numel(list)
		process_directory(fullfile(root,list(li).name));
	end
end

function process_file(mkv_filename)
	[mkv_path, mkv_name, mkv_ext] = fileparts(mkv_filename);
	if strcmpi(mkv_ext,'.mkv')
		mkvextract = 'c:\Program Files\MKVToolNix\mkvextract.exe';

		tmp_xml = [tempname() '.xml'];
		[dos_status, dos_cmdout] = dos(['"' mkvextract '" chapters "' mkv_filename '" > "' tmp_xml '"']);
	else % xml direct processing
		tmp_xml = mkv_filename;
	end
	tmp = dir(tmp_xml);
	
	if tmp.bytes > 0
		chap_xml = xml_read(tmp_xml);
		chap_xml = chap_xml.EditionEntry.ChapterAtom;
		if numel(chap_xml) < 1
			error('Can''t find chapters information');
		end
		
		ttxt.ATTRIBUTE.version = 1.1;
		ttxt.TextStreamHeader.ATTRIBUTE = struct('width',0, 'height',0, 'layer',0, 'translation_x',0, 'translation_y',0);
		ttxt.TextStreamHeader.TextSampleDescription.ATTRIBUTE = struct('horizontalJustification','left', 'backColor','0 0 0', 'scroll','None');
		ttxt.TextStreamHeader.TextSampleDescription.TextBox.ATTRIBUTE = struct('top','0', 'left','0', 'bottom','0', 'right','0');
		
		for ii = 1:numel(chap_xml)
			time_str = chap_xml(ii).ChapterTimeStart;
			if numel(time_str) == 18 && all(time_str(end-5:end) == '0')
				time_str(end-5:end) = [];
			else
				error('Time spamp parsing error.');
			end
			ttxt.TextSample(ii) = struct('CONTENT',chap_xml(ii).ChapterDisplay.ChapterString, 'ATTRIBUTE',struct('sampleTime',time_str));
		end

		xml_write(fullfile(mkv_path, [mkv_name '_chapters.ttxt']), ttxt, 'TextStream');
	end

	try
		if strcmpi(mkv_ext,'.mkv')
			delete(tmp_xml);
		end
	catch
	end
end
