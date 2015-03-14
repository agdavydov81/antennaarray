function plot_regions(reg, patch_clr, patch_transparency)
	if nargin<2
		patch_clr=[1 0 1];
	end
	if nargin<3
		patch_transparency=0.3;
	end

    y_lim=ylim();
	z_pos=-0.1;
    pv=[0 y_lim(1) z_pos; 0 y_lim(2) z_pos; 1 y_lim(2) z_pos; 1 y_lim(1) z_pos];
    pc=[patch_clr;  patch_clr;  patch_clr;  patch_clr];
    pf=[1 2 3; 1 3 4];
	zlim([-1 0]);

    for i=1:size(reg,1)
        pv([1 2],1)=reg(i,1);
        pv([3 4],1)=reg(i,2);
        patch('Vertices',pv,'Faces',pf,'FaceVertexCData',pc,'FaceColor','flat','EdgeColor','none','FaceAlpha',patch_transparency); 
    end
end
