function plot_ATL09_cab(ATL09, inName, figVis, saveFigures, outDir)
% Function to plot ATL09 calibrated attenuated backscatter.
% Not as pretty as Steve Palm's plots, but it gets the message across.
%
%%%
% Last updated on 10/31/2018 by:
% Katie Pitts
% kpitts@arlut.utexas.edu
%%%

%%

if ~exist('saveFigures', 'var') || ~saveFigures
    outDir = [];
end


%% Find and loop through the profile groups

fields = fieldnames(ATL09);
profiles_log = find(strncmpi(fields, 'profile', 7));

for pp = 1:numel(profiles_log)
    
    profile = fields{profiles_log(pp)};
    
    %% Remove invalid values, determine day/night sections
    
    cab_nan = ATL09.(profile).cab_prof > 3.402823e+38;
    
    ATL09.(profile).cab_prof(cab_nan) = NaN;
    
    cab_elevs = (-1000 + 30/2):30:20000;
    
    daytime = ATL09.(profile).solar_elevation >= 0;
    
    day_line = NaN(length(daytime),1);
    day_line(daytime) = 1;
    
    night_line = NaN(length(daytime),1);
    night_line(~daytime) = 1;
    
    
    %% Plot CAB
    
    ATL09_cab_plot = figure( 'MenuBar', 'Figure', 'Units', 'Normalized', 'Position', [ 0.1 0.1 0.8 0.8 ], 'Visible', figVis);

    hold on
    
    cmap = colormap(parula);
    p = pcolor(ATL09.(profile).delta_time - min(ATL09.(profile).delta_time), cab_elevs, flipud(ATL09.(profile).cab_prof));
    shading flat
    set(p,'DisplayName', 'CAB')
    cdat = get(p, 'cdata');
    caxis([0 quantile(cdat(:),0.99)]);
    cmap(1,:) = [0,0,0];
    colormap(cmap)
    cb = colorbar;

    %% Create day/night indicator
    
    plot(ATL09.(profile).delta_time - min(ATL09.(profile).delta_time), day_line-1000, '-', ...
        'LineWidth', 4, 'Color', [1 0.8 0.5], 'DisplayName', 'Daytime')
    
    plot(ATL09.(profile).delta_time - min(ATL09.(profile).delta_time), night_line-1000, '-', ...
        'LineWidth', 4, 'Color', [0.7 0.8 0.5], 'DisplayName', 'Nighttime')
    
    %% Plot labels
    
    xlabel('Delta Segment Time (seconds)')
    ylabel('Elevation (meters)')
    title({'Calibrated attenuated backscatter profile',...
        [profile ' - ' inName]}, ...
        'interpreter', 'none')
    axis tight
    legend('-DynamicLegend','Location','Best')
    dragzoom()
    
    %% Save figure(s)
    % Uncomment savefig line if MATLAB figure desired. It will take longer
    % to save and the output file is usually large.
    
    if saveFigures
%         savefig(ATL09_cab_plot, [ outDir inName '_ATL03_photons_' profile '.fig']);
        saveas(ATL09_cab_plot, [ outDir inName '_ATL03_photons_' profile '.png']);
    end
    
end