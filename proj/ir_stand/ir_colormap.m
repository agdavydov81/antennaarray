function cm = ir_colormap(ax, palette)
    if ischar(palette)
        palette=getcolormap(palette);
    end
	if isa(palette,'float') && size(palette,2)==4
		palette=makecolormap(palette);
	end
    cm = colormap(ax, palette);
end

function map=getcolormap(colormaptype)
    switch lower(colormaptype)
        case 'flir'
			ii = linspace(0,1,64)';
			map = [	polyval([ 0.9207 -3.295  3.21 -0.02259], ii) ...
					polyval([-2.409   4.369 -1.258 0.1703], ii) ...
					polyval([10.25  -14.25   4.67  0.2159], ii) ];
			map = max(0,min(1,map));
		case 'anti gray'
            map=makecolormap([    0      1   1   1;...
                                  1      0   0   0]);
        case 'speech'
            map=makecolormap([    0      0   0   1;...
                                1/3      0   1   0;...
                                2/3      1   0   0;...
                                  1      1   1   0]);
        case 'fire'
            map=makecolormap([    0      0   0   0;...
                              0.113    0.5   0   0;...
                              0.315      1   0   0;...
                              0.450      1 0.5   0;...
                              0.585      1   1   0;...
                              0.765      1   1 0.5;...
                                  1      1   1   1]);
        case 'hsl'
            map=makecolormap([    0      0   0   0;...
                                1/7      1   0   1;...
                                2/7      0   0   1;...
                                3/7      0   1   1;...
                                4/7      0 0.5   0;...
                                5/7      1   1   0;...
                                6/7      1   0   0;...
                                  1      1   1   1]);
        otherwise
            map=colormaptype;
    end
end

function map=makecolormap(map_info)
    map=zeros(64,3);
    map(1,:)=map_info(1,2:4);
    index=1;
    for i=2:63
        pos=(i-1)/63;
        while map_info(index,1)<=pos
            index=index+1;
        end
        map(i,:)=map_info(index-1,2:4)+(map_info(index,2:4)-map_info(index-1,2:4))*(pos-map_info(index-1,1))/(map_info(index,1)-map_info(index-1,1));
    end
    map(64,:)=map_info(end,2:4);
end
