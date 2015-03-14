function wav_regions_write(wav_file, region_pos, region_name)
% Функция wav_regions_write(wav_file, region_pos, region_name) предназначена для сохранения
%   вектора регионов в .wav файл.
%   Параметры:
%       wav_file - имя файла, куда будет сохранен вектор регионов;
%       region_pos - матрица Nx2 регионов [начало длинна] (в отсчетах начиная с 1).
%		region_name - cell имен регионов
%
%   See also WAV_REGIONS_READ.

%   Версия: 1.2
%   Автор: Давыдов А.Г. (18.05.2010)

	txt_file=tempname();
	fh=fopen(txt_file, 'w');
	for i=1:size(region_pos,1)
		if isa(region_name,'char') || length(region_name)==1
			cur_reg=region_name;
		else
			cur_reg=region_name{i};
		end
		fprintf(fh, '%d\t%d\t%s\n', region_pos(i,1)-1, region_pos(i,2), cur_reg);
	end
	fclose(fh);
	dos(['"' which('WavRegionsBinder.exe') '" "' wav_file '" "' txt_file '" >nul']);
	delete(txt_file);
end
