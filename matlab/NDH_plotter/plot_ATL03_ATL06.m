function plot_ATL03_ATL06(atl03s,atl06s,bp,l_or_r,subsetflag,subset1,subset2)
% (C) Nick Holschuh - U. of Washington - 2018 (Nick.Holschuh@gmail.com)
% This file reads the atl03 and atl06 h5 files, and plots them on top of
% one another for comparison. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The inputs are as follows:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% atl03s - Filename (or cell list of filenames) for the ATL03 photons
% atl06s - Filename (or cell list of filenames) for the ATL06 surface
% bp - [1] The beam pair to plot from (1-3)
% l_or_r - [1] left, (2) right, or (3) both beams plotted 
% subset_flag - a flag allowing you to choose from the following:
%     0: Full output, following the .h5 file structure [default]
%     1: data subset by either segment id numbers or fraction of the length
%        of the file
%     2: granule subset by segment id, but only containing a subset of
%        the variables
%     Inf: full length of the granule, but only containing a subset of the
%        variables
% subset1 - either the segment id or the fraction of the granule you want
%     to start with
% subset2 - either the segment id or the fraction of the granule you want
%     to end with
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

if iscell(atl03s) == 0
    atl03s = {atl03s};
end

if iscell(atl06s) == 0
    atl06s = {atl06s};
end

if exist('bp') == 0
   bp = 1;
end

if exist('l_or_r') == 0
    l_or_r = 1;
end

if exist('subsetflag') == 0
    subsetflag = 0;
    subset1 = 0;
    subset2 = 0;
end


if exist('additional_groundfinder') == 0
    additional_groundfinder = [];
else
    if iscell(additional_groundfinder) == 0
        additional_groundfinder = {additional_groundfinder};
    else
       additional_groundfinder = []; 
    end
end

truthfile = 0;
if exist('truthfile') == 0
    truthfile = [];
    truth_search_flag = 0;
elseif truthfile == 0
    truthfile = [];
    truth_search_flag = 0;
else
    if iscell(truthfile) == 0 & length(truthfile) > 1
        truthfile = {truthfile};
        truth_search_flag = 0;
    elseif truthfile == 1
       truth_search_flag = 1; 
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% ATL03 Assembly %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



photon_h_l = [];
photon_x_l_seg = [];
photon_segid_l = [];
photon_segx_l = [];
photon_segcount_l = [];
photon_seglength_l = [];
photon_x_l = [];
photon_class_l = [];

photon_h_r = [];
photon_x_r_seg = [];
photon_segid_r = [];
photon_segx_r = [];
photon_segcount_r = [];
photon_seglength_r = [];
photon_x_r = [];
photon_class_r = [];

if length(truthfile) > 0
    truthx_l = [];
    truthh_l = [];
    truthx_r = [];
    truthh_r = [];
end


land_ice_conf_flag = 4;
for j = 1:length(atl03s)
    atl03_fname = atl03s{j};
    
    [atl03 subset1 subset2] = read_ATL03_h5(atl03_fname,subsetflag,subset1,subset2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%% This is the code for real ATL03s with full structure
    if isfield(eval(['atl03.gt',num2str(bp),'l']),'geolocation') == 1
        photon_h_l = [photon_h_l; eval(['atl03.gt',num2str(bp),'l.heights.h_ph'])];
        photon_x_l_seg = [photon_x_l_seg; eval(['atl03.gt',num2str(bp),'l.heights.dist_ph_along'])];
        photon_segid_l = [photon_segid_l; eval(['atl03.gt',num2str(bp),'l.geolocation.segment_id'])];
        photon_segx_l = [photon_segx_l; eval(['atl03.gt',num2str(bp),'l.geolocation.segment_dist_x'])];
        photon_segcount_l = [photon_segcount_l; eval(['atl03.gt',num2str(bp),'l.geolocation.segment_ph_cnt'])];
        photon_seglength_l = [photon_seglength_l; eval(['atl03.gt',num2str(bp),'l.geolocation.segment_length'])];
        
        %%%%%%%%%%%% Produce the x_RTC for individual photons from segment
        %%%%%%%%%%%% position and photon position within segment
        running_count_1 = 1;
        for i = 1:length(photon_segcount_l)
            running_count_2 = running_count_1 + photon_segcount_l(i) - 1;
            photon_x_l = [photon_x_l; ones(photon_segcount_l(i),1)*photon_segx_l(i)+photon_x_l_seg(running_count_1:running_count_2)];
            running_count_1 = running_count_2 + 1;
        end
        photon_class_l = [photon_class_l; eval(['atl03.gt',num2str(bp),'l.heights.signal_conf_ph(:,:)'])];
        %row_ind = find(max(max(photon_class_l')) == max(photon_class_l'));
        row_ind = land_ice_conf_flag;
        photon_class_l = photon_class_l(row_ind(1),:);
        
        
        photon_h_r = [photon_h_r; eval(['atl03.gt',num2str(bp),'r.heights.h_ph'])];
        photon_x_r_seg = [photon_x_r_seg; eval(['atl03.gt',num2str(bp),'r.heights.dist_ph_along'])];
        photon_segid_r = [photon_segid_r; eval(['atl03.gt',num2str(bp),'r.geolocation.segment_id'])];
        photon_segx_r = [photon_segx_r; eval(['atl03.gt',num2str(bp),'r.geolocation.segment_dist_x'])];
        photon_segcount_r = [photon_segcount_r; eval(['atl03.gt',num2str(bp),'r.geolocation.segment_ph_cnt'])];
        photon_seglength_r = [photon_seglength_r; eval(['atl03.gt',num2str(bp),'r.geolocation.segment_length'])];
        
        running_count_1 = 1;
        for i = 1:length(photon_segcount_l)
            running_count_2 = running_count_1 + photon_segcount_r(i) - 1;
            photon_x_r = [photon_x_r; ones(photon_segcount_r(i),1)*photon_segx_r(i)+photon_x_r_seg(running_count_1:running_count_2)];
            running_count_1 = running_count_2 + 1;
        end
        photon_class_r = [photon_class_r; eval(['atl03.gt',num2str(bp),'r.heights.signal_conf_ph(:,:)'])];
        %row_ind = find(max(max(photon_class_r')) == max(photon_class_r'));
        row_ind = land_ice_conf_flag;
        photon_class_r = photon_class_r(row_ind(1),:);
    else
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%% This is the code Ben's ATL03s with modified structure        

        
        if length(additional_groundfinder) > 0
            additional_groundfinder_name = additional_groundfinder{j};
            atl03_gf = read_h5(additional_groundfinder_name);
            
            photon_h_l = [photon_h_l; eval(['atl03_gf.channelgt',num2str(bp),'l.photon.h_ph'])];
            photon_x_l = [photon_x_l; eval(['atl03.gt',num2str(bp),'l.x_RGT(1:length(atl03_gf.channelgt',num2str(bp),'l.photon.h_ph))'])];
            
            photon_h_r = [photon_h_r; eval(['atl03_gf.channelgt',num2str(bp),'r.photon.h_ph'])];
            photon_x_r = [photon_x_r; eval(['atl03.gt',num2str(bp),'r.x_RGT(1:length(atl03_gf.channelgt',num2str(bp),'r.photon.h_ph))'])];
            
            photon_class_l = [photon_class_l; eval(['atl03_gf.channelgt',num2str(bp),'l.photon.ph_class'])];
            photon_class_r = [photon_class_r; eval(['atl03_gf.channelgt',num2str(bp),'r.photon.ph_class'])];
        else
            photon_x_l = [photon_x_l; eval(['atl03.gt',num2str(bp),'l.x_RGT'])];
            photon_h_l = [photon_h_l; eval(['atl03.gt',num2str(bp),'l.h'])];
            
            photon_x_r = [photon_x_r; eval(['atl03.gt',num2str(bp),'r.x_RGT'])];
            photon_h_r = [photon_h_r; eval(['atl03.gt',num2str(bp),'r.h'])];
            
            photon_class_l = [photon_class_l; eval(['atl03.gt',num2str(bp),'l.ph_class'])];
            photon_class_r = [photon_class_r; eval(['atl03.gt',num2str(bp),'r.ph_class'])];
        end
    end
 
end

ri = find(isnan(photon_h_l) == 1 | photon_h_l > 1e5);
ri2 = find(isnan(photon_h_r) == 1 | photon_h_r > 1e5);
photon_x_l(ri) = [];
photon_h_l(ri) = [];
photon_class_l(ri) = [];
photon_x_r(ri2) = [];
photon_h_r(ri2) = [];
photon_class_r(ri2) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% ATL06 Assembly %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% This code is designed to be able to accept multiple atl03
%%%%%%%%%%%%%%%%% and atl06 files, and concatenate them
segs = [];
lat_l = [];
lon_l = [];
lat_r = [];
lon_r = [];
dhfdx_l = [];
x_l = [];
q_l = [];
h_l = [];
x_r = [];
q_r = [];
h_r = [];
dhfdx_r = [];


for j = 1:length(atl06s)
    atl06_fname = atl06s{j};
    
    if atl06s{j}(end-2:end) == 'mat'
        load(atl06s{j});
        
        segs = [segs; D3(bp).seg_count(:,1)];
        x_l = [x_l; D3(bp).x_RGT(:,1)];
        q_l = [q_l; D3(bp).ATL06_quality_summary(:,1)];
        h_l = [h_l; D3(bp).h_LI(:,1)];
        lat_l = [lat_l; D3(bp).lat_ctr(:,1)];
        lon_l = [lon_l; D3(bp).lon_ctr(:,1)];
        dhfdx_l = [dhfdx_l; D3(bp).dh_fit_dx(:,1)];
        %%%%%%%%%% Load in the right beam
        x_r = [x_r; D3(bp).x_RGT(:,2)];
        q_r = [q_r; D3(bp).ATL06_quality_summary(:,2)];
        h_r = [h_r; D3(bp).h_LI(:,2)];
        lat_r = [lat_r; D3(bp).lat_ctr(:,2)];
        lon_r = [lon_r; D3(bp).lon_ctr(:,2)];
        dhfdx_r = [dhfdx_r; D3(bp).dh_fit_dx(:,2)];
        
    else
        
        atl06 = read_ATL06_h5(atl06_fname,subsetflag,subset1,subset2);
        
        segs = [segs; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.segment_id'])];
        x_l = [x_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.ground_track.x_atc'])];
        q_l = [q_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.atl06_quality_summary'])];
        h_l = [h_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.h_li'])];
        lat_l = [lat_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.latitude'])];
        lon_l = [lon_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.longitude'])];
        dhfdx_l = [dhfdx_l; eval(['atl06.gt',num2str(bp),'l.land_ice_segments.fit_statistics.dh_fit_dx'])];
        %%%%%%%%%% Load in the right beam
        x_r = [x_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.ground_track.x_atc'])];
        q_r = [q_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.atl06_quality_summary'])];
        h_r = [h_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.h_li'])];
        lat_r = [lat_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.latitude'])];
        lon_r = [lon_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.longitude'])];
        dhfdx_r = [dhfdx_r; eval(['atl06.gt',num2str(bp),'r.land_ice_segments.fit_statistics.dh_fit_dx'])];
    end
       
end

ind1 = find(h_l < 1e5);
ind2 = find(h_r < 1e5);
q_l = q_l(ind1);
x_l = x_l(ind1);
h_l = h_l(ind1);
q_r = q_r(ind2);
x_r = x_r(ind2);
h_r = h_r(ind2);
dhfdx_l = dhfdx_l(ind1);
dhfdx_r = dhfdx_r(ind2);
    

%h_l(find(q_l == 1)) = NaN;
%h_r(find(q_r == 1)) = NaN;




%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Here, the full plot is created, and
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% subsequently panned across. There are two
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% complete sections here, one for the strong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% beam and one for the weak beam.


c = {'lightgray','darkgray','lightblue','slateblue','blue'};
animation_flag = 0;

if l_or_r == 1 | l_or_r == 3
    
    
    if l_or_r == 3
        aa = subplot(2,1,1);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Mainly for testing, allows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% a DC shift of the x
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% positions
%     left_shift = min(photon_x_l);
%     %left_shift = 0;
%     photon_x_l = photon_x_l-left_shift;
%     x_l = x_l - left_shift;
    
    hold off
    for i = 1:4
        if i == 1
            inds = [find(photon_class_l <= i)];
        else
           inds = [find(photon_class_l == i)]; 
        end
        if length(inds) > 0
            plot(photon_x_l(inds),photon_h_l(inds),'.','Color',color_call(c{i}),'MarkerSize',(i+2)*1.5)
        end
        hold all
    end
    
    if length(truthfile) > 0
        plot(truthx_l,truthh_l,'o','Color','black','MarkerFaceColor','white','MarkerSize',4)
    end
    
    %plot_segs(x_l,h_l,dhfdx_l,40,['''Color'',color_call(''darkblue''),''LineWidth'',2']);
    plot_segs(x_l,h_l,dhfdx_l,40,['''Color'',color_call(''gold''),''LineWidth'',2']);
    
    legend_inp = {};
    for i = 1:4
        if i == 1
            legend_inp{i} = ['Photon Type - ',num2str(i-1),'/',num2str(i)];
        else
            legend_inp{i} = ['Photon Type - ',num2str(i)];
        end
    end
    
    if length(truthfile) > 0
        legend_inp(end+1:end+2) = {'Ground Truth','ATL06'};
    else
        legend_inp(end+1) = {'ATL06'};
    end
    
    
    legend(legend_inp)
    xlabel('Distance Along Track (m)')
    ylabel('Left Beam - Elevation')
    set(gcf,'Color','white')
    maximize
    
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%% Panning Animation
%     %%%%%%%%%% (Right now this is not set up to be portable)
%     
%     if animation_flag == 1
%         %%%%%%%%%%%%%%%%%%%%% This defines the path for the camera to take
%         xwind = 1000;
%         ywind = 50;
%         inds = find(photon_class_l == 2);
%         subinds = find(diff(photon_x_l(inds)) ~= 0);
%         inds = inds(subinds+1);
%         
%         if length(inds) == 0
%             inds = find(photon_class_l == 0);
%             subinds = find(diff(photon_x_l(inds)) ~= 0);
%             inds = inds(subinds+1);
%         end
%         
%         xp = linspace(min(photon_x_l)+xwind,max(photon_x_l)-xwind,5000);
%         path = smooth_ndh(photon_h_l(inds),2000);
%         path = interp1(photon_x_l(inds),path,xp,'linear','extrap');
%     end

end

if l_or_r == 2 | l_or_r == 3
    
    if l_or_r == 3
        bb = subplot(2,1,2);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Mainly for testing, allows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% a DC shift of the x
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% positions
%     if exist('left_shift') == 0
%         left_shift = min(photon_x_r);
%         left_shift = 0;
%     end
%     photon_x_r = photon_x_r-left_shift;
%     x_r = x_r - left_shift;
    
    hold off
    for i = 1:4
        if i == 1
            inds = [find(photon_class_l <= i)];
        else
           inds = [find(photon_class_l == i)]; 
        end
        if length(inds) > 0
            plot(photon_x_r(inds),photon_h_r(inds),'.','Color',color_call(c{i}),'MarkerSize',(i+2)*1.5)
        end
        hold all
    end

    if length(truthfile) > 0
        plot(truthx_r,truthh_r,'o','Color','black','MarkerFaceColor','white','MarkerSize',4)
    end
    
    %plot_segs(x_r,h_r,dhfdx_r,40,['''Color'',color_call(''darkblue''),''LineWidth'',2']);
    plot_segs(x_r,h_r,dhfdx_r,40,['''Color'',color_call(''gold''),''LineWidth'',2']);
    
    legend_inp = {};
    for i = 1:4
        if i == 1
            legend_inp{i} = ['Photon Type - ',num2str(i-1),'/',num2str(i)];
        else
            legend_inp{i} = ['Photon Type - ',num2str(i)];
        end
    end
    
    if length(truthfile) > 0
        legend_inp(end+1:end+2) = {'Ground Truth','ATL06'};
    else
        legend_inp(end+1) = {'ATL06'};
    end
    legend(legend_inp)
    xlabel('Distance Along Track (m)')
    ylabel('Right Beam - Elevation')
    

    set(gcf,'Color','white')
    
   
%%
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %%%%%%%%%% Panning Animation
%     %%%%%%%%%% (Right now this is not set up to be portable)
%     if animation_flag == 1
%         xwind = 1000;
%         ywind = 50;
%         inds = find(photon_class_r == 2);
%         subinds = find(diff(photon_x_r(inds)) ~= 0);
%         inds = inds(subinds+1);
%         
%         if length(inds) == 0
%             inds = find(photon_class_r == 0);
%             subinds = find(diff(photon_x_r(inds)) ~= 0);
%             inds = inds(subinds+1);
%         end
%         
%         
%         xp = linspace(min(photon_x_r)+xwind,max(photon_x_r)-xwind,5000);
%         path = smooth_ndh(photon_h_r(inds),2000);
%         path = interp1(photon_x_r(inds),path,xp,'linear','extrap');
%     end
    
   
end

if l_or_r == 3
    linkaxes([aa bb],'xy');
    subplot(2,1,1)
end

title(true_name(atl03_fname));


figure()
if min(lat_r) < 0
    [xtemp ytemp] = polarstereo_fwd(lat_r,lon_r);
    groundingline(1);
    plot(xtemp,ytemp,'Color','blue')
    axis equal
else
    [xtemp ytemp] = polarstereo_fwd(lat_r,lon_r);
    groundingline(6);
    groundingline(7);
    plot(xtemp,ytemp,'Color','blue')
    axis equal
end

title(true_name(atl03_fname));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Code for Animation
%     loop_steps = 1:length(xp);
%     for i = loop_steps
%         
%         xlim([xp(i)-xwind xp(i)+xwind])
%         ylim([path(i)-ywind path(i)+ywind]);
%         generate_frames(['SignalFinder_t',num2str(repeatnum),'_',btype,'_Section',num2str(jj)],['SignalFinder_t',num2str(repeatnum),'_',btype,'_Section',num2str(jj)],i-loop_steps(1)+1)
%     end
% 

end




function output = color_call(color_str);
if length(color_str) == 3; if color_str== 'red'; output = [255, 0, 0]; end; end;
if length(color_str) == 3; if color_str== 'tan'; output = [210, 180, 140]; end; end;
if length(color_str) == 4; if color_str== 'aqua'; output = [0, 255, 255]; end; end;
if length(color_str) == 4; if color_str== 'blue'; output = [0, 0, 255]; end; end;
if length(color_str) == 4; if color_str== 'cyan'; output = [0, 255, 255]; end; end;
if length(color_str) == 4; if color_str== 'gold'; output = [255, 215, 0]; end; end;
if length(color_str) == 4; if color_str== 'gray'; output = [128, 128, 128]; end; end;
if length(color_str) == 4; if color_str== 'lime'; output = [0, 255, 0]; end; end;
if length(color_str) == 4; if color_str== 'navy'; output = [0, 0, 128]; end; end;
if length(color_str) == 4; if color_str== 'peru'; output = [205, 133, 63]; end; end;
if length(color_str) == 4; if color_str== 'pink'; output = [255, 192, 203]; end; end;
if length(color_str) == 4; if color_str== 'plum'; output = [221, 160, 221]; end; end;
if length(color_str) == 4; if color_str== 'snow'; output = [255, 250, 250]; end; end;
if length(color_str) == 4; if color_str== 'teal'; output = [0, 128, 128]; end; end;
if length(color_str) == 5; if color_str== 'azure'; output = [240, 255, 255]; end; end;
if length(color_str) == 5; if color_str== 'beige'; output = [245, 245, 220]; end; end;
if length(color_str) == 5; if color_str== 'black'; output = [0, 0, 0]; end; end;
if length(color_str) == 5; if color_str== 'brown'; output = [165, 42, 42]; end; end;
if length(color_str) == 5; if color_str== 'coral'; output = [255, 127, 80]; end; end;
if length(color_str) == 5; if color_str== 'green'; output = [0, 128, 0]; end; end;
if length(color_str) == 5; if color_str== 'ivory'; output = [255, 255, 240]; end; end;
if length(color_str) == 5; if color_str== 'khaki'; output = [240, 230, 140]; end; end;
if length(color_str) == 5; if color_str== 'linen'; output = [250, 240, 230]; end; end;
if length(color_str) == 5; if color_str== 'olive'; output = [128, 128, 0]; end; end;
if length(color_str) == 5; if color_str== 'wheat'; output = [245, 222, 179]; end; end;
if length(color_str) == 5; if color_str== 'white'; output = [255, 255, 255]; end; end;
if length(color_str) == 6; if color_str== 'bisque'; output = [255, 228, 196]; end; end;
if length(color_str) == 6; if color_str== 'indigo'; output = [75, 0, 130]; end; end;
if length(color_str) == 6; if color_str== 'maroon'; output = [128, 0, 0]; end; end;
if length(color_str) == 6; if color_str== 'orange'; output = [255, 165, 0]; end; end;
if length(color_str) == 6; if color_str== 'orchid'; output = [218, 112, 214]; end; end;
if length(color_str) == 6; if color_str== 'purple'; output = [128, 0, 128]; end; end;
if length(color_str) == 6; if color_str== 'salmon'; output = [250, 128, 114]; end; end;
if length(color_str) == 6; if color_str== 'sienna'; output = [160, 82, 45]; end; end;
if length(color_str) == 6; if color_str== 'silver'; output = [192, 192, 192]; end; end;
if length(color_str) == 6; if color_str== 'tomato'; output = [255, 99, 71]; end; end;
if length(color_str) == 6; if color_str== 'violet'; output = [238, 130, 238]; end; end;
if length(color_str) == 6; if color_str== 'yellow'; output = [255, 255, 0]; end; end;
if length(color_str) == 7; if color_str== 'crimson'; output = [220, 20, 60]; end; end;
if length(color_str) == 7; if color_str== 'darkred'; output = [139, 0, 0]; end; end;
if length(color_str) == 7; if color_str== 'dimgray'; output = [105, 105, 105]; end; end;
if length(color_str) == 7; if color_str== 'fuchsia'; output = [255, 0, 255]; end; end;
if length(color_str) == 7; if color_str== 'hotpink'; output = [255, 105, 180]; end; end;
if length(color_str) == 7; if color_str== 'magenta'; output = [255, 0, 255]; end; end;
if length(color_str) == 7; if color_str== 'oldlace'; output = [253, 245, 230]; end; end;
if length(color_str) == 7; if color_str== 'skyblue'; output = [135, 206, 235]; end; end;
if length(color_str) == 7; if color_str== 'thistle'; output = [216, 191, 216]; end; end;
if length(color_str) == 8; if color_str== 'cornsilk'; output = [255, 248, 220]; end; end;
if length(color_str) == 8; if color_str== 'darkblue'; output = [0, 0, 139]; end; end;
if length(color_str) == 8; if color_str== 'darkcyan'; output = [0, 139, 139]; end; end;
if length(color_str) == 8; if color_str== 'darkgray'; output = [169, 169, 169]; end; end;
if length(color_str) == 8; if color_str== 'deeppink'; output = [255, 20, 147]; end; end;
if length(color_str) == 8; if color_str== 'honeydew'; output = [240, 255, 240]; end; end;
if length(color_str) == 8; if color_str== 'lavender'; output = [230, 230, 250]; end; end;
if length(color_str) == 8; if color_str== 'moccasin'; output = [255, 228, 181]; end; end;
if length(color_str) == 8; if color_str== 'seagreen'; output = [46, 139, 87]; end; end;
if length(color_str) == 8; if color_str== 'seashell'; output = [255, 245, 238]; end; end;
if length(color_str) == 9; if color_str== 'aliceblue'; output = [240, 248, 255]; end; end;
if length(color_str) == 9; if color_str== 'burlywood'; output = [222, 184, 135]; end; end;
if length(color_str) == 9; if color_str== 'cadetblue'; output = [95, 158, 160]; end; end;
if length(color_str) == 9; if color_str== 'chocolate'; output = [210, 105, 30]; end; end;
if length(color_str) == 9; if color_str== 'darkgreen'; output = [0, 100, 0]; end; end;
if length(color_str) == 9; if color_str== 'darkkhaki'; output = [189, 183, 107]; end; end;
if length(color_str) == 9; if color_str== 'firebrick'; output = [178, 34, 34]; end; end;
if length(color_str) == 9; if color_str== 'gainsboro'; output = [220, 220, 220]; end; end;
if length(color_str) == 9; if color_str== 'goldenrod'; output = [218, 165, 32]; end; end;
if length(color_str) == 9; if color_str== 'indianred'; output = [205, 92, 92]; end; end;
if length(color_str) == 9; if color_str== 'lawngreen'; output = [124, 252, 0]; end; end;
if length(color_str) == 9; if color_str== 'lightblue'; output = [173, 216, 230]; end; end;
if length(color_str) == 9; if color_str== 'lightcyan'; output = [224, 255, 255]; end; end;
if length(color_str) == 9; if color_str== 'lightgray'; output = [211, 211, 211]; end; end;
if length(color_str) == 9; if color_str== 'lightpink'; output = [255, 182, 193]; end; end;
if length(color_str) == 9; if color_str== 'limegreen'; output = [50, 205, 50]; end; end;
if length(color_str) == 9; if color_str== 'mintcream'; output = [245, 255, 250]; end; end;
if length(color_str) == 9; if color_str== 'mistyrose'; output = [255, 228, 225]; end; end;
if length(color_str) == 9; if color_str== 'olivedrab'; output = [107, 142, 35]; end; end;
if length(color_str) == 9; if color_str== 'orangered'; output = [255, 69, 0]; end; end;
if length(color_str) == 9; if color_str== 'palegreen'; output = [152, 251, 152]; end; end;
if length(color_str) == 9; if color_str== 'peachpuff'; output = [255, 218, 185]; end; end;
if length(color_str) == 9; if color_str== 'rosybrown'; output = [188, 143, 143]; end; end;
if length(color_str) == 9; if color_str== 'royalblue'; output = [65, 105, 225]; end; end;
if length(color_str) == 9; if color_str== 'slateblue'; output = [106, 90, 205]; end; end;
if length(color_str) == 9; if color_str== 'slategray'; output = [112, 128, 144]; end; end;
if length(color_str) == 9; if color_str== 'steelblue'; output = [70, 130, 180]; end; end;
if length(color_str) == 9; if color_str== 'turquoise'; output = [64, 224, 208]; end; end;
if length(color_str) == 10; if color_str== 'aquamarine'; output = [127, 255, 212]; end; end;
if length(color_str) == 10; if color_str== 'blueviolet'; output = [138, 43, 226]; end; end;
if length(color_str) == 10; if color_str== 'chartreuse'; output = [127, 255, 0]; end; end;
if length(color_str) == 10; if color_str== 'darkorange'; output = [255, 140, 0]; end; end;
if length(color_str) == 10; if color_str== 'darkorchid'; output = [153, 50, 204]; end; end;
if length(color_str) == 10; if color_str== 'darksalmon'; output = [233, 150, 122]; end; end;
if length(color_str) == 10; if color_str== 'darkviolet'; output = [148, 0, 211]; end; end;
if length(color_str) == 10; if color_str== 'dodgerblue'; output = [30, 144, 255]; end; end;
if length(color_str) == 10; if color_str== 'ghostwhite'; output = [248, 248, 255]; end; end;
if length(color_str) == 10; if color_str== 'lightcoral'; output = [240, 128, 128]; end; end;
if length(color_str) == 10; if color_str== 'lightgreen'; output = [144, 238, 144]; end; end;
if length(color_str) == 10; if color_str== 'mediumblue'; output = [0, 0, 205]; end; end;
if length(color_str) == 10; if color_str== 'papayawhip'; output = [255, 239, 213]; end; end;
if length(color_str) == 10; if color_str== 'powderblue'; output = [176, 224, 230]; end; end;
if length(color_str) == 10; if color_str== 'sandybrown'; output = [244, 164, 96]; end; end;
if length(color_str) == 10; if color_str== 'whitesmoke'; output = [245, 245, 245]; end; end;
if length(color_str) == 11; if color_str== 'darkmagenta'; output = [139, 0, 139]; end; end;
if length(color_str) == 11; if color_str== 'deepskyblue'; output = [0, 191, 255]; end; end;
if length(color_str) == 11; if color_str== 'floralwhite'; output = [255, 250, 240]; end; end;
if length(color_str) == 11; if color_str== 'forestgreen'; output = [34, 139, 34]; end; end;
if length(color_str) == 11; if color_str== 'greenyellow'; output = [173, 255, 47]; end; end;
if length(color_str) == 11; if color_str== 'lightsalmon'; output = [255, 160, 122]; end; end;
if length(color_str) == 11; if color_str== 'lightsalmon'; output = [255, 160, 122]; end; end;
if length(color_str) == 11; if color_str== 'lightyellow'; output = [255, 255, 224]; end; end;
if length(color_str) == 11; if color_str== 'navajowhite'; output = [255, 222, 173]; end; end;
if length(color_str) == 11; if color_str== 'saddlebrown'; output = [139, 69, 19]; end; end;
if length(color_str) == 11; if color_str== 'springgreen'; output = [0, 255, 127]; end; end;
if length(color_str) == 11; if color_str== 'yellowgreen'; output = [154, 205, 50]; end; end;
if length(color_str) == 12; if color_str== 'antiquewhite'; output = [250, 235, 215]; end; end;
if length(color_str) == 12; if color_str== 'darkseagreen'; output = [143, 188, 139]; end; end;
if length(color_str) == 12; if color_str== 'lemonchiffon'; output = [255, 250, 205]; end; end;
if length(color_str) == 12; if color_str== 'lightskyblue'; output = [135, 206, 250]; end; end;
if length(color_str) == 12; if color_str== 'mediumorchid'; output = [186, 85, 211]; end; end;
if length(color_str) == 12; if color_str== 'mediumpurple'; output = [147, 112, 219]; end; end;
if length(color_str) == 12; if color_str== 'midnightblue'; output = [25, 25, 112]; end; end;
if length(color_str) == 13; if color_str== 'darkgoldenrod'; output = [184, 134, 11]; end; end;
if length(color_str) == 13; if color_str== 'darkslateblue'; output = [72, 61, 139]; end; end;
if length(color_str) == 13; if color_str== 'darkslategray'; output = [47, 79, 79]; end; end;
if length(color_str) == 13; if color_str== 'darkturquoise'; output = [0, 206, 209]; end; end;
if length(color_str) == 13; if color_str== 'lavenderblush'; output = [255, 240, 245]; end; end;
if length(color_str) == 13; if color_str== 'lightseagreen'; output = [32, 178, 170]; end; end;
if length(color_str) == 13; if color_str== 'palegoldenrod'; output = [238, 232, 170]; end; end;
if length(color_str) == 13; if color_str== 'paleturquoise'; output = [175, 238, 238]; end; end;
if length(color_str) == 13; if color_str== 'palevioletred'; output = [219, 112, 147]; end; end;
if length(color_str) == 13; if color_str== 'rebeccapurple'; output = [102, 51, 153]; end; end;
if length(color_str) == 14; if color_str== 'blanchedalmond'; output = [255, 235, 205]; end; end;
if length(color_str) == 14; if color_str== 'cornflowerblue'; output = [100, 149, 237]; end; end;
if length(color_str) == 14; if color_str== 'darkolivegreen'; output = [85, 107, 47]; end; end;
if length(color_str) == 14; if color_str== 'lightslategray'; output = [119, 136, 153]; end; end;
if length(color_str) == 14; if color_str== 'lightsteelblue'; output = [176, 196, 222]; end; end;
if length(color_str) == 14; if color_str== 'mediumseagreen'; output = [60, 179, 113]; end; end;
if length(color_str) == 15; if color_str== 'mediumslateblue'; output = [123, 104, 238]; end; end;
if length(color_str) == 15; if color_str== 'mediumslateblue'; output = [123, 104, 238]; end; end;
if length(color_str) == 15; if color_str== 'mediumturquoise'; output = [72, 209, 204]; end; end;
if length(color_str) == 15; if color_str== 'mediumvioletred'; output = [199, 21, 133]; end; end;
if length(color_str) == 16; if color_str== 'mediumaquamarine'; output = [102, 205, 170]; end; end;
if length(color_str) == 17; if color_str== 'mediumspringgreen'; output = [0, 250, 154]; end; end;
if length(color_str) == 20; if color_str== 'lightgoldenrodyellow'; output = [250, 250, 210]; end; end;


if exist('output') ~= 1
    output = color_str;
else
    output = output/255;
end

end



function output = true_name(input_string)

replace_inds = find(input_string == '_' | input_string == '^');
add_vec_replace = (1:length(replace_inds))-1;
output = input_string;

for i = 1:length(replace_inds)
    output = [output(1:replace_inds(i)+add_vec_replace(i)-1),'\',output(replace_inds(i)+add_vec_replace(i):end)];
end


end



function h=plot_segs(x, h, slope, W, linespec)


eval_string = ['h=plot([x(:)-W/2 x(:)+W/2]'', [h(:)-slope(:)*W/2 h(:)+slope(:)*W/2]'',', linespec,');'];
eval(eval_string);
end



function outval = strcmp_ndh(stringlist,comparator);

for i = 1:length(stringlist)
    val(i) = strcmp(stringlist{i},comparator);
end

outval = max(val);
end



