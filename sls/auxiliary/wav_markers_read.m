function markers=wav_markers_read(wav_file)
% Функция markers=wav_markers_read(wav_file) предназначена для загрузки вектора
%   маркеров из .wav файла.
%   Параметры:
%       wav_file - имя файла, откуда будет загружен вектор маркеров.
%   Возвращаемое значение:
%       markers - вектор маркеров (в отсчетах начиная с 1).
%
%   See also WAV_MARKERS_WRITE.

%   Версия: 1.1
%   Автор: Давыдов А.Г. (25.09.2009)

    marks_file=tempname();
    dos(['"' which('WavMarkersExtractor.exe') '" "' wav_file '" "' marks_file '" >nul']);
    markers=textread(marks_file,'%d')+1;
    delete(marks_file);
end
