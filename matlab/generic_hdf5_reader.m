function h5out =h5readall(h5_file, dataset, fill_with_nan)
% generic hdf5 reader [currenlty handles up to 4 group levels

%% Syntax 
% 
%  h5out = h5read(h5_file)
%  h5out = h5read(h5_file, [], false)
%  h5out = h5read(h5_file, dataset)
%  h5out = h5read(h5_file, dataset, false)
%
%% User Input
%
%       h5_file = full path to hdf5 file
%       dataset = full dataset path within hdf5 structure (optional)
%              can be specified as either a string or cell array of stings
%              e.g. '/orbit_info/rgt' or
%               {'/orbit_info/rgt', /ancillary_data/control'};
%
%       fill_with_nan = true or false, if true single and double datasets
%       with a _FillValue will have _FillValue filled with NaNs
%
%% Author Info
% This function was written by Alex S. Gardner, JPL-Caltech, Oct 2018. 

%% Set defaults and initialize
if exist('fill_with_nan', 'var') ~= 1
    % default behaviour is to fill with nans
    fill_with_nan = true;
end

h5out = struct;

%% Extract requested data
% if only a specific dataset is requested
if exist('dataset', 'var') == 1 && ~isempty(dataset)
    if iscell(dataset)
        for i = 1:length(dataset)
            I = h5info(h5_file, dataset{i});
            
            field_tree = strsplit(dataset{i},'/');
            field_tree(cellfun(@isempty, field_tree)) = [];
            
            struct_out = h5read_parse(h5_file, I, dataset{i}, fill_with_nan);
            h5out = setfield(h5out,field_tree{:}, struct_out);
        end
    else
        I = h5info(h5_file, dataset);
        
        field_tree = strsplit(dataset,'/');
        field_tree(cellfun(@isempty, field_tree)) = [];
        
        struct_out = h5read_parse(h5_file, I, dataset, fill_with_nan);
        h5out = setfield(h5out,field_tree{:}, struct_out);
    end
else
    % return full dataset
    I = h5info(h5_file);
    
    for i = 1:length(I.Groups)
        [~,group1A] = fileparts(I.Groups(i).Name);
        group1B = group1A;
        group1B(group1A == '-') = '_'; % matlab structures names can not include '-'
        
        for j = 1:length(I.Groups(i).Groups)
            [~,group2A] = fileparts(I.Groups(i).Groups(j).Name);
            group2B = group2A;
            group2B(group2B == '-') = '_';
            
            for k = 1:length(I.Groups(i).Groups(j).Groups)
                [~,group3A] = fileparts(I.Groups(i).Groups(j).Groups(k).Name);
                group3B = group3A;
                group3B(group3B == '-') = '_';
                
                for p = 1:length(I.Groups(i).Groups(j).Groups(k).Groups)
                    [~,group4A] = fileparts(I.Groups(i).Groups(j).Groups(k).Groups(p).Name);
                    group4B = group4A;
                    group4B(group4B == '-') = '_';
                    
                    if ~isempty(I.Groups(i).Groups(j).Groups(k).Groups(p).Groups)
                        error('5th group level should needs to added')
                    else
                        if ~isempty(I.Groups(i).Groups(j).Groups(k).Groups(p).Datasets)
                            % extract datasets - level 4
                            for d = 1:length(I.Groups(i).Groups(j).Groups(k).Groups(p).Datasets)
                                datasetA = I.Groups(i).Groups(j).Groups(k).Groups(p).Datasets(d).Name;
                                datasetB = datasetA;
                                datasetB(datasetB == '-') = '_';
                                            
                                struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j).Groups(k).Groups(p).Datasets(d), ['/' group1A '/' group2A '/' group3A '/' group4A '/' datasetA], fill_with_nan);
                                h5out.(group1B).(group2B).(group3B).(group4B).(datasetB).Value = struct_out.Value;
                                h5out.(group1B).(group2B).(group3B).(group4B).(datasetB).Attributes = struct_out.Attributes;
                            end
                        end
                        
                        if ~isempty(I.Groups(i).Groups(j).Groups(k).Groups(p).Attributes)
                            struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j).Groups(k).Groups(p), ['/' group1A '/' group2A '/' group3A '/' group4A], fill_with_nan);
                            h5out.(group1B).(group2B).(group3B).(group4B).Attributes = struct_out.Attributes;
                        end
                    end
                end
                
                if ~isempty(I.Groups(i).Groups(j).Groups(k).Datasets)
                    % extract datasets - level 3
                    for d = 1:length(I.Groups(i).Groups(j).Groups(k).Datasets)
                        datasetA = I.Groups(i).Groups(j).Groups(k).Datasets(d).Name;
                        datasetB = datasetA;
                        datasetB(datasetB == '-') = '_';
                        
                        struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j).Groups(k).Datasets(d), ['/' group1A '/' group2A '/' group3A '/' datasetA], fill_with_nan);
                        h5out.(group1B).(group2B).(group3B).(datasetB).Value = struct_out.Value;
                        h5out.(group1B).(group2B).(group3B).(datasetB).Attributes = struct_out.Attributes;
                    end
                end
                
                if ~isempty(I.Groups(i).Groups(j).Groups(k).Attributes)
                    struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j).Groups(k), ['/' group1A '/' group2A '/' group3A], fill_with_nan);
                    h5out.(group1B).(group2B).(group3B).Attributes = struct_out.Attributes;
                end
            end
            
            if ~isempty(I.Groups(i).Groups(j).Datasets)
                % extract datasets - level 2
                for d = 1:length(I.Groups(i).Groups(j).Datasets)
                    datasetA = I.Groups(i).Groups(j).Datasets(d).Name;
                    datasetB = datasetA;
                    datasetB(datasetB == '-') = '_';
                    
                    struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j).Datasets(d), ['/' group1A '/' group2A '/' datasetA], fill_with_nan);
                    h5out.(group1B).(group2B).(datasetB).Value = struct_out.Value;
                    h5out.(group1B).(group2B).(datasetB).Attributes = struct_out.Attributes;
                    
                end
            end
            
            if ~isempty(I.Groups(i).Groups(j).Attributes)
                    struct_out = h5read_parse(h5_file, I.Groups(i).Groups(j), ['/' group1A '/' group2A], fill_with_nan);
                    h5out.(group1B).(group2B).Attributes = struct_out.Attributes;
            end
        end
        
        if ~isempty(I.Groups(i).Datasets)
            % extract datasets - level 1
            for d = 1:length(I.Groups(i).Datasets)
                datasetA = I.Groups(i).Datasets(d).Name;
                datasetB = datasetA;
                datasetB(datasetB == '-') = '_';
                
                struct_out = h5read_parse(h5_file, I.Groups(i).Datasets(d), ['/' group1A '/'  datasetA], fill_with_nan);
                h5out.(group1B).(datasetB).Value = struct_out.Value;
                h5out.(group1B).(datasetB).Attributes = struct_out.Attributes;
                
            end
        end
        
        if ~isempty(I.Groups(i).Attributes)
            struct_out = h5read_parse(h5_file, I.Groups(i), ['/' group1A], fill_with_nan);
           h5out.(group1B).Attributes = struct_out.Attributes;
        end
    end
    
    % extract datasets - level 0
    if ~isempty(I.Datasets)
        % extract datasets - level 2
        for d = 1:length(I.Datasets)
            datasetA = I.Datasets(d).Name;
            datasetB = datasetA;
            datasetB(datasetB == '-') = '_';
            
            struct_out = h5read_parse(h5_file, I.Datasets(d), ['/'  datasetA], fill_with_nan);
            h5out.(datasetB).Value = struct_out.Value;
            h5out.(datasetB).Attributes = struct_out.Attributes;
        end
    end
    
    if ~isempty(I.Attributes)
        struct_out = h5read_parse(h5_file, I, '/', fill_with_nan);
        h5out.Attributes = struct_out.Attributes;
    end
end
end

%% struct_out funciton extracts data at bottom of data tree
function struct_out = h5read_parse(h5_file, I, field_name, fill_with_nan)
struct_out = struct;
if isfield(I,'Group') || isfield(I,'Groups')
    if ~isempty(I.Attributes)
        
        % extract attributes - level 4
        for a = 1:length(I.Attributes)
            attrA = I.Attributes(a).Name;
            attrB = attrA;
            attrB(attrB == '-') = '_';
            
            struct_out.Attributes.(attrB) = I.Attributes(a).Value;
        end
    end
else
    struct_out.Value = h5read(h5_file, field_name);
    
    % replace fill value
    fillIdx = strcmp({I.Attributes.Name}, '_FillValue');
    if any(fillIdx)
        FillValue = I.Attributes(fillIdx).Value;
    else
        FillValue = [];
    end
    
    if ~isempty(FillValue) && fill_with_nan && (isa(FillValue, 'single') || isa(FillValue, 'double'))
        struct_out.Value(struct_out.Value == FillValue) = nan;
        I.Attributes(strcmp({I.Attributes.Name}, '_FillValue')).Value = nan;
    end
    
    for a = 1:length(I.Attributes)
        attrA = I.Attributes(a).Name;
        attrB = attrA;
        attrB(attrB == '-') = '_';
        if attrB(1) == '_'
            attrB = attrB(2:end);
        end
        struct_out.Attributes.(attrB) =  I.Attributes(a).Value;
    end
end
end