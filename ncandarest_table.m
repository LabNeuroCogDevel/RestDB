

%% atlases
atlases = atlas_list('ncanda'); %  {'GordonHarOx', 'hpc_apriori_atlas_11','hpc_pfc_brainstem_rstg','CogEmoROIs'};
pipelines = {'aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = Inf;

%% subject list
alcUse = readtable('/Volumes/Zeus/preproc/scripts_finn/ncanda/nolowinformation_NCANDA20191118.csv', 'Delimiter', ',','ReadVariableNames',true);
demo = readtable('/Volumes/Zeus/NCANDA_Behavioral/Data/NCANDA_RELEASE_3Y_REDCAP_MEASUREMENTS_V01/summaries/redcap/demographics.csv', 'Delimiter', ',','ReadVariableNames',true);

dirs = dir(fullfile('/Volumes/Hera/preproc/ncanda_siemens/MHRest_ncanda/S*_*'));

allses=[];
allrest=[];

%%

visitnames = {'baseline', 'followup_1y', 'followup_2y', 'followup_3y', 'followup_4y'}; % 0,1,2,3..

for diri = 1:length(dirs)
    thisdir = dirs(diri);

    subj = thisdir.name;
    
    parts = strsplit(subj, '_');
    subjid = parts{1};
    vnum = str2double(parts{2});
    vname = visitnames{vnum+1}; % +1 since 0-indexed
    
    vdate = NaN;
    
    % get age
    ageIdx = find( strcmp(demo.subject, sprintf('NCANDA_%s',subjid)) & strcmp(demo.visit, vname) );
    if length(ageIdx) == 1
        age = demo.mri_restingstate_age(ageIdx);
        gender = demo.sex(ageIdx);
    else
        'Bad match'
        subj
        ageIdx
        
        age = NaN;
        gender = {''};
    end
    
    % init structs
    ses = [];
    ses.ses_id = subj;
    ses.subj = subj;
    ses.age = age;
    ses.sex = gender{1};
    
    % get dx
    dxIdx = find( strcmp(alcUse.subject, sprintf('NCANDA_%s',subjid)) & strcmp(alcUse.visit, vname) );
    if length(dxIdx) == 1
        if alcUse.nolowthresholdcoding(dxIdx)
            ses.dx = 'control';
        else
            ses.dx = 'alcuse';
        end
    else
        ses.dx = 'n/a';
        keyboard
    end
    
    
    
    fprintf(1, '============================================================================================================================================\n');
    fprintf(1, '%d/%d\n', diri, size(dirs,1));
    
    ses
    
    % build struct array that we can later turn into a table
    allses=[allses ses];
    
    % Load all pipelines into rest
    for pipei = 1:length(pipelines)
        for atlasi = 1:length(atlases)
            rest = [];
            rest.ses_id = subj;
            rest.study = 'pnc';
            rest.preproc = pipelines{pipei};
            rest.atlas = atlases{atlasi};

            switch pipelines{pipei}
                case 'aroma'
                    scandir = fullfile('/Volumes/Hera/preproc/ncanda_siemens/MHRest_ncanda',subj);
                    censorFile = 'censor_fd0.3_run5.1D';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subj, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subj, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'brnaswudktm0_func_5.nii.gz');

                case 'aroma_gsr'
                    scandir = fullfile('/Volumes/Hera/preproc/ncanda_siemens/MHRest_ncanda',subj);
                    censorFile = 'censor_fd0.3_run5.1D';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subj, atlases{atlasi}));
                    %/Volumes/Hera/preproc/ncanda_siemens/MHRest_ncanda/S00385_0//S00385_0_Seitzman300_adj_gsr_pearson.txt
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subj, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'bgrnaswudktm0_func_5.nii.gz');
            end
            
            if ~exist(adjFile, 'file')
                %fprintf(1, 'Cannot find adjFile %s (pipe %s, atlas %s)\n', adjFile, pipelines{pipei}, atlases{atlasi});
                continue
            else
                fprintf(1, 'Running adjFile %s (pipe %s, atlas %s)\n', adjFile, pipelines{pipei}, atlases{atlasi});
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

            rest;
            % build array strcut of all rests to turn into table
            allrest=[allrest rest];
        end % end atlases
    end % end pipelines
    
    %pause
end




% make arrays into tables
allses=struct2table(allses);
allrest=struct2table(allrest);

    