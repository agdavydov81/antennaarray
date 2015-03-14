function Timit_base(Timit_root,out_directory)
 
 paths=find_paths(Timit_root,{});
 length(paths);

    for i=1:length(paths)
       lst=dir([paths{i} filesep '*.wav']);
       lst={lst.name};
       if ~isempty(lst)
         k=randi(length(lst));
         foldername=paths{i}(end-4:end);
         copyfile([paths{i} filesep lst{k}],[out_directory filesep foldername '_' lst{k}]);
       end
    end
end
function paths=find_paths(root,paths)

    paths{end+1}=root;
    
    list=dir(root);
	list(not([list.isdir]))=[];
	list={list.name};
	list(strcmp(list,'.'))=[];
	list(strcmp(list,'..'))=[];
    
    for i=1:length(list)
        paths=find_paths([root filesep list{i}],paths);
    end    
    
end