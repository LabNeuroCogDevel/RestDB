% redo_study -- generate new mats/*rest.mat and reenter into db
% USAGE: redo_study('cog') 
%   1. runs cogrest_table
%   2. saves mats/cogrest.mat
%   3. adds cog ses and rest to rest.db (using study_to_db -> mat_to_db)
function redo_study(study)
    script=[study 'rest_table.m'];
    outfile=['mats/' study 'rest.mat'];
    if ~exist(script,file)
        error('no script for %s: %s',study,script)
    end
    %% run creation script and save output
    run(script)
    save(outfile,'allses','allrest')
    
    %% add to db
    dbcn = sqlite('rest.db');
    study_to_db(dbcn,study);
    close(dbcn)
end