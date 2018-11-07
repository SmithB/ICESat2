function ATL09 = readATL09(h5filename)
% Function to read in select parameters of the ATL09 file. 
%
% Input:
%   h5filename - The full path to the ATL09 file
%
% Output:
%   ATL09      - Structure containing ATL09 variables required for ATL08
%                processing
%
%%%
% Last updated on 10/31/2018 by:
% Katie Pitts
% kpitts@arlut.utexas.edu
%%%

ATL09 = struct;

profile = {'profile_1','profile_2','profile_3'};

vars = {'apparent_surf_reflec','bsnow_con','cab_prof','cloud_flag_asr','cloud_flag_atm','delta_time','latitude','layer_attr','layer_con','longitude','msw_flag','prof_dist_x','segment_id','solar_elevation'};
vars_orbit = {'cycle_number','delta_time','orbit_number','rgt'};
vars_anc =  {'data_end_utc';'data_start_utc';'end_cycle';'end_geoseg';'end_orbit';'end_region';'end_rgt';'granule_end_utc';'granule_start_utc';'start_cycle';'start_geoseg';'start_orbit';'start_region';'start_rgt'};


for pp = 1:length(profile)
    
    for vv = 1:length(vars)
        
        ATL09.(profile{pp}).(vars{vv}) = h5read(h5filename,['/', profile{pp}, '/high_rate/', vars{vv}]);
        
    end
    
    for vv = 1:length(vars_orbit)
        
        ATL09.orbit_info.(vars_orbit{vv}) = h5read(h5filename,['/orbit_info/', vars_orbit{vv}]);
        
    end
    
    for vv = 1:length(vars_anc)
        
        ATL09.ancillary_data.(vars_anc{vv}) = h5read(h5filename,['/ancillary_data/', vars_anc{vv}]);
        
    end
    
end