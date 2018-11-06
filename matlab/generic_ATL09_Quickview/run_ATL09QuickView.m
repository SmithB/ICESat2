function bad_file_names = run_ATL09QuickView
% Function to read the ATL09 .h5 files, save a .mat file of the needed
% ATL09 parameters, and create quick look figures (.png) of the 
% along-track cab profile. By default this will not reprocess files that
% were previously processed unless the overwriteOutput is set to true.
%
% Katie Pitts
% kpitts@arlut.utexas.edu
% 10/31/18
% Applied Research Laboratories
% The University of Texas at Austin

%% Set processing flags

saveOutput = true;      % save ATL09 output
saveFigures = true;     % save ATL09 quick look figures
figVis = 'on';          % show figures when plotting: 'on' or 'off'

overwriteOutput = false;    % set to true to overwrite ALL output files

%% Define input and output directories
% generic paths listed below for distribution
% change paths as needed, always end with slash

if(ispc)
    slash = '\';
    dataserverpath = [slash slash 'dataserver' slash];
else
    slash = '/';
    dataserverpath = [slash 'dataserver' slash];
end

basepath = [dataserverpath 'data' slash 'ICESat2' slash 'Rapid' slash];
inpath = [basepath 'ATL09' slash];
outpath = [basepath 'ATL09_QuickLook' slash];

%% If outpath directory doesn't exist, create it

if ~exist(outpath, 'dir')
    mkdir(outpath)
    fileattrib(outpath, '+w', 'g')
end

%% Read input files and output directories

infiles = dir([inpath '*.h5']);
outfiles = dir(outpath);

outfiles = outfiles(~ismember({outfiles.name},{'.','..'}));

%% Determine if input files have already been processed

inputfiles = {infiles.name};
outputfiles = {outfiles.name};

if isempty(outputfiles) || overwriteOutput
    
    isProcessed = false(length(inputfiles),1);

else
    
    isProcessed = ismember(inputfiles, outputfiles);
    
end

toProcess = inputfiles(~isProcessed);

%% Process input files that haven't already been processed

bad_count = 0;

for ii = 1:length(toProcess)
    
    try
        
    outDir = [outpath toProcess{ii}];
    
    if ~exist(outDir, 'dir')
        mkdir(outDir);
        fileattrib(outpath, '+w', 'g')
    end
    
    outDir = [outDir slash];
    
    ATL09 = readATL09([inpath, toProcess{ii}]);
    
    if saveOutput
        save([outDir toProcess{ii} '_ATL09.mat'], 'ATL09', '-v7.3');
    end
    
    plot_ATL09_cab(ATL09, toProcess{ii}, figVis, saveFigures, outDir)
        
    clear ATL09
    close all
    
    catch err
        
        bad_count = bad_count + 1;
        bad_file_names{bad_count} = toProcess{ii};
        
        disp(['Problem with file ' toProcess{ii}])
        error_msg = ['error_processing_' toProcess{ii}];
        
        fid = fopen([outDir error_msg '.txt'], 'wt');
        fprintf(fid, '%s\n\n', err.message);
        fprintf(fid, '%s', err.getReport('extended', 'hyperlinks','off'));
        fclose(fid);
        
    end
    
end

if bad_count > 0
    disp('Check bad_file_names array')
else
    disp('All files processed!')
end

