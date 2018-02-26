function file_list = findfiles(root, mask)
    dir_res = dir(fullfile(root, mask));
	
	file_list = arrayfun(@(x) fullfile(root, x.name), dir_res(~[dir_res.isdir]), 'UniformOutput',false);
	
    dir_res = dir(root);
	dir_res(~[dir_res.isdir]) = [];
	dir_res(arrayfun(@(x) any(strcmp(x.name,{'.','..'})), dir_res)) = [];

	dirs_list = arrayfun(@(x) findfiles(fullfile(root, x.name), mask), dir_res, 'UniformOutput',false);
	file_list = [file_list; vertcat(dirs_list{:})];
end
