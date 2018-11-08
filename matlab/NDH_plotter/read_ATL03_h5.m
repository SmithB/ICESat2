function [output startind endind]=read_ATL03_h5(h5_file,subset_flag,startind,endind)
% (C) Nick Holschuh - University of Washington - 2018 (Holschuh@uw.edu)
% This function reads in the ATL06 .h5 file produced through the NASA SDC
% system, using the land ice algorithm produced by Ben Smith
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% h5_file - string containing either the local or full paht the ATL06 file
% subset_flag - a flag allowing you to choose from the following:
%     0: Full output, following the .h5 file structure [default]
%     1: data subset by either segment id numbers or fraction of the length
%        of the file
%     2: granule subset by segment id, but only containing a subset of
%        the variables
%     Inf: full length of the granule, but only containing a subset of the
%        variables
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Outputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% output - structure containing the .h5 information
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

keep_vars = {'h_ph','dist_ph_along','segment_id','segment_dist_x','segment_ph_cnt','segment_length','signal_conf_ph'};


if exist('subset_flag') == 0
    subset_flag = 0;
    startcount = 0;
    countnum = 0;
end

if subset_flag == Inf | subset_flag == 2
    name_comp = 1;
else
    name_comp = 0;
end

I=h5info(h5_file,'/');

if exist('startind') == 0 
    startind = 0
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% This section determines how to properly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% subset the photons based on either an
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% assigned segment id or a fraction of
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% distance along the line
for i = 1:length(I.Groups)
    if I.Groups(i).Name(2) == 'g' & (subset_flag == 1 | subset_flag == 2)
        subset_group(i) = 1;
        rn = I.Groups(i).Name;
        %%%%%%%%%%%%%%%%%%%%%%%%% Read in the segment ID numbers and the
        %%%%%%%%%%%%%%%%%%%%%%%%% number of photons in each segment id
        segids = h5read(h5_file,['/',rn,'/geolocation/segment_id']);
        segphotons = h5read(h5_file,['/',rn,'/geolocation/segment_ph_cnt']);
        photon_hs = h5read(h5_file,['/',rn,'/heights/h_ph']);
        photon_length(i) = max(size(photon_hs));
        seg_length(i) = max(size(segids));
        
        %%%%%%%%%%%%%%% Find the desired subset groups
        if startind == 0
            startind = inputdlg(['StartInd - ',num2str(min(segids)),' : ',num2str(max(segids))]);
            endind = inputdlg(['EndInd - ',num2str(min(segids)),' : ',num2str(max(segids))]);
            startind = eval(startind{1});
            endind = eval(endind{1});
        end
        
        %%%%%%%%%%%%% If a segment id is provided, find photons associated
        %%%%%%%%%%%%% with those segment ids
        if mod(startind,1) == 0
            segstart(i) = double(find_nearest(segids,startind));
            segcount(i) = double(find_nearest(segids,endind))-segstart(i)+1;
        else %%% If a fraction of the line is provided
            segstart(i) = max([round(length(segids)*startind) 1]);
            segcount(i) = round(length(segids)*endind)-segstart(i)+1;
            startind = double(segids(segstart(i)));
            endind = double(segids(segstart(i)+segcount(i)-1));
        end
        startcount(i) = sum(segphotons(1:segstart(i)-1))+1;
        countnum(i) = sum(segphotons(segstart(i):(segstart(i)+segcount(i)-1)));  
    else
        seg_length(i) = 0;
        photon_length(i) = 0;
        subset_group(i) = 0;
        startcount(i) = 0;
        countnum(i) = 0;
        segstart(i) = 0;
        segcount(i) = 0;
    end
end



%%%%%%%%%%%%%%% This extracts the attributs of the hd5 file itself, and
%%%%%%%%%%%%%%% saves it to the object GranuleMeta
for i = 1:length(I.Attributes)
    wrt_str = ['output.GranuleMeta.',I.Attributes(i).Name,' = I.Attributes(i).Value;'];
    eval(wrt_str)
end




%%%%%%%%%%%%%%% Here we start looping into the different groups, to save
%%%%%%%%%%%%%%% their attributes and values
for i = 1:length(I.Groups)
    
    %%%%% Get the path into the hd5 file and the name to save into the
    %%%%% matlab structure
    rn = I.Groups(i).Name;
    rn2 = strsplit(rn,'/');
    rn_str = ['rn3 = strcat('];
    for j = 1:length(rn2)
        rn_str = [rn_str,'''',rn2{j},''',''.'','];
    end
    rn_str = [rn_str(1:end-1),');'];
    eval(rn_str);
    
    %%%%% Loop through the attributes and save them into the meta
    %%%%% substructure
    for j = 1:length(I.Groups(i).Attributes)
        wrt_str = ['output',rn3,'Meta.',I.Groups(i).Attributes(j).Name,' = I.Groups(i).Attributes(j).Value;'];
        eval(wrt_str)
    end
    
    
    %%%%%%%%%%%%%%%%% Here we either read all the data or just the
    %%%%%%%%%%%%%%%%% subsetted data:
    
    %%%%% Loop through the datasets for this group
    for j = 1:length(I.Groups(i).Datasets)
        vardims = I.Groups(i).Datasets(j).Dataspace.Size;
        varname = I.Groups(i).Datasets(j).Name;
        if name_comp == 0 | strcmp_ndh(keep_vars,varname) == 1
        if length(vardims) == 1
            vardims = [1 vardims];
            h5rank = 1;
        else
            h5rank = 2;
        end
        if subset_group(i) == 1
            %%%%%%%%%%% The subset case for both photon counts and segment
            %%%%%%%%%%% counting variables
            if max(vardims) == photon_length(i)
                h5start = [1 startcount(i)];
                h5count = [vardims(1) countnum(i)];
            elseif max(vardims) == seg_length(i)
                h5start = [1 segstart(i)];
                h5count = [vardims(1) segcount(i)];
            else
                h5start = [1 1];
                h5count = [vardims(1) vardims(2)];
            end
        else
            h5start = [1 1];
            h5count = [vardims(1) vardims(2)];
        end
        if h5rank == 1
            h5start = h5start(2);
            h5count = h5count(2);
        end
        
        if max(h5count) > 0
            wrt_str = ['output',rn3,varname,' = h5read(h5_file,[''',rn,''',''/'',''',varname,'''],h5start,h5count);'];
            eval(wrt_str)
        end
        end
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% Loop into the subgroups
    for j = 1:length(I.Groups(i).Groups)
        %%%%% Get the new naming structure
        rn = I.Groups(i).Groups(j).Name;
        rn2 = strsplit(rn,'/');
        rn_str = ['rn3 = strcat('];
        for k = 1:length(rn2)
            rn_str = [rn_str,'''',rn2{k},''',''.'','];
        end
        rn_str = [rn_str(1:end-1),');'];
        eval(rn_str);
        
        %%%%% Loop through the attributes and save them into the meta
        %%%%% substructure
        for k = 1:length(I.Groups(i).Groups(j).Attributes)
            wrt_str = ['output',rn3,'Meta.',I.Groups(i).Groups(j).Attributes(k).Name,' = I.Groups(i).Groups(j).Attributes(k).Value;'];
            eval(wrt_str)
        end
        
        %%%%% Loop through the datasets for this group
        for k = 1:length(I.Groups(i).Groups(j).Datasets)
            vardims = I.Groups(i).Groups(j).Datasets(k).Dataspace.Size;
            varname = I.Groups(i).Groups(j).Datasets(k).Name;
            if name_comp == 0 | strcmp_ndh(keep_vars,varname) == 1
            if length(vardims) == 1
                vardims = [1 vardims];
                h5rank = 1;
            else
                h5rank = 2;
            end
            if subset_group(i) == 1
                %%%%%%%%%%% The subset case for both photon counts and segment
                %%%%%%%%%%% counting variables
                if max(vardims) == photon_length(i)
                    h5start = [1 startcount(i)];
                    h5count = [vardims(1) countnum(i)];
                elseif max(vardims) == seg_length(i)
                    h5start = [1 segstart(i)];
                    h5count = [vardims(1) segcount(i)];
                else
                    h5start = [1 1];
                    h5count = [vardims(1) vardims(2)];
                end
            else
                h5start = [1 1];
                h5count = [vardims(1) vardims(2)];
            end
            if h5rank == 1
                h5start = h5start(2);
                h5count = h5count(2);
            end
            
            if max(h5count) > 0
                wrt_str = ['output',rn3,varname,' = h5read(h5_file,[''',rn,''',''/'',''',varname,'''],h5start,h5count);'];
                eval(wrt_str)
            end
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% Loop into the subgroups one more time
        for k = 1:length(I.Groups(i).Groups(j).Groups)
            %%%% Get the new naming structure
            rn = I.Groups(i).Groups(j).Groups(k).Name;
            rn2 = strsplit(rn,'/');
            rn_str = ['rn3 = strcat('];
            for l = 1:length(rn2)
                rn_str = [rn_str,'''',rn2{l},''',''.'','];
            end
            rn_str = [rn_str(1:end-1),');'];
            eval(rn_str);
            
            %%%% Loop through the attributes and save them into the meta
            %%%% substructure
            for l = 1:length(I.Groups(i).Groups(j).Groups(k).Attributes)
                if max(rn3 == '-') == 1
                    rn3(find(rn3 == '-')) = [];
                end
                wrt_str = ['output',rn3,'Meta.',I.Groups(i).Groups(j).Groups(k).Attributes(l).Name,' = I.Groups(i).Groups(j).Groups(k).Attributes(l).Value;'];
                eval(wrt_str)
            end
            
            
            %%%%% Loop through the datasets for this group
            for kk = 1:length(I.Groups(i).Groups(j).Groups(k).Datasets)
                vardims = I.Groups(i).Groups(j).Groups(k).Datasets(kk).Dataspace.Size;
                varname = I.Groups(i).Groups(j).Groups(k).Datasets(kk).Name;
                if name_comp == 0 | strcmp_ndh(keep_vars,varname) == 1
                if length(vardims) == 1
                    vardims = [1 vardims];
                    h5rank = 1;
                else
                    h5rank = 2;
                end
                if subset_group(i) == 1
                    %%%%%%%%%%% The subset case for both photon counts and segment
                    %%%%%%%%%%% counting variables
                    if max(vardims) == photon_length(i)
                        h5start = [1 startcount(i)];
                        h5count = [vardims(1) countnum(i)];
                    elseif max(vardims) == seg_length(i)
                        h5start = [1 segstart(i)];
                        h5count = [vardims(1) segcount(i)];
                    else
                        h5start = [1 1];
                        h5count = [vardims(1) vardims(2)];
                    end
                else
                    h5start = [1 1];
                    h5count = [vardims(1) vardims(2)];
                end
                if h5rank == 1
                    h5start = h5start(2);
                    h5count = h5count(2);
                end
                
                if max(h5count) > 0
                    wrt_str = ['output',rn3,varname,' = h5read(h5_file,[''',rn,''',''/'',''',varname,'''],h5start,h5count);'];
                    eval(wrt_str)
                end
                end
            end
            
        end
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%% This pares down the data structure to just the
    
    
    
end

