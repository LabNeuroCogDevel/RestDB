%function data = m01_loadAdj_cogrest

%% atlases
atlases = {'GordonHarOx'};
pipelines = {'mhrestbase','aroma','aroma_gsr'};

fd_thresh = 0.3;
dvars_thresh = 24;

%% get directory list
dirs = dir(fullfile('/Volumes/Zeus/preproc/petrest_rac*/brnsuwdktm_rest/1*'));
%/Volumes/Zeus/preproc/reward_rest/MHRest_aroma/10646_20090410/rest/

allses=[];
allrest=[];

% load ages
%agesTable = readtable('/Volumes/Phillips/mMR_PETDA/scripts/txt/subjinfo_agesexids.csv', 'Delimiter', '\t','ReadVariableNames',true);
agesTable = readtable('/Volumes/Phillips/mMR_PETDA/scripts/merged_data.csv', 'Delimiter', ',','ReadVariableNames',true);

%%
for diri = 1:length(dirs)
    thisdir = dirs(diri);
    
    % Load session info into ses
    subjdate = thisdir.name;
    sdparts = strsplit(subjdate, '_');
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
            rest.study = 'pet';
            rest.preproc = pipelines{pipei};
            rest.atlas = atlases{atlasi};

            switch pipelines{pipei}
                case 'mhrestbase'
                    scandir = fullfile(basedir, 'brnsuwdktm_rest', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    %/Volumes/Phillips/CogRest/subjs/10124_20060803/preproc/10124_20060803_GordonHarOx_adj.txt
                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subjdate, atlases{atlasi})));
                    if length(adjFiles)>=1
                        adjFile = fullfile(adjFiles(1).folder, adjFiles(1).name);
                    else
                        adjFile = '';
                    end

                case 'aroma'
                    scandir = fullfile(basedir, 'MHRest_FM_ica', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subjdate, atlases{atlasi}));
                case 'aroma_gsr'
                    scandir = fullfile(basedir, 'MHRest_FM_ica', subjdate);
                    censorFile = 'motion_info/censor_custom_fd_0.3_dvars_24.1d';
                    fdFile = 'motion_info/fd.txt';
                    dvarsFile = 'motion_info/dvars.txt';
                    %/data/Hera/preproc/cog_task/rest_spikemin/11217_20131022/snip/11217_20131022_GordonHarOx_adj_gsr_pearson.txt
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subjdate, atlases{atlasi}));
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

    
        


        
        
        

        
