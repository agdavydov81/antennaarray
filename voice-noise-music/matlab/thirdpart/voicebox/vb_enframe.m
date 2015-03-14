function f=vb_enframe(x,win,inc)
%vb_enframe split signal up into (overlapping) frames: one per row. F=(X,WIN,INC)
%
%	F = vb_enframe(X,LEN) splits the vector X(:) up into
%	frames. Each frame is of length LEN and occupies
%	one row of the output matrix. The last few frames of X
%	will be ignored if its length is not divisible by LEN.
%	It is an error if X is shorter than LEN.
%
%	F = vb_enframe(X,LEN,INC) has frames beginning at increments of INC
%	The centre of frame I is X((I-1)*INC+(LEN+1)/2) for I=1,2,...
%	The number of frames is fix((length(X)-LEN+INC)/INC)
%
%	F = vb_enframe(X,WINDOW) or vb_enframe(X,WINDOW,INC) multiplies
%	each frame by WINDOW(:)
%
% Example of frame-based processing:
%          INC=20       													% set frame increment
%          NW=INC*2     													% oversample by a factor of 2 (4 is also often used)
%          S=cos((0:NW*7)*6*pi/NW);								% example input signal
%          W=sqrt(hamming(NW+1)); W(end)=[];      % sqrt hamming window of period NW
%          F=vb_enframe(S,W,INC);               			% split into frames
%          ... process frames ...
%          X=vb_overlapadd(F,W,INC);           			% reconstitute the time waveform (omit "X=" to plot waveform)

%	   Copyright (C) Mike Brookes 1997
%      Version: $Id: vb_enframe.m,v 1.6 2009/06/08 16:21:42 dmb Exp $
%
%   VOICEBOX is a MATLAB toolbox for speech processing.
%   Home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   http://www.gnu.org/copyleft/gpl.html or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nx=length(x(:));
nwin=length(win);
if (nwin == 1)
   len = win;
else
   len = nwin;
end
if (nargin < 3)
   inc = len;
end
nf = fix((nx-len+inc)/inc);
f=zeros(nf,len);
indf= inc*(0:(nf-1)).';
inds = (1:len);
f(:) = x(indf(:,ones(1,len))+inds(ones(nf,1),:));
if (nwin > 1)
    w = win(:)';
    f = f .* w(ones(nf,1),:);
end


