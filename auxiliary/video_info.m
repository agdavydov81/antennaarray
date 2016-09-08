function list = video_info(root)
	list = listfiles(root);
	ii = arrayfun(@(x) isempty(x.bytes) || x.bytes<(300*1024*1024), list);
	list(ii) = [];

	ffprobe_path = 'c:\Program Files (x86)\ffmpeg\bin\ffprobe.exe';
	list = num2cell(list);
	for ii = 1:numel(list) % parfor
		obj = list{ii};

		dos_str = ['"' ffprobe_path '" "' obj.name '"'];
		[status,result] = dos(dos_str);
		if isempty(result) || status~=0
			disp(['File ' obj.name ' "ffprobe" error']);
			continue
		end
		result = textscan(result,'%s','Delimiter','\n');
		result = result{1};

		tokn = regexp(result,'^Duration\: (\d+\:\d+\:\d+\.\d+).*bitrate\: (\d+) kb/s', 'tokens');
		tokn = vertcat(tokn{:});
		if numel(tokn)~=1
			disp(['File ' obj.name ' "duration" error']);
			continue
		end
		[~, ~, ~, cur_h, cur_mn, cur_s] = datevec(tokn{1}{1},'HH:MM:SS.FFF');
		obj.total_duration = (cur_h*60+cur_mn)*60+cur_s;
		obj.total_bitrate = str2double(tokn{1}{2});
		
		tokn = regexp(result,'^Stream \#\d\:\d.*Video\: .* (\d+)x(\d+)[, ].* (\d+) kb/s,.* (\d+(\.\d+)?) fps','tokens');
		ti = ~cellfun(@isempty, tokn);
		if sum(ti)==1
			tokn = cellfun(@str2double, tokn{ti}{1});
			obj.video_resolution = tokn(1:2);
			obj.video_bitrate = tokn(3);
			obj.video_fps = tokn(4);
		end

		tokn = regexp(result,'^Stream \#\d\:\d.*Audio\: .* (\d+) Hz,.* (\d+) kb/s','tokens');
		obj.audio_samplerate = cellfun(@(x) str2double(x{1}), horzcat(tokn{:}));
		obj.audio_bitrate = cellfun(@(x) str2double(x{2}), horzcat(tokn{:}));
		
		list{ii} = obj;
	end
end

function list = listfiles(root)
	list = dir(root);
	ii = [list.isdir];
	dirs = list(ii);
	list(ii) = [];
	
	for ii = 1:numel(list)
		list(ii).name = fullfile(root,list(ii).name);
	end

	for ii = 1:numel(dirs)
		if any(strcmp(dirs(ii).name, {'.' '..'}))
			continue
		end
		dirs(ii).list = listfiles(fullfile(root,dirs(ii).name));
	end

	if isfield(dirs,'list')
		list = [list; vertcat(dirs.list)];
	end
end
