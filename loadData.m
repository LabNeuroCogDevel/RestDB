% addpath(genpath('~/2015_01_25 BCT'));
% addpath(genpath('/home/ni_tools/matlab_toolboxes/BrainConnectivityToolbox'))


%parcel = 'GordonHarOx'; 
parcel = 'hpc_pfc_brainstem_rstg';
pipeline = 'aroma_gsr';
study = 'cog';

% parcel = '%';
% pipeline = 'aroma';
% study = 'pnc';

clusterThresh = 0.8; % percentile threshold for binarization
louvainGamma = 1.1;

if ismac
    poolsize = 0;
    showPlots = 1;
else
    poolsize = 32;
    showPlots = 0;
end

%return

%% Load from DB
clear r

if 1
    dbcn = sqlite('rest.db');
    tbl = get_rest(dbcn,sprintf('study like "%s" and preproc like "%s" and atlas like "%s"', study, pipeline, parcel));


    % load
    size(tbl,1)
    for i = 1:size(tbl,1)
        if mod(i,20)==0
            fprintf(1, '%03d ', i);
            if mod(i,200)==0
                fprintf(1, '\n');
            end
        end
        fname = tbl(i,:).adj_file;
        thisr = readtable(fname{1}, 'TreatAsEmpty', 'NA');
        
        if ~exist('r','var')
            nROI = size(thisr, 1);
            r = nan*ones(nROI, nROI, size(tbl,1));
        end
        
        r(:,:,i) = table2array(thisr);
    end
    fprintf(1, 'Done!\n');

    % check for bad entries

    badidx = find(squeeze(sum(sum(isinf(r),1),2))>0);

    tbl(badidx,:) = [];
    r(:,:,badidx) = [];

    save(sprintf('saved_data/query_cog_%s_%s_%s.mat', pipeline, parcel, datestr(now, 'yyyymmdd')), 'tbl', 'r');

else
    load(sprintf('saved_data/query_cog_%s_%s_%s.mat', pipeline, parcel, '20180531'), 'tbl', 'r');
end



