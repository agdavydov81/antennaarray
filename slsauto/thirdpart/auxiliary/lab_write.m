function lab_write(lab_info, lab_path)
% lab_write(lab_path, lab_info)

	% from http://stackoverflow.com/questions/12415767/write-unicode-strings-to-a-file-in-matlab
	fh = fopen(lab_path, 'w');
	arrayfun(@(x) fprintf(fh,'%d %d ',round(x.begin*10000000),round(x.end*10000000))+fwrite(fh,unicode2native(x.string,'UTF-8'),'uint8')+fprintf(fh,'\n'), lab_info);
	fclose(fh);
end
