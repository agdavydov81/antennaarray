function cc=poly2cc(a, err_pwr, lpcc_order)
%POLY2CC Convert linear prediction coefficients to cepstral coefficients.
%   CC=POLY2CC(A, LPCC_ORDER) converts the prediction polynomial specified
%   by A, into the corresponding cepstral coefficients, CC. The number of
%   cepstral coefficients is specified by LPCC_ORDER parameter.
%
%   CC=POLY2CC(A, ERR_PWR, LPCC_ORDER) specify prediction error power
%   ERR_PWR, usually computed as [A, ERR_PWR]=LPC(...). By default ERR_PWR
%   assumed as 1.
%
%   POLY2CC normalizes the prediction polynomial by A(1). In unnormalized
%   case ERR_PWR assumed as ERR_PWR=ERR_PWR/(A(1)*A(1))
%   For more information, see
%       <a href="matlab:doc('lpctofromcepstralcoefficients')">the MATLAB Simulink documentation</a>.
%       <a href="matlab:doc('dsp.LPCToCepstral')">the MATLAB DSP Toolbox documentation</a>.
%       <a href = "http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/doc/voicebox/lpcar2cc.html">The VOICEBOX Web Site</a>
%
%   See also CC2POLY, POLY2LSF, POLY2RC, POLY2AC, RC2IS. 
%            dsp.LPCToCepstral

	if nargin==2 % convert call c=poly2cc(a, lpcc_order) to standart case
		lpcc_order=err_pwr;
		err_pwr=1;
	end

	if a(1)==1 % Normalized filter case
		cc0=log(err_pwr);
	else % Unnormalized filter
		if err_pwr==1
			cc0=log(1/(a(1)*a(1)));
			a=a/a(1);
		else
			cc0=log(err_pwr/(a(1)*a(1)));
			a=a/a(1);
		end
	end

	cc=zeros(1, lpcc_order-1);
	a(1)=[];

	for m=1:min(length(a),lpcc_order-1)
		k=1:m-1;
		cc(m)=-a(m)-sum((m-k).*a(k).*cc(m-k))/m;
	end

	k=1:length(a);
	for m=length(a)+1:lpcc_order-1
		cc(m)=-sum((m-k).*a(k).*cc(m-k))/m;
	end

	cc=[cc0 cc];
end
