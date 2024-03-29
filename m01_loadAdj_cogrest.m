%function data = m01_loadAdj_cogrest

%% db
%dbcn = sqlite('rest.db')


%% atlases
atlases = {'GordonHarOx', 'hpc_pfc_brainstem_rstg'};
pipelines = {'mhrestbase','aroma','aroma_gsr'};

start_idx = [0 115 228]+1; % add 1 since TRs are 0-based, but txt files are 1-based
end_idx = [26 139 243]+1;

fd_thresh = 0.3;
dvars_thresh = 20;

%% get directory list
dirs = dir(fullfile('/Volumes/Hera/preproc/cog_task/rest_spikemin/1*'));

for diri = 1:length(dirs)
    thisdir = dirs(diri);
    
    % Load session info into ses
    subjdate = thisdir.name;
    sdparts = strsplit(subjdate, '_');
    subj = sdparts{1};
    vdate = sdparts{2};
    
    % get age
    [s, r] = system(sprintf('/Volumes/Phillips/CogRest/scripts/getAge.sh %s %s 2>/dev/null', subj, vdate));
    if s == 0 && isnumeric(str2double(r))
        ageParts = strsplit(r, {sprintf('\n'), ' '}); % in case it returns more than one value
        age = str2double(ageParts{1});
        gender = ageParts{2}; %strcmp(ageParts{2}, 'M');
    else
        warning('Could not load age for %s @ %s', subj, vdate);
        age = NaN;
        gender = NaN;
    end

    ses = [];
    ses.ses_id = subjdate;
    ses.subj = subj;
    ses.age = age;
    ses.sex = gender;
    fprintf(1, '============================================================================================================================================\n');
    ses
    
    %insert(dbcn,'ses',{'ses_id',ses.ses_id,'age',ses.age,'sex',ses.sex})
    
    % Load all pipelines into rest
    
    for pipei = 1:length(pipelines)
        for atlasi = 1:length(atlases)
            rest = [];
            rest.ses_id = subjdate;
            rest.study = 'cog';
            rest.preproc = pipelines{pipei};
            rest.atlas = atlases{atlasi};

            switch pipelines{pipei}
                case 'mhrestbase'
                    scandir = fullfile('/Volumes/Phillips/CogRest/subjs/', subjdate, 'preproc');
                    censorFile = 'censor_custom_fd_0.3_dvars_20.1d';
                    fdFile = 'fd.txt';
                    dvarsFile = 'dvars.txt';
                    %/Volumes/Phillips/CogRest/subjs/10124_20060803/preproc/10124_20060803_GordonHarOx_adj.txt
                    adjFiles = dir(fullfile(scandir, sprintf('%s_%s_adj*.txt', subjdate, atlases{atlasi})));
                    if length(adjFiles)>=1
                        adjFile = fullfile(adjFiles(1).folder, adjFiles(1).name);
                    else
                        adjFile = '';
                    end
                    
                    
                    if ~exist(fullfile(scandir, 'fd.txt'), 'file') % make them
                        snip_fd = [];
                        snip_dvars = [];
                        for runi = 1:4
                            motiondir = fullfile(scandir, sprintf('rest_%d', runi), 'motion_info');
                            fd = load(fullfile(motiondir, 'fd.txt'));
                            dvars = load(fullfile(motiondir, 'dvars.txt'));

                            for i = 1:length(start_idx)
                                inds = start_idx(i):end_idx(i);
                                snip_fd = [snip_fd; fd(inds)];
                                snip_dvars = [snip_dvars; dvars(inds)];
                            end
                        end
                        fdfid = fopen(fullfile(scandir, fdFile), 'w'); fprintf(fdfid, '%.4f\n', snip_fd); fclose(fdfid);
                        dvarsfid = fopen(fullfile(scandir, dvarsFile), 'w'); fprintf(dvarsfid, '%.4f\n', snip_dvars); fclose(dvarsfid);
                    end

                case 'aroma'
                    scandir = fullfile('/Volumes/Hera/preproc/cog_task/rest_spikemin', subjdate, 'snip');
                    censorFile = 'motion_info/snip_censor.1D';
                    fdFile = 'fd.txt';
                    dvarsFile = 'dvars.txt';
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_pearson.txt', subjdate, atlases{atlasi}));
                case 'aroma_gsr'
                    scandir = fullfile('/Volumes/Hera/preproc/cog_task/rest_spikemin', subjdate, 'snip');
                    censorFile = 'motion_info/snip_censor.1D';
                    fdFile = 'fd.txt';
                    dvarsFile = 'dvars.txt';
                    %/data/Hera/preproc/cog_task/rest_spikemin/11217_20131022/snip/11217_20131022_GordonHarOx_adj_gsr_pearson.txt
                    adjFile = fullfile(scandir, sprintf('%s_%s_adj_gsr_pearson.txt', subjdate, atlases{atlasi}));
            end


            if ~exist(adjFile, 'file')
                adjFile
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
            % make field-value pairs
            restdata = {};
            f = fieldnames(rest);
            for fi = 1:length(f)
                restdata{end+1} = f{fi};
                restdata{end+1} = rest.(f{fi});
            end
            restdata
            %insert(dbcn,'rest', { restdata })
        end % end atlases
    end % end pipelines
    
    pause
end

    
        


        
        
        

        