function [region_pos, region_name]=wav_regions_read(wav_file)
% ������� wav_regions_read(wav_file) ������������� ��� ��������
%   �������� �� .wav �����.
%   ���������:
%       wav_file - ��� �����, ������ ����� ��������� �������;
%       region_pos - ������� Nx2 �������� [������ ������] (� �������� ������� � 1).
%		region_name - cell ���� ��������
%
%   See also WAV_REGIONS_WRITE.

%   ������: 1.1
%   �����: ������� �.�. (18.05.2010)

	txt_file=tempname();
	dos(['"' which('WavRegionsExtractor.exe') '" "' wav_file '" "' txt_file '" >nul']);
	[a b region_name]=textread(txt_file,'%d%d%s', 'whitespace','\t');
	region_pos=[a+1, b];
	delete(txt_file);
end
