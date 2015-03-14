function [y, speech_reg]=find_regions(x, min_pause, min_speech)
	dx=diff([0; x; 0]);
	regs_beg=find(dx==1);
	regs_end=find(dx==-1);

	small_pause = regs_beg(2:end)-regs_end(1:end-1) < min_pause;
	regs_beg([false; small_pause])=[];
	regs_end([small_pause; false])=[];

	small_speech= regs_end-regs_beg < min_speech;
	regs_beg(small_speech)=[];
	regs_end(small_speech)=[];
	speech_reg=[regs_beg regs_end-1];
	if isempty(speech_reg)
		speech_reg=zeros(0,2);
	end

	y=false(size(x));
	for i=1:size(speech_reg,1)
		y(speech_reg(i,1):speech_reg(i,2))=true;
	end
end
