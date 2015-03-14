function on_zoom_pan(hObject, eventdata) %#ok<INUSD>
	x_lim=xlim();

	data=guidata(hObject);
	if isfield(data,'user_data') && isfield(data.user_data.x_len)
		rg=x_lim(2)-x_lim(1);
		if x_lim(1)<0
			x_lim=[0 rg];
		end
		if x_lim(2)>data.user_data.x_len
			x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
		end
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end
