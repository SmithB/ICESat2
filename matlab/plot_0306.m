% From Ben Smith.
%
ATL03_file='ATL03_20151027T112254_00850305_943_01_sreq_525.h5';
ATL06_file='ATL06_20151027T112254_00850305_943_01_sreq_524.h5';
beam=1;
pair=1;

% read the ATL03 data
D3=read_ATL03(ATL03_file);
% read the altimetry group from the ATL06 file
D6=read_ATL06_alt(ATL06_file);
  
% color colde the ATL03 photons by confidence
cla;hold on;
colors={'b','k','r','g'};
for kConf=1:4;
    these=D3(beam).signal_conf_ph==kConf-1;
    plot(D3(beam).x_RGT(these), D3(beam).h_ph(these),'.','color', colors{kConf});
end

% plot the ATL06 heights
plot(D6(pair).x_atc(:,1), D6(pair).h_li(:,1),'mo');

xlabel('x_{atc}'); 
ylabel('h');
    
