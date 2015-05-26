function wav_markers_write(wav_file, markers)
% Функция wav_markers_write(wav_file, markers) предназначена для сохранения
%   вектора маркеров в .wav файл.
%   Параметры:
%       wav_file - имя файла, куда будет сохранен вектор маркеров;
%       markers - вектор маркеров (в отсчетах начиная с 1).
%
%   See also WAV_MARKERS_READ.

%   Версия: 1.1
%   Автор: Давыдов А.Г. (18.05.2010)

    marks_file=tempname();
    fh=fopen(marks_file, 'w');
    fprintf(fh, '%d ', markers-1);
    fclose(fh);
    dos(['"' which('WavMarkersBinder.exe') '" "' wav_file '" "' marks_file '" >nul']);
    delete(marks_file);
end
