function vnm_feature_select_graph(sfs_root)
	if nargin<1
		sfs_root=uigetdir('', 'Select feature selection root folder');
		if not(sfs_root)
			return;
		end
	end
	
	list=dir([sfs_root filesep 'Step*']);
	list(not([list.isdir]))=[];

	[~,si] = sort(str2double(regexp({list.name}','(?<=Step)\d+','match','once')));
	list = list(si);

%	figure();
	last_pt=[nan nan];
	for li=1:length(list)
		last_pt=parse_subdir(last_pt,[sfs_root filesep 'Step' num2str(li)]);
	end
	grid('on');
	xlabel('Features number');
	ylabel('Prediction performance');
	title(sfs_root,'Interpreter','none');
end

function last_pt=parse_subdir(last_pt, subroot)
	list=dir([subroot filesep '*.txt']);
	list([list.isdir])=[];
	[~,si]=sort([list.datenum]);
	list=list(si);
	list={list.name};

	fr_flag=not(cellfun(@isempty, regexp(list, '.*_forward\d+\.txt')));
	bk_flag=not(cellfun(@isempty, regexp(list, '.*_backward\d+\.txt')));

	list = [list(fr_flag) list(bk_flag)];
	fr_flag=not(cellfun(@isempty, regexp(list, '.*_forward\d+\.txt')));
	bk_flag=not(cellfun(@isempty, regexp(list, '.*_backward\d+\.txt')));

	fr_bk_flag=fr_flag | bk_flag;
	list(not(fr_bk_flag))=[];
	fr_flag(not(fr_bk_flag))=[];

	for li=1:length(list)
		fh=fopen([subroot filesep list{li}],'r');
		fgetl(fh);
		rate=fscanf(fh, '%f');
		fclose(fh);
		new_pt=last_pt;
		if isnan(new_pt(1))
			new_pt(1)=0;
		end
		if fr_flag(li)
			new_pt(1)=new_pt(1)+1;
			cur_clr='bd-';
		else
			new_pt(1)=new_pt(1)-1;
			cur_clr='r+-';
		end
		new_pt(2)=rate;

		plot([last_pt(1) new_pt(1)], [last_pt(2) new_pt(2)], cur_clr);
		hold('on');
		
		last_pt=new_pt;
	end
end
