function [x,aspc,spec] = rm_invmelfcc(cep, sr, varargin)
% [x,aspc,spec] = rm_invmelfcc(cep, sr[, opts ...])
%    Attempt to invert plp cepstra back to a full spectrum
%    and even a waveform.  Takes all the same options as rm_melfcc.
%    x is (noise-excited) time domain waveform; aspc is the 
%    auditory spectrogram, spec is the |STFT| spectrogram.
% 2005-05-15 dpwe@ee.columbia.edu

% Parse out the optional arguments
[wintime, hoptime, numcep, rm_lifterexp, sumpower, preemph, dither, ...
 minfreq, maxfreq, nbands, bwidth, dcttype, fbtype, usecmp, modelorder] = ...
    rm_process_options(varargin, 'wintime', 0.025, 'hoptime', 0.010, ...
          'numcep', 13, 'rm_lifterexp', 0.6, 'sumpower', 1, 'preemph', 0.97, ...
	  'dither', 0, 'minfreq', 0, 'maxfreq', 4000, ...
	  'nbands', 40, 'bwidth', 1.0, 'dcttype', 2, ...
	  'fbtype', 'mel', 'usecmp', 0, 'modelorder', 0);

winpts = round(wintime*sr);
nfft = 2^(ceil(log(winpts)/log(2)));

cep = rm_lifter(cep, rm_lifterexp, 1);   % 3rd arg nonzero means undo rm_liftering

% Need to reconstruct the two extra flanking bands for rm_invpostaud to delete
% (if we're doing usecmp)
pspc = rm_cep2spec(cep, nbands+2*usecmp, dcttype);

if (usecmp)
  aspc = rm_invpostaud(pspc, maxfreq, fbtype);
else
  aspc = pspc;
end

% Undo the auditory spectrum (inline)
spec = rm_invaudspec(aspc, sr, nfft, fbtype, minfreq, maxfreq, sumpower, bwidth);

% Back to waveform (modulate white noise)
x = rm_invpowspec(spec, sr, wintime, hoptime);

if preemph ~= 0
  % Undo the original preemphasis
  x = filter(1, [1 -preemph], x);
end
