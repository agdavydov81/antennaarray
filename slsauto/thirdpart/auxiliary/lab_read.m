function lab_info = lab_read(lab_path)
%  lab_info = lab_read(lab_path)

	% from http://stackoverflow.com/questions/6863147/matlab-how-to-display-utf-8-encoded-text-read-from-file
	fh = fopen(lab_path, 'rb');
	lab_info = fread(fh, '*uint8')';             %'# read bytes
	fclose(fh);

	%# decode as unicode string
	lab_info = native2unicode(lab_info,'UTF-8');

	% parse
	lab_info = regexp(lab_info, '(\d+) (\d+) ?([^\r\n]*)', 'tokens');
	lab_info = cellfun(@(x) struct(	'begin',str2double(x{1})/10000000, ...
									'end',	str2double(x{2})/10000000, ...
									'string',x{3}), lab_info(:));
end
