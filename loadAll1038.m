% load all gsr
clear r r_vec lowerInds

cd /Volumes/Hera/Projects/RestDB
atlas = 'wb1038';
pipeline = 'aroma_gsr';
study = '%';
nROI = 1038;
lowerInds = find(tril(ones(nROI), -1));
dbcn = sqlite('rest.db');
tbl = get_rest(dbcn,sprintf('rest.study like "%s" and rest.preproc like "%s" and atlas like "%s" and dx like "control"', study, pipeline, atlas));

if 1
%    dbcn = sqlite('rest.db');
%    tbl = get_rest(dbcn,sprintf('rest.study like "%s" and rest.preproc like "%s" and atlas like "%s" and dx like "control"', study, pipeline, atlas));

    goodidx =  [];
    for i = 1:height(tbl)
	if isempty(strfind(tbl(i,:).ts_file{1}, 'rac2'))
		goodidx(end+1) = i;
	end
    end
    tbl = tbl(goodidx,:);

    % load
    size(tbl,1)
    unique(tbl.study)
    writetable(tbl, 'wb1038.csv');

    % add siemens_st
%     idx = find(strcmp(tbl.study, 'ncsiemens'));
%     new_tbl = tbl(idx,:);
%     for i = 1:height(new_tbl)
%         new_tbl(i,:).study = {'ncs_st'};
%         new_tbl(i,:).ts_file = strrep(new_tbl(i,:).ts_file, 'ncanda_siemens', 'ncanda_siemens_st');
%         new_tbl(i,:).adj_file = strrep(new_tbl(i,:).adj_file, 'ncanda_siemens', 'ncanda_siemens_st');
%     end
%     tbl = [tbl; new_tbl];

    r_vec = nan*ones(length(lowerInds), size(tbl,1));

    %tbl = get_rest(dbcn,sprintf('study like "%s" and preproc like "%s" and atlas like "%s"', study, pipeline, atlas));

    % check for bad entries
    %badidx = find(squeeze(sum(sum(isinf(r),1),2))>0 | tbl.age==0);
    badidx = find(tbl.age==0);
    tbl(badidx,:) = [];
    %r(:,:,badidx) = [];


    for i = 1:size(tbl,1)
        if mod(i,20)==0
            fprintf(1, '%03d ', i);
            if mod(i,200)==0
                fprintf(1, '\n');
            end
        end
                
        fname = tbl(i,:).adj_file;
        %fname = strrep(fname, 'Hera', 'Hera_xc');

        if exist(fname{1}, 'file')
            thisr = readtable(fname{1}, 'TreatAsEmpty', 'NA');
            thisrArr = table2array(thisr);

            if (size(thisrArr,1) ~= size(thisrArr,2)) | (size(thisrArr,1) ~= nROI) | (size(thisrArr,2) ~= nROI)
                %thisrArr = nan(size(r,1), size(r,2));
                r_vec(:,i) = nan(size(r_vec(:,i)));
            else
                r_vec(:,i) = single(thisrArr(lowerInds));
                %r_vec(:,i) = thisrArr(lowerInds);
            end
        else
            r_vec(:,i) = nan(size(r_vec(:,i)));
        end

        %r(:,:,i) = thisrArr;
    	
        clearvars -except tbl nROI lowerInds r_vec i
        
    end
    fprintf(1, 'Done!\n');

    %save(sprintf('saved_data/query_%s_%s_%s_%s.mat', study, pipeline, atlas, datestr(now, 'yyyymmdd')), 'tbl', 'r', 'r_vec', 'lowerInds','atlas','pipeline','study');
    save('wb1038.mat', 'r_vec', 'tbl', '-v7.3');
    
    

else
    load(sprintf('saved_data/query_%s_%s_%s_%s.mat', study, pipeline, atlas, '20180531'), 'tbl', 'r');
end


