function [b,d] = vb_frq2bark(f,m)
%vb_frq2bark  Convert Hertz to BARK frequency scale BARK=(FRQ)
%       bark = vb_frq2bark(frq) converts a vector of frequencies (in Hz)
%       to the corresponding values on the BARK scale.
% Inputs: f  list of frequencies in Hz
%         m  mode options
%            'h'   apply high frequency correction
%            'l'   apply low frequency correction
%
% Outputs: b  list of bark values
%          d  list of derivatives: d(bark)/d(freq)

%   There are many published formulae approximating the Bark scale.
%   We use the one from Traunmuller.
%   The high and low frequency corrections give a better fit to [2]
%   but make the derviative discontinuous.
%   The Bark scale is named in honour of Barkhausen, the creator
%   of the unit of loudness level [2].

%   [1] H. Traunmuller, Analytical Expressions for the
%       Tonotopic Sensory Scale”, J. Acoust. Soc. Am. 88,
%       1990, pp. 97-100.
%   [2] E. Zwicker, Subdivision of the audible frequency range into
%       critical bands, J Accoust Soc Am 33, 1961, p248.

%      Copyright (C) Mike Brookes 2006
%      Version: $Id: vb_frq2bark.m,v 1.4 2009/05/15 15:06:43 dmb Exp $
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

if nargin<2
    m=' ';
end
b=26.81*f./(1960+f)-0.53;
d=52547.6*(1960+f).^(-2);
if any(m=='l')
    d(b<2)=d(b<2)*0.85;
    b=b+0.15*(2-b).*(b<2);
end
if any(m=='h')
    d(b>20.1)=d(b>20.1)*1.22;
    b=b+0.22*(b-20.1).*(b>20.1);
end
if ~nargout
    plot(f,b,'x-b',f,d*1000,'-r');
    xlabel('Frequency (Hz)');
    ylabel('Bark + derivative*1000');
end
