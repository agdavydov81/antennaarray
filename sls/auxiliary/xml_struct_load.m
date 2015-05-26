function cfg=xml_struct_load(xml_file_name, cfg_def)
% ������� cfg=xml_strruct_load(xml_file_name, cfg_def) ������������� ���
%   �������� ��������� �� XML ����. � � ������� ������ ���������
%   ��������� ��������� ��������.
%   ���������:
%       xml_file_name - ��� �����, ������ ����� ��������� ��������� ������;
%       cfg_def -       ��������� ������ �� ���������� ��-���������,
%                       �������������, ���� � ����� ������� ��������
%                       �����������;
%       cfg -           ����������� ��������� ������.
%
%   See also XML_STRUCT_SAVE.

%   ������: 1.0
%   �����: ������� �.�. (22.11.2008)

    cfg_names =     fieldnames(cfg_def);
    cfg_vals_def =  struct2cell(cfg_def);

    try
        xDoc=xmlread(xml_file_name);
    catch
        cfg=cfg_def;
        return;
    end

    xRoot=xDoc.getDocumentElement;
    for i=1:length(cfg_names)
        cur_val=xRoot.getAttribute(cfg_names{i});
        if ischar(cfg_vals_def{i})
            cur_val=str2mat(cur_val);
            if isempty(cur_val);    cur_val=cfg_vals_def{i};    end
        else
            cur_val=str2num(cur_val);
            if isempty(cur_val)||max(isnan(cur_val))
                cur_val=cfg_vals_def{i};
            end
        end
        cfg.(cfg_names{i})=cur_val;
    end
end
