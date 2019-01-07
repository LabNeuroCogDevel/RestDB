%function data = m01_loadAdj_cogrest

%% atlases
atlases = atlas_list('pnc'); %  {'GordonHarOx', 'hpc_apriori_atlas_11','hpc_pfc_brainstem_rstg','CogEmoROIs'};
pipelines = {'mhrestbase','aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = 20;

%% subject list
usable = readtable('/Volumes/Zeus/Finn/PNC/final_PNC_controls.txt');
agesTable = readtable('/Volumes/Zeus/Finn/PNC/scripts/pnc_ages_sex.csv', 'Delimiter', ',','ReadVariableNames',true);
dx = readtable('/Volumes/Hera/Projects/RestDB/20180601_PNC_imaging.csv', 'ReadVariableNames', true, 'Delimiter',',' );

dirs = dir(fullfile('/Volumes/Zeus/Finn/PNC/subjs/6*'));

allses=[];
allrest=[];

for diri = 1:length(dirs)
    thisdir = dirs(diri);
%    subj = num2str(usable(subji,:).SUBJID);
    % Load session info into ses
    subj = thisdir.name;
    
    vdate = NaN;
    
    % get age
    ageIdx = find(agesTable.subjid == str2double(subj));
    if ~isempty(ageIdx)
        age = agesTable.age(ageIdx);
        gender = agesTable.sex(ageIdx);
    else
        age = NaN;
        gender = {''};
    end


    ses = [];
    ses.ses_id = subj;
    ses.subj = subj;
    ses.age = age;
    ses.sex = gender{1};
    
    dxIdx = find(dx.SUBJID == str2double(subj));
    if length(dxIdx) == 1
        ses.dx = dx(dxIdx,:).final_dx{1};
    else
        ses.dx = 'n/a';
    end
    
    
    fprintf(1, '============================================================================================================================================\n');
    fprintf(1, '%d/%d\n', diri, size(dirs,1));
    
    ses
    %f = fieldnames(ses); for fi = 1:length(f); fprintf(1, '%s: %s\n', f{fi}, class(ses.(f{fi}))); end; return
    
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
                case 'mhrestbase'
                    scandir = fullfile('/Volumes/Zeus/Finn/PNC/subjs',subj,'preproc');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    fourdFile = fullfile(scandir, 'brnswdktm_restepi_5.nii.gz');

                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subj, atlases{atlasi})));
                    if length(adjFiles)>=1
                        adjFile = fullfile(adjFiles(1).folder, adjFiles(1).name);
                    else
                        adjFile = '';
                    end
                    tsFiles = dir(fullfile(scandir, sprintf('%s_%s_ts*.txt', subj, atlases{atlasi})));
                    if length(tsFiles)>=1
                        tsFile = fullfile(tsFiles(1).folder, tsFiles(1).name);
                    else
                        tsFile = '';
                    end
                case 'aroma'
                    scandir = fullfile('/Volumes/Zeus/preproc/PNC_rest/aroma',subj,'preproc');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subj, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts.txt', subj, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'brnaswdktm_restepi_5.nii.gz');

                case 'aroma_gsr'
                    scandir = fullfile('/Volumes/Zeus/preproc/PNC_rest/aroma',subj,'preproc');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subj, atlases{atlasi}));
                    tsFile = fullfile(scandir, sprintf('%s_%s_ts_gsr.txt', subj, atlases{atlasi}));
                    fourdFile = fullfile(scandir, 'bgrnaswdktm_restepi_5.nii.gz');
            end


            if ~exist(adjFile, 'file')
                fprintf(1, 'Cannot find adjFile %s\n', adjFile);
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

    
        


        
        
        

        
