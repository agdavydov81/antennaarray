function antenna_diagram()
	fid=figure('NumberTitle','off', 'Name','Antenna Plot', 'Toolbar','figure', 'Units','normalized', 'Position',[0 0 1 1], 'ResizeFcn',@on_figure_resize);
	data=guihandles(fid);
	data.GUI.fid=fid;

	data.GUI.axes=axes();
	
	font_sz=9;
	pan_sz=[60 21.8];
	data.GUI.panel=uipanel('Parent',fid, 'Title','Настройка', 'Units','characters', 'Position',[0 0 pan_sz], 'FontSize',font_sz);

	ctrl_pos=[1 pan_sz(2)-3 10 1.5];
	data.GUI.ctrl_ed_freq=uicontrol('Parent',data.GUI.panel, 'Style','edit', 'String','1000', 'Units','characters', 'Position',ctrl_pos, 'Background','w', 'FontSize',font_sz, 'HorizontalAlignment','right');
	ctrl_pos(5)=ctrl_pos(1)+ctrl_pos(3)+1;
	ctrl_pos(6)=pan_sz(1)-2-ctrl_pos(5);
	ctrl_pos(7)=pan_sz(1)-2-ctrl_pos(1);
	uicontrol('Parent',data.GUI.panel, 'Style','text', 'String','Частота анализа, Гц', 'Units','characters', 'Position',ctrl_pos([5 2 6 4]), 'FontSize',font_sz, 'HorizontalAlignment','left');

	ctrl_pos(2)=ctrl_pos(2)-ctrl_pos(4)-0.3;
	data.GUI.ctrl_ed_src_dist=uicontrol('Parent',data.GUI.panel, 'Style','edit', 'String','100', 'Units','characters', 'Position',ctrl_pos(1:4), 'Background','w', 'FontSize',font_sz, 'HorizontalAlignment','right');
	uicontrol('Parent',data.GUI.panel, 'Style','text', 'String','Расстояние до источника звука, м', 'Units','characters', 'Position',ctrl_pos([5 2 6 4]), 'FontSize',font_sz, 'HorizontalAlignment','left');

	ctrl_pos(2)=ctrl_pos(2)-ctrl_pos(4)-0.3;
	data.GUI.ctrl_ed_pt_num=uicontrol('Parent',data.GUI.panel, 'Style','edit', 'String','180', 'Units','characters', 'Position',ctrl_pos(1:4), 'Background','w', 'FontSize',font_sz, 'HorizontalAlignment','right');
	uicontrol('Parent',data.GUI.panel, 'Style','text', 'String','Число точек анализа по координате', 'Units','characters', 'Position',ctrl_pos([5 2 6 4]), 'FontSize',font_sz, 'HorizontalAlignment','left');

	ctrl_pos(2)=ctrl_pos(2)-ctrl_pos(4)-0.3;
	uicontrol('Parent',data.GUI.panel, 'Style','text', 'String','Функция антены ( y=...(x) )', 'Units','characters', 'Position',ctrl_pos([1 2 7 4]), 'FontSize',font_sz, 'HorizontalAlignment','left');
	ctrl_pos(2)=ctrl_pos(2)-10.5-0.3;
	data.GUI.ctrl_ed_expr=uicontrol('Parent',data.GUI.panel, 'Style','edit', 'String','y=sum([x{:}],2)', 'Units','characters', 'Position',[ctrl_pos([1 2 7]) 10.8], 'Background','w', 'FontSize',font_sz, 'HorizontalAlignment','left', 'Max',100);

	ctrl_pos(4)=1.8;
	ctrl_pos(2)=ctrl_pos(2)-ctrl_pos(4)-0.4;
	ctrl_pos(7)=(pan_sz(1)-ctrl_pos(1)*2)/3-ctrl_pos(1);
	data.GUI.ctrl_btn_load=uicontrol('Parent',data.GUI.panel, 'Style','pushbutton', 'String','Загрузить', 'Units','characters', 'Position',ctrl_pos([1 2 7 4]), 'Callback',@on_load);
	data.GUI.ctrl_btn_save=uicontrol('Parent',data.GUI.panel, 'Style','pushbutton', 'String','Сохранить', 'Units','characters', 'Position',[sum(ctrl_pos([1 7 1])) ctrl_pos([2 7 4])], 'Callback',@on_save);
	data.GUI.ctrl_btn_calc=uicontrol('Parent',data.GUI.panel, 'Style','pushbutton', 'String','Пересчитать', 'Units','characters', 'Position',[sum(ctrl_pos([1 7 1 7 1])) ctrl_pos([2 7 4])], 'Callback',@on_calc);

	set(data.GUI.panel, 'Units','pixels');
	pan_sz_pix=get(data.GUI.panel, 'Position');
	set(data.GUI.panel, 'Units','characters');

	data.GUI.tbl=uitable('Parent',fid, 'Units','characters', 'Position',[2 2 pan_sz(1) 10], ...
		'ColumnFormat',{'numeric' 'numeric' 'numeric' 'numeric' 'numeric'}, 'ColumnEditable',ones(1,5)>0, ...
		'ColumnName',{'X' 'Y' 'Z' 'k' 'delay'}, 'ColumnWidth',num2cell(ones(1,5)*round((pan_sz_pix(3)-60)/5)), ...
		'Data',nan(1,5), 'FontSize',font_sz, 'RearrangeableColumns','on', ...
		'TooltipString','Точки антенной решетки', 'CellEditCallback',@on_table_edit, 'CellSelectionCallback',@on_table_sel);
	
	data.antenna_file='antenna.xml';

	guidata(fid,data);
%{
	f=1000;					% Частота анализа
	c=331.46;				% Скорость звука в воздухе
	lambda=c/f;				% Длинна волны
	k=2*pi/lambda;			% Волновое число
	src_dst=100;			% Расстояние от источника звука до центра решетки

	antenna_sz=5;
	antenna_sectors_sum=9;

	data.antenna_file=['ant_circle_' num2str(antenna_sz) '_' num2str(antenna_sectors_sum) '.xml'];
	data.antenna.points=[0 0 0];
	for j=1:antenna_sz
		for i=1:antenna_sectors_sum
%			cur_dir=exp(2*pi*i*1i/antenna_sectors_sum);
			cur_dir=exp(2*pi*1i*(i+(j-1)/antenna_sz)/antenna_sectors_sum);
			data.antenna.points(end+1,:)=[real(cur_dir) imag(cur_dir) 0]*j*lambda/2;% (j^(sqrt(2)/2));
		end
	end

% 	data.antenna_file=['ant_rhomb_' num2str(antenna_sz) '.xml'];
% 	for i=-antenna_sz:antenna_sz
% 		j_sz=antenna_sz-abs(i);
% 		for j=-j_sz:j_sz
% 			data.antenna.points(end+1,:)=[i j 0];
% 		end
% 	end

%	data.antenna.points=data.antenna.points*0.1;
	
% 	src_pt=[0 0 src_dst];	% Прогиб антены для фокусировки на ближний источник
% 	dist= sqrt(sum(( antenna_pt - src_pt(ones(size(antenna_pt,1),1),:) ).^2,2)); % Расстояние от точки src_pt до каждой точки antenna_pt
% 	antenna_pt(:,3)=dist-dist(1);
	
%	dist0= sqrt(sum(antenna_pt.^2,2)); % Расстояние от точки [0 0 0] до каждой точки grate_pt
	data.antenna.factor= ones(size(data.antenna.points,1),1); % sinc(dist0);
	data.antenna.delay=zeros(size(data.antenna.factor));
	data.antenna.expr='y=sum([x{:}],2)';

	xml_write('ant_test.xml',data.antenna);
%}
end

function on_table_edit(hObject,eventdata)
	obj_data=get(hObject,'Data');
	nan_rows=all(isnan(obj_data),2);
	if any(nan_rows(1:end-1)) || not(nan_rows(end))
		set(hObject, 'Data',[obj_data(not(nan_rows),:); nan(1,size(obj_data,2))]);
	end
	guidata(hObject,antenna_points_plot(get_data(hObject)));
	on_table_sel(hObject, eventdata);
end

function on_table_sel(hObject,eventdata)
	if isempty(eventdata.Indices)
		return;
	end
	obj_data=get(hObject,'Data');
	sel_data=obj_data(eventdata.Indices(1),:);
	if any(isnan(sel_data))
		return;
	end
	
	data=guidata(hObject);
	data_pos=[get(data.GUI.scat, 'XData'); get(data.GUI.scat, 'YData'); get(data.GUI.scat, 'ZData')];

	for i=1:3
		data_pos(i,:)=data_pos(i,:)-sel_data(i);
	end
	[mv,mi]=min(sum(abs(data_pos)));
	if mv~=0
		return;
	end

	obj_clr=repmat([1 0 1],size(data_pos,2),1);
	obj_clr(mi,:)=[0 0 1];
	set(data.GUI.scat, 'CData', obj_clr);
end

function on_figure_resize(hObject,eventdata) %#ok<*INUSD>
	data=guidata(hObject);

	set(data.GUI.fid,	'Units','characters');
	set(data.GUI.panel,	'Units','characters');
	set(data.GUI.axes,	'Units','characters');
	set(data.GUI.tbl,	'Units','characters');

	fig_pos=get(data.GUI.fid,  'Position');
	pan_pos=get(data.GUI.panel,'Position');
	pan_pos=[fig_pos(3:4)-pan_pos(3:4) pan_pos(3:4)];

	set(data.GUI.panel, 'Position',pan_pos);
	set(data.GUI.tbl,	'Position',[pan_pos(1) 0 pan_pos(3) pan_pos(2)]);
	set(data.GUI.axes,  'Position',[15 5 pan_pos(1)-30 fig_pos(4)-10]);
end

function data=get_data(hObject)
	if nargin<1
		hObject=gcbo;
	end
	data=guidata(hObject);

	tbl_data=get(data.GUI.tbl, 'Data');
	nan_rows=any(isnan(tbl_data),2);
	tbl_data(nan_rows,:)=[];
	data.antenna.points=tbl_data(:,1:3);
	data.antenna.factor=tbl_data(:,4);
	data.antenna.delay=	tbl_data(:,5);
	data.antenna.expr=get(data.GUI.ctrl_ed_expr,'String');
end

function on_load(hObject,eventdata)
	data=get_data(hObject);

	[dlg_name,dlg_path]=uigetfile({'*.xml','XML files (*.xml)'},'Выберите файл для обработки');
	if dlg_name==0
		return;
	end
	data.antenna_file=fullfile(dlg_path,dlg_name);
	data.antenna=xml_read(data.antenna_file);
	guidata(data.GUI.fid,data);

	tbl_data_old=get(data.GUI.tbl, 'Data');
	tbl_data=[data.antenna.points data.antenna.factor data.antenna.delay];
	tbl_data(end+1,1:size(tbl_data_old,2))=nan;
	set(data.GUI.tbl,			'Data',tbl_data);
	set(data.GUI.ctrl_ed_expr,	'String', data.antenna.expr);
	
	guidata(hObject,antenna_points_plot(data));
end

function on_save(hObject,eventdata)
	data=get_data(hObject);

	[dlg_name,dlg_path]=uiputfile({'*.xml','XML files (*.xml)'},'Сохранить результирующий файл как...', data.antenna_file);
	if dlg_name==0
		return;
	end
	file_name=fullfile(dlg_path,dlg_name);

	xml_write(file_name,data.antenna);
end

function on_calc(hObject,eventdata)
	data=get_data(hObject);

	data.antenna.frequency=str2double(get(data.GUI.ctrl_ed_freq,'String'));
	data.antenna.c=331.46;

	data.antenna.src_dist=str2double(get(data.GUI.ctrl_ed_src_dist,'String'));
	data.antenna.src_points=str2double(get(data.GUI.ctrl_ed_pt_num,'String'));
	data.antenna.use_parfor=true;

	[x,y,z, data.antenna.center, main_lobe_ind, side_lobe_part, c_angle, c_lvl]=antenna_directivity_diagram(data.antenna);
	data.antenna.lambda=data.antenna.c/data.antenna.frequency;

	guidata(hObject,antenna_plot(data, x,y,z, main_lobe_ind, side_lobe_part, [c_angle c_lvl]));
end

function data=antenna_points_plot(data)
	scat_sz=50;
	data.GUI.scat=scatter3(data.GUI.axes, data.antenna.points(:,1), data.antenna.points(:,2), data.antenna.points(:,3), scat_sz*abs(data.antenna.factor)+0.001, 'filled');
	set(data.GUI.scat, 'CData',repmat([1 0 1], size(data.antenna.points,1), 1));
end

function data=antenna_plot(data, x, y, z, main_lobe_ind, side_lobe_part, main_lobe_angle)
	data=antenna_points_plot(data);
	hold on;

	x=x+data.antenna.center(1);
	y=y+data.antenna.center(2);
	z=z+data.antenna.center(3);

	if main_lobe_ind>1
		surf(x(1:main_lobe_ind,:),y(1:main_lobe_ind,:),z(1:main_lobe_ind,:),'FaceColor','interp','FaceAlpha',0.5);
	end
	
	if main_lobe_ind<size(x,1)
		surf(x(main_lobe_ind:end,:),y(main_lobe_ind:end,:),z(main_lobe_ind:end,:),'FaceColor','interp','FaceAlpha',0.5, 'EdgeColor','none');
	end
	hold off;

	axis('equal');
	xlabel('X'); ylabel('Y'); zlabel('Z');

	antenna_file=data.antenna_file;
	tex_sym={'\' '$' '&' '%' '#' '_' '{' '}' '~' '^'};
	for i=1:length(tex_sym)
		antenna_file=strrep(antenna_file, tex_sym{i}, ['\' tex_sym{i}]);
	end

	title({['Файл ' antenna_file '; ' ...
		num2str(size(data.antenna.points,1)) ' точек; f=' ...
		num2str(data.antenna.frequency) 'Гц; \lambda=' ...
		num2str(data.antenna.lambda) 'м;'];
		['Объем боковых лепестков ' num2str(side_lobe_part*100) ...
		'%; Максимальный угол раскрытия основного лепестка ' num2str(main_lobe_angle(1)) ...
		'\circ по уровню ' num2str(main_lobe_angle(2)) ...
		'; Геометрический центр ' sprintf('%.2f ',data.antenna.center)]});
end
