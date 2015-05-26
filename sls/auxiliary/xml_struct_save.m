function xml_struct_save(xml_file_name, cfg)
% ������� xml_struct_save(xml_file_name, cfg) ������������� ���
%   ���������� ��������� ������ � XML �����. � � ������� ������ ���������
%   ��������� ��������� ��������.
%   ���������:
%       xml_file_name - ��� �����, ���� ����� ��������� ��������� ������;
%       cfg -           ��������� ������ ��� ����������.
%
%   See also XML_STRUCT_LOAD.

%   ������: 1.0
%   �����: ������� �.�. (22.11.2008)

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
