% load all gsr

atlas = 'wb1038';
pipeline = 'aroma_gsr';
study = '%';
%study = 'cog OR pet OR rew';

clear r r_vec lowerInds

if 1
    dbcn = sqlite('rest.db');
    tbl = get_rest(dbcn,sprintf('rest.study like "%s" and rest.preproc like "%s" and atlas like "%s" and dx like "control"', study, pipeline, atlas));

    %tbl = get_rest(dbcn,sprintf('study like "%s" and preproc like "%s" and atlas like "%s"', study, pipeline, atlas));

    % load
    size(tbl,1)
    unique(tbl.study)

    for i = 1:size(tbl,1)
        if mod(i,20)==0
            fprintf(1, '%03d ', i);
            if mod(i,200)==0
                fprintf(1, '\n');
            end
        end
        fname = tbl(i,:).adj_file;
        %fname = strrep(fname, 'Hera', 'Hera_xc');
        thisr = readtable(fname{1}, 'TreatAsEmpty', 'NA');
        
        if ~exist('r','var')
            nROI = size(thisr, 1);
            r = nan*ones(nROI, nROI, size(tbl,1));
            
            lowerInds = find(tril(ones(nROI), -1));
            r_vec = nan*ones(length(lowerInds), size(tbl,1));
        end

        thisrArr = table2array(thisr);

        if (size(thisrArr,1) ~= size(thisrArr,2)) | (size(thisrArr,1) ~= size(r,1)) | (size(thisrArr,2) ~= size(r,2))
            thisrArr = nan(size(r,1), size(r,2));
        end

        r(:,:,i) = thisrArr;
        r_vec(:,i) = thisrArr(lowerInds);
        
    end
    fprintf(1, 'Done!\n');

    % check for bad entries

    badidx = find(squeeze(sum(sum(isinf(r),1),2))>0 | tbl.age==0);

    tbl(badidx,:) = [];
    r(:,:,badidx) = [];

    save(sprintf('saved_data/query_%s_%s_%s_%s.mat', study, pipeline, atlas, datestr(now, 'yyyymmdd')), 'tbl', 'r', 'r_vec', 'lowerInds','atlas','pipeline','study');

else
    load(sprintf('saved_data/query_%s_%s_%s_%s.mat', study, pipeline, atlas, '20180531'), 'tbl', 'r');
end


