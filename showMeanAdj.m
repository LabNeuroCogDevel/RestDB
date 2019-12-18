addpath('altmany-export_fig-4282d74/');
rmpath(genpath('/opt/ni_tools/matlab_toolboxes/fieldtrip'))
atlas = 'wb1038';
pipeline = 'aroma_gsr';
study = '%';

nROI = 1038;
nSubj = size(r_vec, 2);
lowerInds = find(tril(ones(nROI), -1));

if ~exist('r', 'var')
    r = nan(nROI, nROI, nSubj);
    for i = 1:nSubj
        thisr = nan(nROI, nROI);
        thisr(lowerInds) = r_vec(:,i);
        thisr(isnan(thisr)) = 0;
        thisr = thisr + flipud( rot90( thisr ) );
        thisr(find(eye(size(thisr)))) = 0;
        r(:,:,i) = thisr;
    end
end


h = figure('visible', 'off')
[networkIDs, allnets] = loadParcLabels;
meanr = nanmean(r,3);

[X,Y,INDSORT] = grid_communities(networkIDs); % call function
imagesc(meanr(INDSORT,INDSORT));           % plot ordered adjacency matrix
hold on;                                 % hold on to overlay community visualization
plot(X,Y,'r','linewidth',2);             % plot community boundaries

caxis([-1 1]*.3)
y0 = 0;
yticks = [];
for i = 1:length(allnets)
    thisn = length(find(networkIDs == i));
    yticks(end+1) = round(y0 + thisn/2);
    y0 = y0 + thisn;
end
set(gca, 'YTick', yticks)
set(gca, 'YTickLabels', allnets)
set(gca, 'XTick', yticks)
set(gca, 'XTickLabels', allnets)
set(gca, 'XTickLabelRotation', 45)
set(gca, 'FontSize', 14);
set(gcf, 'color', 'w')

export_fig( sprintf('saved_data/query_%s_%s_%s_%s.jpg', study, pipeline, atlas, datestr(now, 'yyyymmdd') ), '-r600' )


close(h)

h = figure('visible', 'off')
set(gca, 'Position', [996         121        1928        1196]);
studies = unique(tbl.study);
nx = 2;
ny = ceil(length(studies)/nx);

for studyi = 1:length(studies)
	subplot(nx,ny,studyi);

	thisStudy = studies{studyi};
	idx = find(strcmp(tbl.study, thisStudy));
	meanr = nanmean(r(:,:,idx),3);

	[X,Y,INDSORT] = grid_communities(networkIDs); % call function
	imagesc(meanr(INDSORT,INDSORT));           % plot ordered adjacency matrix
	hold on;                                 % hold on to overlay community visualization
	plot(X,Y,'r','linewidth',2);             % plot community boundaries

	caxis([-1 1]*.3)
	y0 = 0;
	yticks = [];
	for i = 1:length(allnets)
	    thisn = length(find(networkIDs == i));
	    yticks(end+1) = round(y0 + thisn/2);
	    y0 = y0 + thisn;
	end
	set(gca, 'YTick', [])
	set(gca, 'XTick', [])
	set(gcf, 'color', 'w')
end

export_fig( sprintf('saved_data/query_%s_%s_%s_%s_byStudy.jpg', study, pipeline, atlas, datestr(now, 'yyyymmdd') ), '-r300' )



close(h)

h = figure('visible', 'off')

studyCorr = nan(length(studies), length(studies));

for studyi = 1:length(studies)
	idxi = find(strcmp(tbl.study, studies{studyi}));

	for studyj =  studyi+1:length(studies)
		idxj = find(strcmp(tbl.study, studies{studyj}));

	        meanrx = nanmean(r(:,:,idxi),3);
	        meanry = nanmean(r(:,:,idxj),3);

		meanrx_vec = meanrx(lowerInds);
		meanry_vec = meanry(lowerInds);

		inds = find(~isnan(meanrx_vec) & ~isnan(meanry_vec));

		[corr_r, corr_p] = corrcoef(meanrx_vec(inds), meanry_vec(inds));

		studyCorr(studyi, studyj) = corr_r(1,2);
		studyCorr(studyj, studyi) = corr_r(1,2);
	end
end

studyCorr

imagesc(studyCorr);
caxis([0 1]);
colorbar;
set(gca, 'YTick', 1:length(studies))
set(gca, 'YTickLabels', studies)
set(gca, 'XTick', 1:length(studies))
set(gca, 'XTickLabels', studies)
set(gca, 'XTickLabelRotation', 45)
set(gca, 'FontSize', 14);
set(gcf, 'color', 'w')

export_fig( sprintf('saved_data/query_%s_%s_%s_%s_studyCorr.jpg', study, pipeline, atlas, datestr(now, 'yyyymmdd') ), '-r300' )

close(h)

h = figure('visible', 'off')

studyCorrFixedN = nan(length(studies), length(studies));
minn = 1e6;
for studyi = 1:length(studies)
	idx = find(strcmp(tbl.study, studies{studyi}));
	minn = min(minn, length(idx));
end
minn = round(.8*minn);
nreps = 50;

for studyi = 1:length(studies)
        idxi = find(strcmp(tbl.study, studies{studyi}));

        for studyj =  studyi+1:length(studies)
                idxj = find(strcmp(tbl.study, studies{studyj}));

		fprintf(1, 'Correlating %s - %s\n, studies{studyi}, studies{studyj});

		for repi = 1:nreps

			i_perm = randperm(length(idxi));
			j_perm = randperm(length(idxj));

			idxi_shuf = idxi(i_perm(1:minn));
			idxj_shuf = idxj(j_perm(1:minn));

	                meanrx = nanmean(r(:,:,idxi_shuf),3);
	                meanry = nanmean(r(:,:,idxj_shuf),3);

	                meanrx_vec = meanrx(lowerInds);
	                meanry_vec = meanry(lowerInds);

	                inds = find(~isnan(meanrx_vec) & ~isnan(meanry_vec));

	                [corr_r, corr_p] = corrcoef(meanrx_vec(inds), meanry_vec(inds));
	
			allR = corr_r(1,2);

		end

                studyCorrFixedN(studyi, studyj) = mean(allR);
                studyCorrFixedN(studyj, studyi) = mean(allR);
        end
end

studyCorrFixedN

imagesc(studyCorrFixedN);
caxis([0 1]);
colorbar;
set(gca, 'YTick', 1:length(studies))
set(gca, 'YTickLabels', studies)
set(gca, 'XTick', 1:length(studies))
set(gca, 'XTickLabels', studies)
set(gca, 'XTickLabelRotation', 45)
set(gca, 'FontSize', 14);
set(gcf, 'color', 'w')

export_fig( sprintf('saved_data/query_%s_%s_%s_%s_studyCorrFixedN.jpg', study, pipeline, atlas, datestr(now, 'yyyymmdd') ), '-r300' )

close all
