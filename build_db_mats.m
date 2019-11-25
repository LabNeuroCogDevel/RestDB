% build_db_mats -- build rest/ses info; save in mats/*rest.mat
% has no dependencies on sqlite
% this will take a long time. look at redo_study() for just one study
function build_db_mats()
    % see readme.txt for adding a study
    % filenames are important:
    %  expect ${study}rest_table.m and mats/${study}rest.mat

    DEBUG=0; % petrest will print lots if DEBUG=1
    % ses and rest info as matlab table
    petrest_table 
    save('mats/petrest.mat','allses','allrest')

    % 20190725 -- studies below are finished. dont need to be rerun
    % can just use the mats/*.mat file
    %return

    cogrest_table 
    save('mats/cogrest.mat','allses','allrest')

    pncrest_table 
    save('mats/pncrest.mat','allses','allrest')

    rewrest_table 
    save('mats/rewrest.mat','allses','allrest')

    ncsiemensrest_table
    save('mats/ncsiemensrest.mat','allses','allrest')

    ncgerest_table
    save('mats/ncgerest.mat','allses','allrest')

end
