function sls_automake()
	obj = pitch_sdkobs('d:\Matlab work\kaz\snd\cut.flac');

end

function obj = pitch_sdkobs(snd_filename)
	try
%		frame_obs_list={'power' 'pitch' 'tone' 'lsf' 'lpcc' 'hos' 'phonfunc' 'specrel' 'mfcc' 'rceps'};

%		obs_list_str = [{'time'} frame_obs_list];

		[snd.path, snd.name, snd.ext] =  fileparts(snd_filename);

		tmp_dir=tempname();
		mkdir(tmp_dir);
		copyfile(snd_filename, fullfile(tmp_dir,[snd.name snd.ext]));

		cmd_name = which('SVMClassifierSN_cmd.exe');
		cfg_name = dir(fullfile(fileparts(cmd_name), '*.xml'));
		cfg_name = fullfile(fileparts(cmd_name), cfg_name.name);

		tmp_do = fullfile(tmp_dir, 'do.bat');
		fh = fopen(tmp_do, 'w');
		fprintf(fh, '%s\n', tmp_dir(1:2));
		fprintf(fh, 'cd "%s"\n', tmp_dir(3:end));
		fprintf(fh, '"%s" . -c "%s" -b 65536 -ch 1', cmd_name, cfg_name);
		fclose(fh);
		[dos_status, dos_result]=dos(tmp_do);

		if ~isempty(obs_list_str)
			cl_dir=dir([tmp_dir filesep '*__SVMClassifierSN']);
			cl_dir=sort({cl_dir.name});
			obs_dir=[tmp_dir filesep cl_dir{2} filesep];

			for oi=1:numel(obs_list_str)
				if strcmp(obs_list_str{oi},'time')
					obj.time = load([obs_dir 'frameobs_pos.txt']);
					if isempty(obj.time)
						error('emo:obs:sdkobs','There are no observations calculated.');
					end
					obj.time = feval(algs.obs_general.precision, obj.time(:,2));
				elseif any(strcmp(obs_list_str{oi}, frame_obs_list))
					obj.(obs_list_str{oi}) = feval(algs.obs_general.precision, load([obs_dir 'frameobs_' obs_list_str{oi} '.txt']) );
				elseif strcmp(obs_list_str{oi}, 'hist_dist')
					obj.hist_dist = feval(algs.obs_general.precision, load([obs_dir 'hist_pos_dist.txt']) );
					obj.hist_dist(:,1)=[];
				elseif strcmp(obs_list_str{oi}, 'svm')
					obj.svm = feval(algs.obs_general.precision, load([obs_dir 'svm_pos_obs_predict.txt']) );
					obj.svm(:,1) = [];
				end
			end
		end
	catch ME
		disp(ME.message);
		disp(ME.stack(1));
	end
	
	try
		rmdir(tmp_dir,'s');
	catch ME
	end
end
