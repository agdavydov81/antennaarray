function [region_pos, region_name]=wav_regions_read(wav_file)
% Функция [region_pos, region_name]=wav_regions_read(wav_file) предназначена для загрузки
%   регионов из .wav файла.
%   Параметры:
%       wav_file - имя файла, откуда будут загружены регионы;
%       region_pos - матрица Nx2 регионов [начало длинна] (в отсчетах начиная с 1).
%		region_name - cell имен регионов
%
%   See also WAV_REGIONS_WRITE.

%   Версия: 1.1
%   Автор: Давыдов А.Г. (18.05.2010)

	txt_file=tempname();
	dos(['"' which('WavRegionsExtractor.exe') '" "' wav_file '" "' txt_file '" >nul']);
	[a b region_name]=textread(txt_file,'%d%d%s', 'whitespace','\t');
	region_pos=[a+1, b];
	delete(txt_file);
end
