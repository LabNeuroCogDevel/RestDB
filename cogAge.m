%% simple age effects
data = [];
conns = {'conn_ahpc_vmpfc','conn_ahpc_vlpfc','conn_ahpc_dlpfc','conn_ahpc_sgacc',...
         'conn_phpc_vmpfc','conn_phpc_vlpfc','conn_phpc_dlpfc','conn_phpc_sgacc'};
uSubjs = unique(tbl.subj);
subjNums = [];
for i = 1:size(tbl,1); subjNums(i) = find( strcmp(tbl(i,:).subj, uSubjs) ); end

    
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

%conns = fieldnames(data);
for conni = 1:length(conns)
    subplot_tight(2,4,conni, margins)
    
    
    thistbl = table(data.(conns{conni}), age, invage, meanFD, sexid, subjNums', 'VariableNames', {'z','age','invage','fd','sex', 'id'});
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


%% better age fx
figure

predages = (min(age(age>0)):.1:max(age))';
predconn = zeros(length(predages), length(conns));

% RH -> RH
data.conn_ahpc_vmpfc_rr = squeeze(r(1,7,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_ahpc_vlpfc_rr = squeeze(r(1,5,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_ahpc_dlpfc_rr = squeeze(r(1,3,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_ahpc_sgacc_rr = squeeze(r(1,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));

data.conn_phpc_vmpfc_rr = squeeze(r(10,7,:)); %nanmean([squeeze(r(10,7) squeeze(r(11,8)]);%nanmean(nanmean(squeeze(r(10:11, 7:8)));
data.conn_phpc_vlpfc_rr = squeeze(r(10,5,:)); %nanmean([squeeze(r(10,5) squeeze(r(11,6)]);%nanmean(nanmean(squeeze(r(10:11, 5:6)));
data.conn_phpc_dlpfc_rr = squeeze(r(10,3,:)); %nanmean([squeeze(r(10,3) squeeze(r(11,4)]);%nanmean(nanmean(squeeze(r(10:11, 3:4)));
data.conn_phpc_sgacc_rr = squeeze(r(10,9,:)); %nanmean([squeeze(r(10,9) squeeze(r(11,9)]);%nanmean(squeeze(r(10:11, 9));

data.conn_vta_vmpfc_rh = squeeze(r(12,7,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_vta_vlpfc_rh = squeeze(r(12,5,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_vta_dlpfc_rh = squeeze(r(12,3,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_vta_sgacc_rh = squeeze(r(12,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));

% RH -> RH
data.conn_ahpc_vmpfc_rl = squeeze(r(1,8,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_ahpc_vlpfc_rl = squeeze(r(1,6,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_ahpc_dlpfc_rl = squeeze(r(1,4,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_ahpc_sgacc_rl = squeeze(r(1,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));

data.conn_phpc_vmpfc_rl = squeeze(r(10,8,:)); %nanmean([squeeze(r(10,7) squeeze(r(11,8)]);%nanmean(nanmean(squeeze(r(10:11, 7:8)));
data.conn_phpc_vlpfc_rl = squeeze(r(10,6,:)); %nanmean([squeeze(r(10,5) squeeze(r(11,6)]);%nanmean(nanmean(squeeze(r(10:11, 5:6)));
data.conn_phpc_dlpfc_rl = squeeze(r(10,4,:)); %nanmean([squeeze(r(10,3) squeeze(r(11,4)]);%nanmean(nanmean(squeeze(r(10:11, 3:4)));
data.conn_phpc_sgacc_rl = squeeze(r(10,9,:)); %nanmean([squeeze(r(10,9) squeeze(r(11,9)]);%nanmean(squeeze(r(10:11, 9));

% LH -> LH
data.conn_ahpc_vmpfc_ll = squeeze(r(2,8,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_ahpc_vlpfc_ll = squeeze(r(2,6,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_ahpc_dlpfc_ll = squeeze(r(2,4,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_ahpc_sgacc_ll = squeeze(r(2,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));

data.conn_phpc_vmpfc_ll = squeeze(r(11,8,:)); %nanmean([squeeze(r(10,7) squeeze(r(11,8)]);%nanmean(nanmean(squeeze(r(10:11, 7:8)));
data.conn_phpc_vlpfc_ll = squeeze(r(11,6,:)); %nanmean([squeeze(r(10,5) squeeze(r(11,6)]);%nanmean(nanmean(squeeze(r(10:11, 5:6)));
data.conn_phpc_dlpfc_ll = squeeze(r(11,4,:)); %nanmean([squeeze(r(10,3) squeeze(r(11,4)]);%nanmean(nanmean(squeeze(r(10:11, 3:4)));
data.conn_phpc_sgacc_ll = squeeze(r(11,9,:)); %nanmean([squeeze(r(10,9) squeeze(r(11,9)]);%nanmean(squeeze(r(10:11, 9));

data.conn_vta_vmpfc_lh = squeeze(r(12,8,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_vta_vlpfc_lh = squeeze(r(12,6,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_vta_dlpfc_lh = squeeze(r(12,4,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_vta_sgacc_lh = squeeze(r(12,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));


% LH -> RH
data.conn_ahpc_vmpfc_lr = squeeze(r(2,7,:)); %nanmean([squeeze(r(1,7) squeeze(r(2,8)]);%
data.conn_ahpc_vlpfc_lr = squeeze(r(2,5,:)); %nanmean([squeeze(r(1,5) squeeze(r(2,6)]);%nanmean(nanmean(squeeze(r(1:2, 5:6)));
data.conn_ahpc_dlpfc_lr = squeeze(r(2,3,:)); %nanmean([squeeze(r(1,3) squeeze(r(2,4)]);%nanmean(nanmean(squeeze(r(1:2, 3:4)));
data.conn_ahpc_sgacc_lr = squeeze(r(2,9,:)); %nanmean([squeeze(r(1,9) squeeze(r(2,9)]);%nanmean(squeeze(r(1:2, 9));

data.conn_phpc_vmpfc_lr = squeeze(r(11,7,:)); %nanmean([squeeze(r(10,7) squeeze(r(11,8)]);%nanmean(nanmean(squeeze(r(10:11, 7:8)));
data.conn_phpc_vlpfc_lr = squeeze(r(11,5,:)); %nanmean([squeeze(r(10,5) squeeze(r(11,6)]);%nanmean(nanmean(squeeze(r(10:11, 5:6)));
data.conn_phpc_dlpfc_lr = squeeze(r(11,3,:)); %nanmean([squeeze(r(10,3) squeeze(r(11,4)]);%nanmean(nanmean(squeeze(r(10:11, 3:4)));
data.conn_phpc_sgacc_lr = squeeze(r(11,9,:)); %nanmean([squeeze(r(10,9) squeeze(r(11,9)]);%nanmean(squeeze(r(10:11, 9));

age = tbl.age;
invage = 1./age;
age2 = (tbl.age-mean(tbl.age)).^2;
age3 = (tbl.age-mean(tbl.age)).^3;

meanFD = tbl.fd_mean;
sexid = 1*strcmp(tbl.sex, 'M');
id = tbl.subj;
pcens = tbl.motion_pct_cens;

for conni = 1:length(conns)
    subplot_tight(2,4,conni, margins)

    conn_rr = [data.([conns{conni} '_rr'])];
    conn_rl = [data.([conns{conni} '_rl'])];
    conn_ll = [data.([conns{conni} '_ll'])];
    conn_lr = [data.([conns{conni} '_lr'])];

    n = size(conn_rl,1);
    src = [ones(n,1); zeros(n,1);ones(n,1);zeros(n,1)];
    targ = [ones(n,1); ones(n,1);zeros(n,1);zeros(n,1)];
    allconn = [conn_rr; conn_rl; conn_ll; conn_lr];
    thistbl = table(allconn, repmat(age, [4 1]), repmat(invage, [4 1]), repmat(age2, [4 1]), repmat(age3, [4 1]), repmat(meanFD, [4 1]), repmat(sexid, [4 1]), repmat(subjNums', [4 1]), src, targ, ...
        'VariableNames', {'z','age','invage','age2','age3','fd','sex', 'id', 'src','targ'});

    thistbl(find(thistbl.age<=9 | thistbl.age>=27 | repmat(pcens,[4 1])>.3),:) = [];

    plot(thistbl.age, thistbl.z, '.k');
    loessline(.9, 'rloess', 'r', 1)

    lme_null = fitlme(thistbl, 'z ~ sex + fd + src + targ + (1|id)');
    lme_lin = fitlme(thistbl, 'z ~ age + sex + fd + src + targ + (1|id)');
    lme_inv = fitlme(thistbl, 'z ~ invage + sex + fd + src + targ + (1|id)');

    lme_poly2 = fitlme(thistbl, 'z ~ age2 + sex + fd + src + targ + (1|id)');
    lme_poly12 = fitlme(thistbl, 'z ~ age + age2 + sex + fd + src + targ + (1|id)');
    lme_poly13 = fitlme(thistbl, 'z ~ age + age3 + sex + fd + src + targ + (1|id)');
    lme_poly23 = fitlme(thistbl, 'z ~ age2 + age3 + sex + fd + src + targ + (1|id)');
    lme_poly123 = fitlme(thistbl, 'z ~ age + age2 + age3 + sex + fd + src + targ + (1|id)');
    lme_poly3 = fitlme(thistbl, 'z ~ age3 + sex + fd + src + targ + (1|id)');

    models = {lme_lin lme_inv lme_poly2 lme_poly12 lme_poly13 lme_poly23 lme_poly123 lme_poly3};
    modelNames = {'Linear','Inverse','Poly2','Poly12','Poly13','Poly23','Poly123','Poly3'};
    aic = zeros(size(models));
    for mi = 1:length(models)
        aic(mi) = models{mi}.ModelCriterion.AIC;
    end
    aic = aic - lme_null.ModelCriterion.AIC;
    [bestAIC, bestModel] = min(aic);
    
    predTbl = table(nan*ones(size(predages)), predages, 1./predages, (predages-mean(tbl.age)).^2, (predages-mean(tbl.age)).^3, ...
        mean(meanFD)*ones(size(predages)), ones(size(predages)), ones(size(predages)), ones(size(predages)), ones(size(predages)), ...
    	'VariableNames', {'z','age','invage','age2','age3','fd','sex', 'id', 'src','targ'});
        
    predconn(:,conni) = predict(models{bestModel}, predTbl, 'Conditional', false);
    c = compare(lme_null, models{bestModel});
    p = c.pValue(2);

    hold on
    plot(predages, predconn(:,conni), '--b', 'LineWidth', 3);
    fprintf(1, '%s: best=%s, dAIC=%.02f, p=%.02g\n', conns{conni}, modelNames{bestModel}, bestAIC, p);
%    if p<0.01
%	models{bestModel}
%	models{bestModel}.Coefficients.Estimate'
%	c
%    end

   axis([min(thistbl.age) max(thistbl.age) -.6 1.4]);
   text(21, -.4, sprintf('p = %.02g', p), 'FontSize', 20, 'color', 'r');
   ylabel(conns{conni}, 'Interpreter', 'none');
   xlabel('Age');
   set(gca, 'FontSize', 14);

end

set(gcf, 'position', [604         461        1675         877]);
set(gcf, 'color', 'w');
