function vnm_3sec_random_mixing(signals_dir,noise_dir, out_directory)
    mkdir(out_directory);
	list=dir(signals_dir);
	list([list.isdir])=[];
	list={list.name};
    
    list2=dir(noise_dir);
	list2([list2.isdir])=[];
	list2={list2.name};
    cp=1:length(list);
    if length(list)~=3*length(list2)
        error('Lengths speech and noise directories are differents.');
    end
       
    for is=1:length(list2)
        k1=randi(length(cp)); s1=cp(k1); cp(k1)=[];
        k2=randi(length(cp)); s2=cp(k2); cp(k2)=[];
        k3=randi(length(cp)); s3=cp(k3); cp(k3)=[];
        
		vnm_3sec_mixed_signal([signals_dir filesep list{s1}],[noise_dir filesep list2{is}],out_directory,-10);
        vnm_3sec_mixed_signal([signals_dir filesep list{s2}],[noise_dir filesep list2{is}],out_directory,0);
        vnm_3sec_mixed_signal([signals_dir filesep list{s3}],[noise_dir filesep list2{is}],out_directory,10);
    end
end