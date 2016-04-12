function slsauto_batch_processing(root, ext_list, process_subdirs)
	if nargin<1
		cache_name = [mfilename '_cache.mat'];
		root = '';
		if exist(cache_name, 'file')
			load(cache_name);
		end
		root_last = '';
		while ~exist(root,'dir') && ~isequal(root_last,root)
			root_last = root;
			root = fileparts(root);
		end
		root = uigetdir(root, 'Выберите каталог для обработки');
		if not(root)
			return
		end
		save(cache_name, 'root');
	end
	
	if nargin<2
		ext_list = inputdlg('Enter file extensions', 'Parameters input', 2, {'wav fla flac ogg mp3 aac'});
		if isempty(ext_list)
			return
		end
		ext_list = strsplit(ext_list{1}, ' ');
	end
	
	if nargin<3
		process_subdirs = true;
	end

	process_files(root, ext_list);

	if process_subdirs
		list = dir(root);
		list(~[list.isdir]) = [];
		list = {list.name};
		list(strcmp('.',list)) = [];
		list(strcmp('..',list)) = [];
		for li = 1:numel(list)
			d = fullfile(root, list{li});
			disp(['Process directory ' d]);
			slsauto_batch_processing(d, ext_list, process_subdirs);
		end
	end
end

function process_files(root, ext_list)
	list = cell2mat(cellfun(@(x) dir(fullfile(root,['*.' x])), ext_list(:), 'UniformOutput',false));
	list([list.isdir]) = [];

	parfor li = 1:numel(list)
		cfg = struct('snd_filename', fullfile(root, list(li).name));

		slsauto_pitch_raw(cfg, {'pitchrapt'});

		slsauto_lpc_analyse(cfg);
		
		fclose(fopen(slsauto_getpath(cfg,'lab'), 'w'));

		slsauto_vu2lab(cfg, [], [], [], false);

		delete(slsauto_getpath(cfg,'lpc'));
	end
end
