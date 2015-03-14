function [cepstra, spectra, pspectrum, lpcas, F, M] = rm_rastaplp(samples, sr, dorasta, modelorder)
%[cepstra, spectra, lpcas] = rm_rastaplp(samples, sr, dorasta, modelorder)
%
% cheap version of log rasta with fixed parameters
%
% output is matrix of features, row = feature, col = frame
%
% sr is sampling rate of samples, defaults to 8000
% dorasta defaults to 1; if 0, just calculate PLP
% modelorder is order of PLP model, defaults to 8.  0 -> no PLP
%
% rm_rastaplp(d, sr, 0, 12) is pretty close to the unix command line
% feacalc -dith -delta 0 -ras no -plp 12 -dom cep ...
% except during very quiet areas, where our approach of adding noise
% in the time domain is different from rasta's approach 
%
% 2003-04-12 dpwe@ee.columbia.edu after shire@icsi.berkeley.edu's version

if nargin < 2
  sr = 8000;
end
if nargin < 3
  dorasta = 1;
end
if nargin < 4
  modelorder = 8;
end

% add miniscule amount of noise
%samples = samples + randn(size(samples))*0.0001;

% first compute power spectrum
pspectrum = rm_powspec(samples, sr);

% next group to critical bands
aspectrum = rm_audspec(pspectrum, sr);
nbands = size(aspectrum,1);

if dorasta ~= 0

  % put in log domain
  nl_aspectrum = log(aspectrum);

  % next do rasta filtering
  ras_nl_aspectrum = rm_rastafilt(nl_aspectrum);

  % do inverse log
  aspectrum = exp(ras_nl_aspectrum);

end
  
% do final auditory compressions
postspectrum = rm_postaud(aspectrum, sr);

if modelorder > 0

  % LPC analysis 
  lpcas = rm_dolpc(postspectrum, modelorder);

  % convert lpc to cepstra
  cepstra = rm_lpc2cep(lpcas, modelorder+1);

  % .. or to spectra
  [spectra,F,M] = rm_lpc2spec(lpcas, nbands);

else
  
  % No LPC smoothing of spectrum
  spectra = postspectrum;
  cepstra = rm_spec2cep(spectra);
  
end

cepstra = rm_lifter(cepstra, 0.6);
