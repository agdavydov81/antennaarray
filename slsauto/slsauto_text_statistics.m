function info = slsauto_text_statistics(filename, vowels, syllable_cdf_threshold, display_figures)
	if nargin < 1 || isempty(filename)
		cache_name = [mfilename '_cache.mat'];

		filename = '';
		if exist(cache_name, 'file')
			load(cache_name);
		end
		
		[dlg_name, dlg_path] = uigetfile({'*.txt','Text files (*.txt)'}, 'Select file for processing', filename);
		if dlg_name==0
			return
		end
		filename = fullfile(dlg_path,dlg_name);

		save(cache_name, 'filename');
	end
	if nargin < 2 || isempty(vowels)
		vowels = 'àîóûèýÿþå¸³';
	end
	if nargin < 3 || isempty(syllable_cdf_threshold)
		syllable_cdf_threshold = 0.97;
	end
	if nargin < 4 || isempty(display_figures)
		display_figures = true;
	end

	fh = fopen(filename,'r','n','UTF-8');
	txt = textscan(fh,'%s','delimiter','\n','whitespace','');
	txt = txt{1}';
	fclose(fh);
	
	paragraph = find(~cellfun(@isempty, regexp(txt, '^[ ]{3,}[^ ]', 'match','once')));
	txt_par = arrayfun(@(b,e) cell2mat(strcat(txt(b:e),{' '})), paragraph(1:end-1), paragraph(2:end)-1, 'UniformOutput',false);


	stat = cell(size(txt_par));
	for ii = 1:numel(txt_par) % parfor
		txt_parX = txt_par{ii};
		txt_parX(txt_parX(1:end-1)==' ' & txt_parX(2:end)==' ') = [];

		stat{ii} = process_paragraph(txt_parX, vowels);
	end
	stat = cell2mat(stat);


	info.distr_par_in_sent = arrayfun(@(x) length(x.words), stat);
	info.distr_par_in_word = arrayfun(@(x) sum(cell2mat(x.word_borders)), stat);
	info.distr_par_in_syll = arrayfun(@(x) length(cell2mat(x.syllable_borders)), stat);

	info.distr_sent_in_word = cell2mat(arrayfun(@(x) cellfun(@sum, x.word_borders), stat, 'UniformOutput',false));
	info.distr_sent_in_syll = cell2mat(arrayfun(@(x) cellfun(@length, x.syllable_borders), stat, 'UniformOutput',false));

	info.distr_word_in_syll = cell2mat(arrayfun(@(x) cell2mat(cellfun(@(c) diff([0 find(c)]), x.word_borders, 'UniformOutput',false)), stat, 'UniformOutput',false));
	
	
	if display_figures
		figure('NumberTitle','off', 'Name','Distributions', 'Units','normalized', 'Position',[0 0 1 1]);
		subplot(2,2,1);
		plot(info.distr_par_in_sent, info.distr_par_in_word, 'b.');
		xlabel('Paragraph length in sentances');
		ylabel('Paragraph length in words');
		subplot(2,2,2);
		plot(info.distr_par_in_sent, info.distr_par_in_syll, 'b.');
		xlabel('Paragraph length in sentances');
		ylabel('Paragraph length in syllables');
		subplot(2,2,3);
		plot(info.distr_par_in_word, info.distr_par_in_syll, 'b.');
		xlabel('Paragraph length in words');
		ylabel('Paragraph length in syllables');
		subplot(2,2,4);
		plot(info.distr_sent_in_word, info.distr_sent_in_syll, 'b.');
		xlabel('Sentance length in words');
		ylabel('Sentance length in syllables');
	end


	words = cell2mat([stat.words]);
	syllable_borders = [stat.syllable_borders];
	offsets = cumsum([0 cellfun(@(x) x(end), syllable_borders(1:end-1))]);
	syllable_borders = [0 cell2mat(cellfun(@(i,o) i+o, syllable_borders, num2cell(offsets), 'UniformOutput',false))];
	syllables = arrayfun(@(i,j) words(i+1:j), syllable_borders(1:end-1), syllable_borders(2:end), 'UniformOutput',false);

	[syllables_ind, ~, info.syllables_uniques] = grp2idx(syllables);
	syllables_hist = hist(syllables_ind, 1:numel(info.syllables_uniques));
	[syllables_hist,si] = sort(syllables_hist, 'descend');
	info.syllables_uniques = info.syllables_uniques(si);
	[~,ssi] = sort(si);
	syllables_ind = ssi(syllables_ind);
	if ~isequal(syllables, info.syllables_uniques(syllables_ind)')
		error('Probability reordering error.');
	end


	syllables_cdf = cumsum(syllables_hist) / numel(syllables);
	syllables_thr_ind = round(interp1q(syllables_cdf(:), (1:numel(syllables_hist))', syllable_cdf_threshold));

	if display_figures
		figure('NumberTitle','off', 'Name','Syllables dictionary distribution', 'Units','normalized', 'Position',[0 0 1 1]);
		subplot(1,2,1);
		plot(syllables_hist / numel(syllables));
		line(syllables_thr_ind+[0 0], ylim(), 'Color','r');
		ylabel('Probability density function');
		subplot(1,2,2);
		plot(syllables_cdf);
		line(syllables_thr_ind+[0 0], ylim(), 'Color','r');
		ylabel('Cumulative density function');
	end

	info.syllables_uniques(syllables_thr_ind:end) = [];
	syllables_hist(syllables_thr_ind:end) = [];

	ki = syllables_ind >= syllables_thr_ind;
	ki(1:end-1) = ki(1:end-1) | ki(2:end);
	syllables_ind_IJ = [syllables_ind(1:end-1)' syllables_ind(2:end)'];
	syllables_ind_IJ(ki(1:end-1)', :) = []; 

	info.syllables_pdf = zeros(numel(info.syllables_uniques));
	for ii = 1:size(syllables_ind_IJ,1)
		info.syllables_pdf(syllables_ind_IJ(ii,1), syllables_ind_IJ(ii,2)) = info.syllables_pdf(syllables_ind_IJ(ii,1), syllables_ind_IJ(ii,2)) + 1;
	end
	if any(size(info.syllables_pdf) ~= numel(info.syllables_uniques))
		error('Probability marix building error');
	end
	
	if nargout < 1
		save([mfilename '_result.mat'], 'info');
	end
end

function stat = process_paragraph(txt_par, vowels)
	sentances = regexp(txt_par, '[A-ZÀ-ß][^.!?]*(\.|\?|\!)+', 'match');
	
	stat.words = cell(size(sentances));
	stat.word_borders = cell(size(sentances));
	stat.syllable_borders = cell(size(sentances));
	ski = false(size(sentances));
	for si = 1:numel(sentances)
		words = regexp(lower(sentances{si}), '[a-zà-ÿ]+', 'match');

		% Remove monosyllable words
		words( cellfun(@(w) sum(any(repmat(w,numel(vowels),1) == repmat(vowels(:),1,numel(w)), 1)), words) < 2 ) = [];

		if isempty(words)
			ski(si) = true;
			continue
		end
		
		word_borders = cumsum(cellfun(@length, words));
		words = cell2mat(words);
		stat.words{si} = words;

		syllable_bordres = find(any(repmat(words,numel(vowels),1) == repmat(vowels(:),1,numel(words)), 1));
		
		syllable_bordres_mat = repmat(syllable_bordres,numel(word_borders),1);
		word_borders_mat = repmat(word_borders(:),1,numel(syllable_bordres)-1);
		wdi = any( syllable_bordres_mat(:,1:end-1) <= word_borders_mat & word_borders_mat < syllable_bordres_mat(:,2:end), 1);
		stat.word_borders{si} = [wdi true];

		ii = diff(syllable_bordres) > 2 & ~wdi;
		syllable_bordres(ii) = syllable_bordres(ii) + 1;
		ti = min(syllable_bordres+1,numel(words));
		ii = words(ti) == 'ü' | words(ti) == 'ú';
		syllable_bordres(ii) = syllable_bordres(ii) + 1;

		syllable_bordres(stat.word_borders{si}) = word_borders;

		stat.syllable_borders{si} = syllable_bordres;
	end
	stat.words(ski) = [];
	stat.word_borders(ski) = [];
	stat.syllable_borders(ski) = [];
end
