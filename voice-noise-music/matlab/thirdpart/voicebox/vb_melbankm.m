function [x,mc,mn,mx]=vb_melbankm(p,n,fs,fl,fh,w)
%vb_melbankm determine matrix for a mel-spaced filterbank [X,MN,MX]=(P,N,FS,FL,FH,W)
%
% Inputs:	p   number of filters in filterbank or the filter spacing in k-mel [default 0.06]
%		n   length of fft
%		fs  sample rate in Hz
%		fl  low end of the lowest filter as a fraction of fs (default = 0)
%		fh  high end of highest filter as a fraction of fs (default = 0.5)
%		w   any sensible combination of the following:
%		      't'  triangular shaped filters in mel domain (default)
%		      'n'  hanning shaped filters in mel domain
%		      'm'  hamming shaped filters in mel domain
%
%		      'z'  highest and lowest filters taper down to zero (default)
%		      'y'  lowest filter remains at 1 down to 0 frequency and
%			   highest filter remains at 1 up to nyquist freqency
%
%		       If 'ty' or 'ny' is specified, the total power in the fft is preserved.
%
% Outputs:	x     a sparse matrix containing the filterbank amplitudes
%		          If the mn and mx outputs are given then size(x)=[p,mx-mn+1]
%                 otherwise size(x)=[p,1+floor(n/2)]
%                 Note that teh peak filter values equal 2 to account for the power
%                 in the negative FFT frequencies.
%           mc    the filterbank centre frequencies in mel
%		    mn    the lowest fft bin with a non-zero coefficient
%		    mx    the highest fft bin with a non-zero coefficient
%                 Note: you must specify both or neither of mn and mx.
%
% Usage:	f=fft(s);			f=fft(s);
%		x=vb_melbankm(p,n,fs);		[x,mc,na,nb]=vb_melbankm(p,n,fs);
%		n2=1+floor(n/2);		z=log(x*(f(na:nb)).*conj(f(na:nb)));
%		z=log(x*abs(f(1:n2)).^2);
%		c=dct(z); c(1)=[];
%
% To plot filterbanks e.g.	n=256; fs=8000; plot((0:floor(n/2))*fs/n,vb_melbankm(20,n,fs)')
%
% [1] S. S. Stevens, J. Volkman, and E. B. Newman. A scale for the measurement
%     of the psychological magnitude of pitch. J. Acoust Soc Amer, 8: 185–19, 1937.
% [2] S. Davis and P. Mermelstein. Comparison of parametric representations for
%     monosyllabic word recognition in continuously spoken sentences.
%     IEEE Trans Acoustics Speech and Signal Processing, 28 (4): 357–366, Aug. 1980.


%      Copyright (C) Mike Brookes 1997
%      Version: $Id: vb_melbankm.m,v 1.7 2009/10/19 10:19:40 dmb Exp $
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

if nargin < 6
    w='tz'; % default options
    if nargin < 5
        fh=0.5; % max freq is the nyquist
        if nargin < 4
            fl=0; % min freq is DC
        end
    end
end
f0=700/fs;
fn2=floor(n/2);     % bin index of Nyquist term
if isempty(p)
    p=0.06;         % spacing = 0.06 kmel
end
if p<1
    p=round(log((f0+fh)/(f0+fl))/(p*log(17/7)))-1;
end
lr=log((f0+fh)/(f0+fl))/(p+1);
% convert filter edges to fft bin numbers (0 = DC)
bl=n*((f0+fl)*exp([0 1 p p+1]*lr)-f0);  % bins: [filter1-low filter1-mid filterp-mid filterp-high]
b2=ceil(bl(2));
b3=floor(bl(3));
mc=(log(fl/f0+1)+(1:p)*lr)*1000/log(17/7);          % mel centre frequencies
if any(w=='y')          % preserve power in FFT
    pf=log((f0+(b2:b3)/n)/(f0+fl))/lr;
    fp=floor(pf);
    r=[ones(1,b2) fp fp+1 p*ones(1,fn2-b3)];
    c=[1:b3+1 b2+1:fn2+1];
    v=2*[0.5 ones(1,b2-1) 1-pf+fp pf-fp ones(1,fn2-b3-1) 0.5];
    mn=1;
    mx=fn2+1;
else
    b1=floor(bl(1))+1;            % lowest FFT bin required (0 = DC)
    b4=min(fn2,ceil(bl(4)))-1;    % highest FFT bin required (0 = DC)
    pf=log((f0+(b1:b4)/n)/(f0+fl))/lr;  % maps FFT bins to filter
    if pf(end)>p
        pf(end)=[];
        b4=b4-1;
    end
    fp=floor(pf);                  % FFT bin i contributes to filters fp(1+i-b1)+[0 1]
    pm=pf-fp;
    k2=b2-b1+1;
    k3=b3-b1+1;
    k4=b4-b1+1;
    r=[fp(k2:k4) 1+fp(1:k3)];
    c=[k2:k4 1:k3];
    v=2*[1-pm(k2:k4) pm(1:k3)];
    mn=b1+1;
    mx=b4+1;
end
if any(w=='n')
    v=1-cos(v*pi/2);      % convert triangles to Hanning
elseif any(w=='m')
    v=1-0.92/1.08*cos(v*pi/2);  % convert triangles to Hamming
end
if nargout > 2
    x=sparse(r,c,v);
    if nargout == 3
        mc=mn;    % delete mc output for legacy code compatibility
        mn=mx;
    end
else
    x=sparse(r,c+mn-1,v,p,1+fn2);
end
if ~nargout
    ng=3;
    if any(w=='n') || any(w=='m')
        ng=201;
    end
    fe=((f0+fl)*exp((0:p+1)*lr)-f0)'*fs;
    x=repmat(linspace(0,1,ng),p,1).*repmat(fe(3:end)-fe(1:end-2),1,ng)+repmat(fe(1:end-2),1,ng);
    v=2-abs(linspace(-2,2,ng));
    if any(w=='n')
        v=1-cos(v*pi/2);      % convert triangles to Hanning
    elseif any(w=='m')
        v=1-0.92/1.08*cos(v*pi/2);  % convert triangles to Hamming
    end
    v=repmat(v,p,1);
    if any(w=='y')
        v(1,1:floor(ng/2))=2;
        v(end,ceil(ng/2):end)=2;
    end
    plot(x'/1000,v','b');
    set(gca,'xlim',[fe(1) fe(end)]/1000);
    xlabel('Frequency (kHz)');
end