%function data = m01_loadAdj_cogrest

%% atlases
atlases = atlas_list('rew'); % {'GordonHarOx','CogEmoROIs'};
pipelines = {'mhrestbase','aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = 20;

%% get directory list
dirs = dir(fullfile('/Volumes/Zeus/preproc/reward_rest/MHRest_aroma/1*'));
%/Volumes/Zeus/preproc/reward_rest/MHRest_aroma/10646_20090410/rest/

allses=[];
allrest=[];

% load ages
agesTable = readtable('/Volumes/Phillips/CogRest/scripts/multistudy/reward_age_sex.csv', 'Delimiter', ',','ReadVariableNames',true);


for diri = 1:length(dirs)
    thisdir = dirs(diri);
    
    % Load session info into ses
    subjdate = thisdir.name;
    sdparts = strsplit(subjdate, '_');
    subj = sdparts{1};
    vdate = sdparts{2};
    
    % get age
    ageIdx = find(strcmp(agesTable.id, subj) & strcmp(agesTable.vdate, vdate));
    if ~isempty(ageIdx)
        age = agesTable.age(ageIdx);
        gender = agesTable.sex(ageIdx);
    else
        age = NaN;
        gender = {''};
    end

    ses = [];
    ses.ses_id = subjdate;
    ses.subj = subj;
    ses.age = age;
    ses.sex = gender{1};
    ses.dx = 'control';
    
    fprintf(1, '============================================================================================================================================\n');
    fprintf(1, '%d/%d\n', diri, length(dirs));
    ses
    %f = fieldnames(ses); for fi = 1:length(f); fprintf(1, '%s: %s\n', f{fi}, class(ses.(f{fi}))); end; return
    
    % build struct array that we can later turn into a table
    allses=[allses ses];
    
    % Load all pipelines into rest
    for pipei = 1:length(pipelines)
        for atlasi = 1:length(atlases)
            rest = [];
            rest.ses_id = subjdate;
            rest.study = 'rew';
            rest.preproc = pipelines{pipei};
            rest.atlas = atlases{atlasi};

            switch pipelines{pipei}
                case 'mhrestbase'
                    scandir = fullfile('/mnt/usb/Deepu/RewardRestTask/subj', subjdate, 'rest');
                    censorFile = 'censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    %/Volumes/Phillips/CogRest/subjs/10124_20060803/preproc/10124_20060803_GordonHarOx_adj.txt
                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subjdate, atlases{atlasi})));
                    fourdFile = fullfile(scandir, 'brnswdktm_restepi_5.nii.gz');
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
                    scandir = fullfile('/Volumes/Zeus/preproc/reward_rest/MHRest_aroma/', subjdate, 'rest');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subjdate, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subjdate, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'brnaswdktm_restepi_5.nii.gz');

                case 'aroma_gsr'
                    scandir = fullfile('/Volumes/Zeus/preproc/reward_rest/MHRest_aroma/', subjdate, 'rest');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    %/data/Hera/preproc/cog_task/rest_spikemin/11217_20131022/snip/11217_20131022_GordonHarOx_adj_gsr_pearson.txt
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subjdate, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subjdate, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'bgrnaswdktm_restepi_5.nii.gz');
            end


            if ~exist(adjFile, 'file')
                fprintf(1, 'Cannot find adjFile %s for atlas=%s, pipeline=%s\n', adjFile, atlases{atlasi}, pipelines{pipei});
                continue
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

    
        


        
        
        

        
