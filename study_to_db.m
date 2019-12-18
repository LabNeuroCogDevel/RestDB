% study_to_db -- remove and (re-)insert a study into the database
%                uses mat_to_db

function study_to_db(dbcn,study)
  %% find mat file representing study
  f=['mat/' study 'rest.mat'];
  if ~exist(f,'file')
      error('cannot find study file %s\n',f)
  end
  
  %% remove study from table
  rmstudy = @(table) ...
      sprintf('delete from %s where study like "%s"',table, study);
  
  exec(dbcn,rmstudy('ses'));
  exec(dbcn,rmstudy('rest'));
  
  %% add back
  mat_to_db(f,dbcn,study)
end
