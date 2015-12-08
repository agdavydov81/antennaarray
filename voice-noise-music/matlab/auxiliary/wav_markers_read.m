function markers=wav_markers_read(wav_file)
% ������� markers=wav_markers_read(wav_file) ������������� ��� �������� �������
%   �������� �� .wav �����.
%   ���������:
%       wav_file - ��� �����, ������ ����� �������� ������ ��������.
%   ������������ ��������:
%       markers - ������ �������� (� �������� ������� � 1).
%
%   See also WAV_MARKERS_WRITE.

%   ������: 1.1
%   �����: ������� �.�. (25.09.2009)

    marks_file=tempname();
    dos(['"' which('WavMarkersExtractor.exe') '" "' wav_file '" "' marks_file '" >nul']);
    markers=textread(marks_file,'%d')+1;
    delete(marks_file);
end
