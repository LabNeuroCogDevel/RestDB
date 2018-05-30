% build_db_mats -- build rest/ses info; save in mats/*rest.mat
% has no dependencies on sqlite
% this will take a long time. look at redo_study() for just one study
function build_db_mats()
    % ses and rest info as matlab table
    cogrest_table 
    save('mats/cogrest.mat','allses','allrest')

    petrest_table 
    save('mats/petrest.mat','allses','allrest')

    pncrest_table 
    save('mats/pncrest.mat','allses','allrest')

    rewrest_table 
    allses.age = cellfun(@(x) x(1), allses.age);
    save('mats/rewrest.mat','allses','allrest')

end