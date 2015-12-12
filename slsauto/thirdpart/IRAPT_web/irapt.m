function [ F0, time_marks, Voc_value] = irapt(Sig, Fs, type)
%IRAPT -- implementation of instanteneous RAPT algorithm.
%  [F0, time_marks, Voc_value] = irapt(Sig, Fs, type)
%  Sig -- input signal
%  Fs  -- sampling frequency
%  F0  -- f0 estimations
%  time_marks -- corresponding time marks (in seconds)
%  Voc_value -- vocalization degree in [0 1] range
%  type -- 'irapt1' or 'irapt2'

if(Fs~=44100)
    Sig=resample(Sig,44100,Fs);
    Fs=44100;
end

[F0,Voc_value,Cfg] = irapt1(Sig');
Voc_value(numel(F0)+1:end) = [];
if (strcmpi(type,'irapt2'))
    F0 = irapt2(Cfg,Sig',F0);   %IRAPT2
end

time_marks = (0:length(F0)-1)'*Cfg.step_smp/Fs;

end
