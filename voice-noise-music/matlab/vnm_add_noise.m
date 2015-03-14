function vnm_add_noise(signals_directory,noise_file, out_directory,SNR_dB)
	mkdir(out_directory);
	list=dir(signals_directory);
	list([list.isdir])=[];
	list={list.name};
	list=strcat({[signals_directory filesep]},list);
	for is=1:length(list)
		vnm_add_noise_to_signal(list{is},noise_file,out_directory,SNR_dB);
	end
end