%function data = m01_loadAdj_cogrest
%% Notes
% * used by build_db_mats (from 00_createdb.bash)
% * creates 'allses' and 'allrest' variables
% * set DEBUG=1 for more verbose output

%% atlases
atlases = atlas_list('pet'); % {'GordonHarOx','CogEmoROIs','vmpfcstrvta20181221'}
pipelines = {'mhrestbase','aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = 24;

%% get directory list - petrest_{rac1,rac2,dtbz}
dirs = [ dir(fullfile('/Volumes/Zeus/preproc/petrest_*/brnsuwdktm_rest/1*')); ...
         dir(fullfile('/Volumes/Zeus/preproc/petrest_dtbz/MHRest_FM_ica/1*')) ...
];
fprintf('== running petrest_table for %d folders and %d atlases ==\n',...
    length(dirs), length(atlases));

allses=[];
allrest=[];

% load ages
%agesTable = readtable('/Volumes/Phillips/mMR_PETDA/scripts/txt/subjinfo_agesexids.csv', 'Delimiter', '\t','ReadVariableNames',true);
agesTable = readtable('/Volumes/Phillips/mMR_PETDA/scripts/merged_data.csv', 'Delimiter', ',','ReadVariableNames',true);
agesTable.lunaid = cellfun(@str2double, agesTable.lunaid); % 20191107 -- at somepoint these became strings. need as num for comp below

%%
for diri = 1:length(dirs)
    thisdir = dirs(diri);
    if exist('DEBUG','var') && DEBUG==1
        fprintf('Looking to #%d: %s/%s\n', diri, thisdir.folder,thisdir.name);
    end

    % Load session info into ses
    subjdate = thisdir.name;
    sdparts = strsplit(subjdate, '_');
    if length(sdparts) < 2
        warning('bad folder name %s/%s', thisdir.folder, thisdir.name);
        continue
    end
    subj = sdparts{1};
    vdate = sdparts{2};
    
    
    % get age
    ageIdx = find(agesTable.lunaid==str2double(subj) & strcmp(agesTable.vdate, vdate));
    if ~isempty(ageIdx)
        age = str2double(agesTable(ageIdx,:).age);
        gender = agesTable(ageIdx,:).sex;
    else
        age = NaN;
        gender = {''};
    end
    
    dirparts = strsplit(thisdir.folder, '/');
    basedir = fullfile(filesep, dirparts{2:5});
    
    ses = [];
    ses.ses_id = subjdate;
    ses.subj = subj;
    ses.age = age;
    ses.sex = gender{1};
    ses.dx = 'control';
    
    
    if mod(diri,20) == 0
        fprintf(1, '%s: %d/%d\n',...
            datetime('now','Format','HH:mm:ss.SSS'), diri, length(dirs));
    end
    if exist('DEBUG','var') && DEBUG==1
        disp(ses)
    end
    %f = fieldnames(ses); for fi = 1:length(f); fprintf(1, '%s: %s\n', f{fi}, class(ses.(f{fi}))); end; return
    
    % build struct array that we can later turn into a table
    allses=[allses ses];
    
    % Load all pipelines into rest
    for pipei = 1:length(pipelines)
        for atlasi = 1:length(atlases)
            rest = [];
            rest.ses_id = subjdate;
            rest.study = 'pet';
            rest.preproc = pipelines{pipei};
            rest.atlas = atlases{atlasi};

            switch pipelines{pipei}
                case 'mhrestbase'
                    scandir = fullfile(basedir, 'brnsuwdktm_rest', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    fourdFile = fullfile(scandir, 'brnswudktm_func_5.nii.gz');
                    %/Volumes/Phillips/CogRest/subjs/10124_20060803/preproc/10124_20060803_GordonHarOx_adj.txt
                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subjdate, atlases{atlasi})));
                    if length(adjFiles)>=1
                        adjFile = fullfile(adjFiles(1).folder, adjFiles(1).name);
                    else
                        adjFile = '';
                    end
                    tsFiles = dir(fullfile(scandir, sprintf('%s_%s_ts*.txt', subjdate, atlases{atlasi})));
                    if length(tsFiles)>=1
                        tsFile = fullfile(tsFiles(1).folder, tsFiles(1).name);
                    else
                        tsFile = '';
                    end
                case 'aroma'
                    scandir = fullfile(basedir, 'MHRest_FM_ica', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subjdate, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subjdate, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'brnaswudktm_func_4.nii.gz');

                case 'aroma_gsr'
                    scandir = fullfile(basedir, 'MHRest_FM_ica', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    %/data/Hera/preproc/cog_task/rest_spikemin/11217_20131022/snip/11217_20131022_GordonHarOx_adj_gsr_pearson.txt
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subjdate, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subjdate, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'bgrnaswudktm_func_4.nii.gz');
            end


            if ~exist(adjFile, 'file')
                if exist('DEBUG','var') && DEBUG==1
                    fprintf(1, '\tCannot find adjFile %s for atlas=%s, pipeline=%s\n', adjFile, atlases{atlasi}, pipelines{pipei});
                end
                continue
            end
            
            if exist('DEBUG','var') && DEBUG==1
                fprintf('\tadding %s\n', adjFile)
            end
            
            % get censored volumes
            thisCensorFile = fullfile(scandir, censorFile);
            thisFDFile = fullfile(scandir, fdFile);
            thisDVARSFile = fullfile(scandir, dvarsFile);

            if exist(thisCensorFile, 'file')
                cens = load(thisCensorFile);
                nVols = numel(cens);
                goodVols = sum(cens);
                badVols = nVols - goodVols;
                pctBadVols = badVols/nVols;

                fd = load(thisFDFile);
                dvars = load(thisDVARSFile);

                fd_n_cens = sum(fd>fd_thresh);
                dvars_n_cens = sum(dvars>dvars_thresh);
            else
                fprintf(1, 'No censor file %s\n', thisCensorFile);
                nVols = NaN;
                goodVols = NaN;
                badVols = NaN;
                pctBadVols = NaN;
                fd = NaN;
                dvars = NaN;
                fd_n_cens = NaN;
                dvars_n_cens = NaN;
            end    
            
            rest.ntr = nVols;

            rest.adj_file = adjFile;
            rest.ts_file = tsFile;

            rest.motion_n_cens = badVols;
            rest.motion_pct_cens = pctBadVols;
            rest.motion_path = fullfile(scandir, censorFile);

            rest.fd_mean = mean(fd);
            rest.fd_median = median(fd);
            rest.fd_n_cens = fd_n_cens;
            rest.fd_path = thisFDFile;

            rest.dvars_mean = mean(dvars);
            rest.dvars_median = median(dvars);
            rest.dvars_n_cens = dvars_n_cens;
            rest.dvars_path = thisDVARSFile;
            rest.ts4d = fourdFile;

            %rest
            % build array strcut of all rests to turn into table
            allrest=[allrest rest];
        end % end atlases
    end % end pipelines
    
    %pause
end


% make arrays into tables
allses=struct2table(allses);
allrest=struct2table(allrest);
