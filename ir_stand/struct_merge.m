function struct_major = struct_merge(varargin)
	varargin(cellfun(@isempty, varargin)) = [];
	if ~all(cellfun(@isstruct, varargin))
		error('Not a struct object.');
	end

	struct_major = struct();
	if nargin>=1
		struct_major = varargin{1};
	end

	for st_i = 2:numel(varargin)
		struct_minor = varargin{st_i};

		fl_maj = fieldnames(struct_major);
		for fi = 1:numel(fl_maj)
			if isfield(struct_minor,fl_maj{fi}) && isstruct(struct_major.(fl_maj{fi})) && isstruct(struct_minor.(fl_maj{fi}))
				struct_major.(fl_maj{fi}) = struct_merge(struct_major.(fl_maj{fi}), struct_minor.(fl_maj{fi}));
			end
		end

		fl_min = fieldnames(struct_minor);
		fl_min( cellfun(@(x) any(strcmp(x,fl_maj)), fl_min) ) = [];
		for fi = 1:numel(fl_min)
			struct_major.(fl_min{fi}) = struct_minor.(fl_min{fi});
		end
	end
end
