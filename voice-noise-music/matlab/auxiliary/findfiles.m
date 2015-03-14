function file_list=findfiles(root, mask, file_list)
    if nargin<3
        file_list={};
    end

    dir_res=dir([root filesep mask]);
    for i=1:length(dir_res)
        if dir_res(i).isdir==1
            continue;
        end
        file_list{end+1}=[root filesep dir_res(i).name];
    end

    dir_res=dir(root);
    for i=1:length(dir_res)
        if dir_res(i).isdir==0 || max(strcmp(dir_res(i).name,{'.','..'}))
            continue;
        end
        file_list=findfiles([root filesep dir_res(i).name], mask, file_list);
    end
end
