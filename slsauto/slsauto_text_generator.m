function outtext = slsauto_text_generator(stat_result_filename, text_length)
	if nargin<1
		[dlg_name, dlg_path] = uigetfile({'*.mat','MATLAB files (*.mat)'}, 'Select statistics result file', 'slsauto_text_statistics_result.mat');
		if dlg_name==0
			return
		end
		stat_result_filename = fullfile(dlg_path,dlg_name);
	end
	if nargin<2
		text_length = 1000;
	end

	stat = load(stat_result_filename);
	[stat.info.ecdf_par_in_syll.hy, stat.info.ecdf_par_in_syll.hx] = ecdf(stat.info.distr_par_in_syll);
	[stat.info.ecdf_sent_in_syll.hy, stat.info.ecdf_sent_in_syll.hx] = ecdf(stat.info.distr_sent_in_syll);
	stat.info.syllables_cdf = cumsum(stat.info.syllables_pdf,2);
	stat.info.syllables_cdf = stat.info.syllables_cdf ./ repmat(stat.info.syllables_cdf(:,end), 1, size(stat.info.syllables_cdf,2));

	outtext = '';
	while length(outtext) < text_length
		outtext = [outtext gen_paragraph(stat)]; %#ok<AGROW>
	end
end

function text = gen_paragraph(stat)
	text = '    ';
	
	par_in_syll = round(interp1q(stat.info.ecdf_par_in_syll.hy, stat.info.ecdf_par_in_syll.hx, rand()));
	par_syll_num = 0;

	while true
		sent_in_syll = round(interp1q(stat.info.ecdf_sent_in_syll.hy, stat.info.ecdf_sent_in_syll.hx, rand()));
		if (par_syll_num + sent_in_syll - par_in_syll)/sent_in_syll >= 0.5
			break
		end

		sylls = cell(1, sent_in_syll);
		syll_last = 1;
		for si = 1:numel(sylls)
			syll_next = max(1,round(interp1q(stat.info.syllables_cdf(syll_last,:)', (1:size(stat.info.syllables_cdf,2))', rand())));
			sylls(si) = stat.info.syllables_uniques(syll_next);
			syll_last = syll_next;
		end
	end
end