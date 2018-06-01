% mat_to_db -- put a matfile in to the db. see also study_to_db
function mat_to_db(matfile, dbcn,study)
  m=load(matfile);
  % add study
  m.allses.study = repmat({study},[height(m.allses) 1]);
  % add dx
  if ~ismember('dx',fieldnames(m.allses))
    fprintf('\tadding dx = control for all\n');
    m.allses.dx = repmat({'control'},[height(m.allses) 1]);
  end
  % remove duplicate ses ids
  i = uniqidx(m.allses,'ses_id','sessions');
  insert(dbcn,'ses',m.allses.Properties.VariableNames,m.allses(i,:) );

  % warn about not ts_file
  if ~ismember('ts_file',fieldnames(m.allrest))
    fprintf('\trest does not have ts_file column. fix in %srest_table.m and run redo_study(''%s'')\n',study,study);
    m.allrest.ts_file = repmat({'DNE'},[height(m.allrest) 1]);
  end
  
  i = uniqidx(m.allrest,'adj_file','rest runs');
  insert(dbcn,'rest',m.allrest.Properties.VariableNames,m.allrest(i,:));
end

function i=uniqidx(t,col,desc)
 [~,i] = unique(t.(col));
 uniqdif = height(t) - length(i);
 if uniqdif >0
     fprintf('removing %d duplicated %s (%s)\n',uniqdif, col, desc)
 end
  
end
