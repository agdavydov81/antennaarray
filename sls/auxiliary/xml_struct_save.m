function xml_struct_save(xml_file_name, cfg)
% Функция xml_struct_save(xml_file_name, cfg) предназначена для
%   сохранения структуры данных в XML файле. С её помощью удобно сохранять
%   различные структуры настроек.
%   Параметры:
%       xml_file_name - имя файла, куда будет сохранена структура данных;
%       cfg -           структура данных для сохранения.
%
%   See also XML_STRUCT_LOAD.

%   Версия: 1.0
%   Автор: Давыдов А.Г. (22.11.2008)

    xDoc=com.mathworks.xml.XMLUtils.createDocument('root_element');
    xRoot=xDoc.getDocumentElement;

    cfg_names = fieldnames(cfg);
    cfg_vals =  struct2cell(cfg);
    
    for i=1:length(cfg_names)
        cur_val=cfg_vals{i};
        if isnumeric(cur_val);  cur_val=num2str(cur_val);   end
        xRoot.setAttribute(cfg_names{i}, cur_val);
    end

    xmlwrite(xml_file_name, xDoc);
end
