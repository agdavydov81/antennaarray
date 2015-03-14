function added_paths=addpath_recursive(root, varargin)
%ADDPATH_RECURSIVE Smart replace for addpath(genpath(...)) functions call.
%   [ADDED_PATHS]=ADDPATH_RECURSIVE(root_dir, ...) recursively add
%   directories to MATLAB path from specified root and return list of added
%   directories. Function support next call types.
%
%   ADDPATH_RECURSIVE() - recursively add directories from calling function
%   path. Equivalent to ADDPATH_RECURSIVE(FILEPARTS(MFILENAME('fullpath')) call.
%
%   ADDPATH_RECURSIVE(root, 'arg1','val1', 'arg2','val2', ...).
%   Next arguments supported:
%   'ignore_dirs' - string or cell of strings with regular expressions
%     describing names (not full path or parts of name) of ignored folders
%     (and also subfolders). For example
%     ADDPATH_RECURSIVE(root,'ignore_dirs','\.svn')
%     ADDPATH_RECURSIVE(root,'ignore_dirs',{'\.svn' 'c\+\+'})
%   'addpath_arg' - string or cell of optional arguments directly passed to
%     addpath function. For example
%     ADDPATH_RECURSIVE(root,'addpath_arg','-end')
%   'add_root' - flag (false by default) for adding to path also root folder.

%   Author(s): A.G.Davydov
%   $Revision: 1.0.0.3 $  $Date: 2012/09/03 19:06:11 $ 

	if nargin==0 || isempty(root)
		call_stack=dbstack('-completenames');
		if length(call_stack)>1
			root=fileparts(call_stack(2).file);
		else
			root=pwd();
		end
	end

	cfg=struct('ignore_dirs',{{}}, 'addpath_arg',{{}}, 'add_root',false);
	if rem(length(varargin),2)
		error('addpath_recursive:arguments_parse', 'Incorrect number of input arguments.');
	end
	for i=1:length(varargin)/2
		cfg.(varargin{2*i-1})=varargin{2*i};
	end

	if isa(cfg.ignore_dirs,'char')
		cfg.ignore_dirs={cfg.ignore_dirs};
	end
	if not(isa(cfg.ignore_dirs,'cell'))
		error('addpath_recursive:arguments_parse', 'ignore_dirs argument must be string or cell of strings.');
	end

	if isa(cfg.addpath_arg,'char')
		cfg.addpath_arg={cfg.addpath_arg};
	end
	if not(isa(cfg.addpath_arg,'cell'))
		error('addpath_recursive:arguments_parse', 'addpath_arg argument must be string or cell.');
	end

	added_paths=recursive_call(root, cfg, {});
end

function added_paths=recursive_call(root, cfg, added_paths)
	if cfg.add_root
		addpath(root, cfg.addpath_arg{:});
		added_paths{end+1}=root;
	else
		cfg.add_root=true;
	end

	list=dir(root);
	list(not([list.isdir]))=[];
	list={list.name};
	list(strcmp(list,'.'))=[];
	list(strcmp(list,'..'))=[];

	ignore_mask=false(size(list));
	for i=1:length(cfg.ignore_dirs)
		[reg_beg, reg_end]=regexp(list, cfg.ignore_dirs{i});
		ignore_mask=ignore_mask | cellfun(@(l,b,e) not(isempty(b))&&b==1&&e==length(l), list, reg_beg, reg_end);
	end
	list(ignore_mask)=[];

	for i=1:length(list)
		added_paths=recursive_call([root filesep list{i}], cfg, added_paths);
	end
end
