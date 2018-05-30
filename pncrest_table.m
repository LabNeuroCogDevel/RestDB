%function data = m01_loadAdj_cogrest

%% atlases
atlases = {'GordonHarOx', 'hpc_apriori_atlas_11'};
pipelines = {'mhrestbase','aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = 20;

%% subject list
usable = readtable('/Volumes/Zeus/Finn/PNC/final_PNC_controls.txt');
agesTable = readtable('/Volumes/Zeus/Finn/PNC/scripts/pnc_ages_sex.csv', 'Delimiter', ',','ReadVariableNames',true);

allses=[];
allrest=[];

for subji = 1:size(usable,1)
    subj = num2str(usable(subji,:).SUBJID);
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
    fprintf(1, '============================================================================================================================================\n');
    fprintf(1, '%d/%d\n', subji, size(usable,1));
    
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
                    %/Volumes/Phillips/CogRest/subjs/10124_20060803/preproc/10124_20060803_GordonHarOx_adj.txt
                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subj, atlases{atlasi})));
                    if length(adjFiles)>=1
                        adjFile = fullfile(adjFiles(1).folder, adjFiles(1).name);
                    else
                        adjFile = '';
                    end

                case 'aroma'
                    scandir = fullfile('/Volumes/Zeus/preproc/PNC_rest/aroma_nogsr',subj,'preproc');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subj, atlases{atlasi}));
                case 'aroma_gsr'
                    scandir = fullfile('/Volumes/Zeus/preproc/PNC_rest/aroma_gsr',subj,'preproc');
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subj, atlases{atlasi}));
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

    
        


        
        
        

        
