function [base alg]=vnm_parse_folders(db_root, alg)
	base=recursive_parse_folders(struct('class',{},'data',{},'color',{}), [db_root filesep], '.', alg, {'b' 'r' 'g' 'c' 'm' 'y' 'k'});
end

function [base color_list]=recursive_parse_folders(base, db_root, db_subpath, alg, color_list)
	%% add wav files in current directory
	list=dir([db_root db_subpath filesep '*.wav']);
	list([list.isdir])=[];
	if not(isempty(list))
		flist=arrayfun(@(x) struct('file_name',[db_root db_subpath filesep x.name]), list, 'UniformOutput',false);
		flist=vnm_parse_files(flist, alg);
		base(end+1,1)=struct('class',db_subpath, 'data',{flist}, 'color',color_list{1});
		color_list=color_list([2:end, 1]);
	end

	list=dir([db_root db_subpath]);
	list(not([list.isdir]))=[];
	list={list.name};
	list(strcmp(list,'.'))=[];
	list(strcmp(list,'..'))=[];

	for i=1:length(list)
		[base color_list]=recursive_parse_folders(base, db_root, [db_subpath filesep list{i}], alg, color_list);
	end
end
