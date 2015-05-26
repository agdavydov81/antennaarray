function wav_markers_write(wav_file, markers)
% ������� wav_markers_write(wav_file, markers) ������������� ��� ����������
%   ������� �������� � .wav ����.
%   ���������:
%       wav_file - ��� �����, ���� ����� �������� ������ ��������;
%       markers - ������ �������� (� �������� ������� � 1).
%
%   See also WAV_MARKERS_READ.

%   ������: 1.1
%   �����: ������� �.�. (18.05.2010)

    marks_file=tempname();
    fh=fopen(marks_file, 'w');
    fprintf(fh, '%d ', markers-1);
    fclose(fh);
    dos(['"' which('WavMarkersBinder.exe') '" "' wav_file '" "' marks_file '" >nul']);
    delete(marks_file);
end
