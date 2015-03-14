function vnm_3sec_base(base_directory,out_directory)
    % Скрипт для создания базы длительностью 3 секунды
	mkdir(out_directory);
	list=dir(base_directory);
	list([list.isdir])=[];
	list={list.name};
	list=strcat({[base_directory filesep]},list);
    for is=1:length(list)
	vnm_3sec_file(list{is},out_directory);
    end
end
   function vnm_3sec_file(signal_file,out_directory) 
   
    [x,fs]=wavread(signal_file);
	 k=randi(12*fs);
    if(k<fs)
     y=x(1:3*fs);
    else
         if(k>10*fs)
          y=x(end+1-3*fs:end);
         else
          y=x(k-fs+1:k+2*fs);   
         end
    end 
		
	[~,nsf]=fileparts(signal_file);
	wavwrite(y,fs,[out_directory filesep nsf '.wav']);
end