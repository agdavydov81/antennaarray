function wav_regions_write(wav_file, region_pos, region_name)
% ������� wav_regions_write(wav_file, region_pos, region_name) ������������� ��� ����������
%   ������� �������� � .wav ����.
%   ���������:
%       wav_file - ��� �����, ���� ����� �������� ������ ��������;
%       region_pos - ������� Nx2 �������� [������ ������] (� �������� ������� � 1).
%		region_name - cell ���� ��������
%
%   See also WAV_REGIONS_READ.

%   ������: 1.2
%   �����: ������� �.�. (18.05.2010)

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
