% mat_to_db -- put a matfile in to the db. see also study_to_db
function mat_to_db(matfile, dbcn,study)
  m=load(matfile);
  m.allses.study = repmat({study},[height(m.allses) 1]);
  % remove duplicate ses ids
  i = uniqidx(m.allses,'ses_id','sessions');
  insert(dbcn,'ses',m.allses.Properties.VariableNames,m.allses(i,:) );
  
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