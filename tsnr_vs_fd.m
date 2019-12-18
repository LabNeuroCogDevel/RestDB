%% set up
atlas = 'wb1038';
pipeline = 'aroma_gsr';
study = 'pnc';
%study = 'cog OR pet OR rew';

clear r r_vec lowerInds

if ~exist('tbl','var') || isempty(tbl)
    dbcn = sqlite('rest.db');
    tbl = get_rest(dbcn,sprintf('rest.study like "%s" and rest.preproc like "%s" and atlas like "%s" and dx like "control"', study, pipeline, atlas));
end

mask = '/opt/ni_tools/standard_old/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_brain_2.3mm.nii';
mask_nii = load_nifti(mask);
mask_idx = find(mask_nii.vol > 50);

%% load all tSNR maps
all_tsnr = [];
all_tsnr_vec = [];
all_fd = [];

for i = 1:height(tbl)
    parts = strsplit(tbl(i,:).ts_file{1}, '/');
    thisdir = fullfile(filesep, parts{1:end-1});
    tsnr_file = fullfile(thisdir, 'tsnr', 'bgrnaswdktm_tsnr.nii.gz');
    
    if isnan(tbl(i,:).tsnr) || isempty(tbl(i,:).tsnr) || tbl(i,:).tsnr==0
        fprintf(1, '%d: SKIPPING %s (bad tsnr: %.2f)\n', i, tbl(i,:).subj{1}, tbl(i,:).tsnr);
        continue
    end
    
    if exist(tsnr_file, 'file')
        nii = load_nifti(tsnr_file);
    else
        fprintf(1, '%d: SKIPPING %s (no tsnr file: %s)\n', i, tbl(i,:).subj{1}, tsnr_file);
        continue
    end
    
    if all(size(nii.vol) == size(mask_nii.vol))
        all_tsnr_vec(end+1, :) = nii.vol(mask_idx);
        all_tsnr(end+1) = tbl(i,:).tsnr;
        all_fd(end+1) = tbl(i,:).fd_mean;
    else
        fprintf(1, '%d: SKIPPING %s (bad tsnr dimensions: %d x %d x %d)\n', i, tbl(i,:).subj{1}, size(nii.vol));
        continue
    end
    
    fprintf(1, '%d: Added %s (%d)\n', i, tbl(i,:).subj{1}, length(all_tsnr));

end

save('tsnr_data.mat', 'all_tsnr', 'all_tsnr_vec', 'all_fd');


%% compute PCs
if ~exist('all_tsnr_vec', 'var')
    load('tsnr_data.mat');
end

%[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(all_tsnr_vec);

compi = 1;
plot(all_tsnr', SCORE(:,compi), '.')
lsline




%% predict FD


%% look at prediction outliers