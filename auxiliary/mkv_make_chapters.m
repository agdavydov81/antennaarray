function mkv_make_chapters(video_root)
	ffprobe_path = 'c:\Program Files (x86)\ffmpeg\bin\ffprobe.exe';

	if nargin<1
		cache_name = [mfilename '_cache.mat'];
		video_root = '';
		if exist(cache_name, 'file')
			load(cache_name);
		end
		video_root_last = '';
		while ~exist(video_root,'dir') && ~isequal(video_root_last,video_root)
			video_root_last = video_root;
			video_root = fileparts(video_root);
		end
		is_first_cycle = true;
		while ~isempty(video_root) || is_first_cycle
			is_first_cycle = false;
			video_root = uigetdir(video_root, 'Выберите каталог для обработки');
			if not(video_root)
				break
			end
			save(cache_name, 'video_root');

			mkv_make_chapters(video_root);
		end
		return
	end

	list = dir(fullfile(video_root,'*.*')); % Find extension by bigest file
	list([list.isdir]) = [];
	list = sort({list.name}');
	
	Chapters.EditionEntry.EditionFlagHidden = 0;
	Chapters.EditionEntry.EditionFlagDefault = 0;
	Chapters.EditionEntry.EditionUID = randi(intmax('uint32'), 1, 'uint32');

	cur_t = 0;
	for li=1:numel(list)
		[~, cur_name] = fileparts(list{li});
		dos_str = ['"' ffprobe_path '" "' fullfile(video_root,list{li}) '"'];
		[status,result] = dos(dos_str);
		if status
			continue
%			error('mkv_make_chapters:ffprobe',['Can''t get information from ' fullfile(video_root,list{li}) '.']);
		end
		cur_len = regexp(result,'(?<=Duration\: )\d+\:\d+\:\d+\.\d+', 'match','once');
		[~, ~, ~, cur_h, cur_mn, cur_s] = datevec(cur_len,'HH:MM:SS.FFF');
		cur_len = datenum(0,0,0,cur_h,cur_mn,cur_s);
		Chapters.EditionEntry.ChapterAtom(li,1) = struct( ...
			'ChapterDisplay',struct('ChapterString',cur_name, 'ChapterLanguage','und'), ...
			'ChapterUID',randi(intmax('uint32'), 1, 'uint32'), ...
			'ChapterTimeStart',datestr(cur_t,'HH:MM:SS:FFF'), ...
			'ChapterFlagHidden',0, ...
			'ChapterFlagEnabled',1);
		cur_t = cur_t+cur_len;
	end

	xml_write(fullfile(video_root,'chapters.xml'),Chapters,'Chapters',struct('StructItem',false));
end
