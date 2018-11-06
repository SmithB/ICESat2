function D3=read_ATL06(filename, pair, fields)
% [Add description]
%
% Initial version from Ben Smith.

if ~exist('pair', 'var')
    pair=[1,2,3];
end

if ~exist('fields','var')
    for k=1:length(pair)
        try
            temp=h5info(filename, sprintf('/gt%dl/land_ice_segments', pair(k)));
            fields={temp.Datasets.Name};
        end
        if exist('fields','var')
            break
        end
    end
    fields{end+1}='/ground_track/x_atc';
    fields{end+1}='/ground_track/y_atc';   
end

%fields=fields(~ismember(fields,'segment_id'));


beams={'l','r'};
for kP=1:length(pair)
    
    for kB=1:2
        ID{kB}=h5read(filename,sprintf('/gt%d%s/land_ice_segments/%s', pair(kP), beams{kB}, 'segment_id')); 
    end
    ID_both=unique(cat(1, ID{:}));
    
    for kB=1:2
        [~, in_ind{kB}, out_ind{kB}]=intersect(ID{kB}, ID_both);
    end
    
    for kF=1:length(fields)
        temp=cell(1,2);
        for kB=1:2
            temp{kB}=h5read(filename,sprintf('/gt%d%s/land_ice_segments/%s', pair(kP), beams{kB}, fields{kF})); 
        end
        D3_name=strrep(fields{kF},'/ground_track/','');
        D3(kP).(D3_name)=NaN(numel(ID_both), 2);
        
        for kB=1:2
            D3(kP).(D3_name)(out_ind{kB}, kB)=temp{kB}(in_ind{kB});
        end
    end
end


fields=fieldnames(D3);
for kP=1:3
    bad=D3(kP).h_li>1e30;
    for kf=1:length(fields);
        if isa(D3(kP).(fields{kf}),'single') ||  isa(D3(kP).(fields{kf}),'double')
            D3(kP).(fields{kf})(bad)=NaN;        
        end
    end
end




