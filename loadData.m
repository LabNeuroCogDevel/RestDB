addpath(genpath('~/2015_01_25 BCT'));
addpath(genpath('/home/ni_tools/matlab_toolboxes/BrainConnectivityToolbox'))


%parcel = 'GordonHarOx'; nROI = 345;
parcel = 'hpc_pfc_brainstem_rstg'; nROI = 14;

pipeline = 'aroma_gsr';

clusterThresh = 0.8; % percentile threshold for binarization
louvainGamma = 1.1;

if ismac
    poolsize = 0;
    showPlots = 1;
else
    poolsize = 32;
    showPlots = 0;
end


%% Load from DB

dbcn = sqlite('rest.db');
tbl = get_rest(dbcn,sprintf('study like "cog" and preproc like "%s" and atlas like "%s"', pipeline, parcel));


%% load
r = nan*ones(nROI, nROI, size(tbl,1));
size(tbl,1)
for i = 1:size(tbl,1)
    if mod(i,20)==0
        fprintf(1, '%03d ', i);
        if mod(i,200)==0
            fprintf(1, '\n');
        end
    end
    fname = tbl(i,:).adj_file;
    thisr = readtable(fname{1}, 'TreatAsEmpty', 'NA');
    r(:,:,i) = table2array(thisr);
end
fprintf(1, 'Done!\n');

%% check for bad entries

badidx = find(squeeze(sum(sum(isinf(r),1),2))>0);

tbl(badidx,:) = [];
r(:,:,badidx) = [];

save(sprintf('saved_data/query_cog_%s_%s_%s.mat', pipeline, parcel, datestr(now, 'yyyymmdd')), 'tbl', 'r');


%% simple age effects
margins = [0.06 0.06];

data.conn_ahpc_vmpfc = squeeze(nanmean(nanmean(r(1:2, 7:8,:),1),2));
data.conn_ahpc_vlpfc = squeeze(nanmean(nanmean(r(1:2, 5:6,:),1),2));
data.conn_ahpc_dlpfc = squeeze(nanmean(nanmean(r(1:2, 3:4,:),1),2));
data.conn_ahpc_sgacc = squeeze(nanmean(r(1:2, 9,:)));

data.conn_phpc_vmpfc = squeeze(nanmean(nanmean(r(10:11, 7:8,:),1),2));
data.conn_phpc_vlpfc = squeeze(nanmean(nanmean(r(10:11, 5:6,:),1),2));
data.conn_phpc_dlpfc = squeeze(nanmean(nanmean(r(10:11, 3:4,:),1),2));
data.conn_phpc_sgacc = squeeze(nanmean(r(10:11, 9,:)));

age = tbl.age;
invage = 1./age;

meanFD = tbl.fd_mean;
sexid = strcmp(tbl.sex, 'M');
id = tbl.subj;
pcens = tbl.motion_pct_cens;

conns = fieldnames(data);
for conni = 1:length(conns)
    subplot_tight(2,4,conni, margins)
    
    
    thistbl = table(data.(conns{conni}), age, invage, meanFD, sexid, id, 'VariableNames', {'z','age','invage','fd','sex', 'id'});
    thistbl(find(thistbl.age<=9 | thistbl.age>=27 | pcens>.3),:) = [];

    plot(thistbl.age, thistbl.z, '.k');
    loessline(.9, 'rloess', 'r', 1)

    lme_null = fitlme(thistbl, 'z ~ sex + fd + (1|id)');
    lme_lin = fitlme(thistbl, 'z ~ age + sex + fd + (1|id)');
    lme_inv = fitlme(thistbl, 'z ~ invage + sex + fd + (1|id)');
    
    if lme_lin.ModelCriterion.AIC < lme_inv.ModelCriterion.AIC
        c = compare(lme_null, lme_lin);
    else
        c = compare(lme_null, lme_inv);
    end
    p = c.pValue(2);
    
    axis([min(thistbl.age) max(thistbl.age) -.6 1.4]);
    text(21, -.4, sprintf('p = %.02g', p), 'FontSize', 20, 'color', 'r');
    ylabel(conns{conni}, 'Interpreter', 'none');
    xlabel('Age');
    set(gca, 'FontSize', 14);

end

set(gcf, 'position', [604         461        1675         877]);
set(gcf, 'color', 'w');


%% better age effects
margins = [0.06 0.06];

% RH -> RH
data.conn_ahpc_vmpfc_rr = data.(atlas).r(1,7); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_ahpc_vlpfc_rr = data.(atlas).r(1,5); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_ahpc_dlpfc_rr = data.(atlas).r(1,3); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_ahpc_sgacc_rr = data.(atlas).r(1,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));

data.conn_phpc_vmpfc_rr = data.(atlas).r(10,7); %nanmean([data.(atlas).r(10,7) data.(atlas).r(11,8)]);%nanmean(nanmean(data.(atlas).r(10:11, 7:8)));
data.conn_phpc_vlpfc_rr = data.(atlas).r(10,5); %nanmean([data.(atlas).r(10,5) data.(atlas).r(11,6)]);%nanmean(nanmean(data.(atlas).r(10:11, 5:6)));
data.conn_phpc_dlpfc_rr = data.(atlas).r(10,3); %nanmean([data.(atlas).r(10,3) data.(atlas).r(11,4)]);%nanmean(nanmean(data.(atlas).r(10:11, 3:4)));
data.conn_phpc_sgacc_rr = data.(atlas).r(10,9); %nanmean([data.(atlas).r(10,9) data.(atlas).r(11,9)]);%nanmean(data.(atlas).r(10:11, 9));

data.conn_vta_vmpfc_rh = data.(atlas).r(12,7); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_vta_vlpfc_rh = data.(atlas).r(12,5); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_vta_dlpfc_rh = data.(atlas).r(12,3); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_vta_sgacc_rh = data.(atlas).r(12,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));

% RH -> RH
data.conn_ahpc_vmpfc_rl = data.(atlas).r(1,8); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_ahpc_vlpfc_rl = data.(atlas).r(1,6); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_ahpc_dlpfc_rl = data.(atlas).r(1,4); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_ahpc_sgacc_rl = data.(atlas).r(1,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));

data.conn_phpc_vmpfc_rl = data.(atlas).r(10,8); %nanmean([data.(atlas).r(10,7) data.(atlas).r(11,8)]);%nanmean(nanmean(data.(atlas).r(10:11, 7:8)));
data.conn_phpc_vlpfc_rl = data.(atlas).r(10,6); %nanmean([data.(atlas).r(10,5) data.(atlas).r(11,6)]);%nanmean(nanmean(data.(atlas).r(10:11, 5:6)));
data.conn_phpc_dlpfc_rl = data.(atlas).r(10,4); %nanmean([data.(atlas).r(10,3) data.(atlas).r(11,4)]);%nanmean(nanmean(data.(atlas).r(10:11, 3:4)));
data.conn_phpc_sgacc_rl = data.(atlas).r(10,9); %nanmean([data.(atlas).r(10,9) data.(atlas).r(11,9)]);%nanmean(data.(atlas).r(10:11, 9));

% LH -> LH
data.conn_ahpc_vmpfc_ll = data.(atlas).r(2,8); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_ahpc_vlpfc_ll = data.(atlas).r(2,6); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_ahpc_dlpfc_ll = data.(atlas).r(2,4); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_ahpc_sgacc_ll = data.(atlas).r(2,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));

data.conn_phpc_vmpfc_ll = data.(atlas).r(11,8); %nanmean([data.(atlas).r(10,7) data.(atlas).r(11,8)]);%nanmean(nanmean(data.(atlas).r(10:11, 7:8)));
data.conn_phpc_vlpfc_ll = data.(atlas).r(11,6); %nanmean([data.(atlas).r(10,5) data.(atlas).r(11,6)]);%nanmean(nanmean(data.(atlas).r(10:11, 5:6)));
data.conn_phpc_dlpfc_ll = data.(atlas).r(11,4); %nanmean([data.(atlas).r(10,3) data.(atlas).r(11,4)]);%nanmean(nanmean(data.(atlas).r(10:11, 3:4)));
data.conn_phpc_sgacc_ll = data.(atlas).r(11,9); %nanmean([data.(atlas).r(10,9) data.(atlas).r(11,9)]);%nanmean(data.(atlas).r(10:11, 9));

data.conn_vta_vmpfc_lh = data.(atlas).r(12,8); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_vta_vlpfc_lh = data.(atlas).r(12,6); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_vta_dlpfc_lh = data.(atlas).r(12,4); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_vta_sgacc_lh = data.(atlas).r(12,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));


% LH -> RH
data.conn_ahpc_vmpfc_lr = data.(atlas).r(2,7); %nanmean([data.(atlas).r(1,7) data.(atlas).r(2,8)]);%
data.conn_ahpc_vlpfc_lr = data.(atlas).r(2,5); %nanmean([data.(atlas).r(1,5) data.(atlas).r(2,6)]);%nanmean(nanmean(data.(atlas).r(1:2, 5:6)));
data.conn_ahpc_dlpfc_lr = data.(atlas).r(2,3); %nanmean([data.(atlas).r(1,3) data.(atlas).r(2,4)]);%nanmean(nanmean(data.(atlas).r(1:2, 3:4)));
data.conn_ahpc_sgacc_lr = data.(atlas).r(2,9); %nanmean([data.(atlas).r(1,9) data.(atlas).r(2,9)]);%nanmean(data.(atlas).r(1:2, 9));

data.conn_phpc_vmpfc_lr = data.(atlas).r(11,7); %nanmean([data.(atlas).r(10,7) data.(atlas).r(11,8)]);%nanmean(nanmean(data.(atlas).r(10:11, 7:8)));
data.conn_phpc_vlpfc_lr = data.(atlas).r(11,5); %nanmean([data.(atlas).r(10,5) data.(atlas).r(11,6)]);%nanmean(nanmean(data.(atlas).r(10:11, 5:6)));
data.conn_phpc_dlpfc_lr = data.(atlas).r(11,3); %nanmean([data.(atlas).r(10,3) data.(atlas).r(11,4)]);%nanmean(nanmean(data.(atlas).r(10:11, 3:4)));
data.conn_phpc_sgacc_lr = data.(atlas).r(11,9); %nanmean([data.(atlas).r(10,9) data.(atlas).r(11,9)]);%nanmean(data.(atlas).r(10:11, 9));

age = tbl.age;
invage = 1./age;

meanFD = tbl.fd_mean;
sexid = strcmp(tbl.sex, 'M');
id = tbl.subj;
pcens = tbl.motion_pct_cens;

conns = fieldnames(data);
for conni = 1:length(conns)
    subplot_tight(2,4,conni, margins)
    
    
    thistbl = table(data.(conns{conni}), age, invage, meanFD, sexid, id, 'VariableNames', {'z','age','invage','fd','sex', 'id'});
    thistbl(find(thistbl.age<=9 | thistbl.age>=27 | pcens>.3),:) = [];

    plot(thistbl.age, thistbl.z, '.k');
    loessline(.9, 'rloess', 'r', 1)

    lme_null = fitlme(thistbl, 'z ~ sex + fd + (1|id)');
    lme_lin = fitlme(thistbl, 'z ~ age + sex + fd + (1|id)');
    lme_inv = fitlme(thistbl, 'z ~ invage + sex + fd + (1|id)');
    
    if lme_lin.ModelCriterion.AIC < lme_inv.ModelCriterion.AIC
        c = compare(lme_null, lme_lin);
    else
        c = compare(lme_null, lme_inv);
    end
    p = c.pValue(2);
    
    axis([min(thistbl.age) max(thistbl.age) -.6 1.4]);
    text(21, -.4, sprintf('p = %.02g', p), 'FontSize', 20, 'color', 'r');
    ylabel(conns{conni}, 'Interpreter', 'none');
    xlabel('Age');
    set(gca, 'FontSize', 14);

end

set(gcf, 'position', [604         461        1675         877]);
set(gcf, 'color', 'w');
