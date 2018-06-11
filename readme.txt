20180611 
  working R query helper: 
    source('read_adj.R')
    restdb_query(study='pnc',atlas='GordonHarOx') %>% head(10) %>% db_to_2dmat

20180530 
  add matlab helpers, cleaned up schema
    - get_rest -- fetch rest info optionally with sql query where statement
    - get_ses  -- fetch ses  info optionally with sql query where statement

  REDO
   * single
    - redo_study('cog') -- redo mat/cogrest.mat, remove and reenter into db
   * ALL
    - build_db_mats  -- regnerate all mat/*rest.mat
    - buildDB        -- put all mats into database
     also see 00_create.bash

   mat file generators. each create tables 'allses' and 'allrest'
    - petrest_table.m
    - pncrest_table.m
    - cogrest_table.m
    - rewrest_table.m
 
20180529 FC WF
  create:
    sqlite3 rest.db < schema.sql
  
  matlab: https://www.mathworks.com/help/database/ug/sqlite.html
     dbcn = sqlite('/Volumes/Hera/Projects/RestDB/rest.db')
     % insert
     insert(dbcn,'ses',{'ses_id','age','sex'}, {'ses_id','9999_19001231','age',99.9,'sex','M'})
     % query
     cur = exec(dbcn,'select * from rest natural join ses')
     cur.fetch(cur)
     dt = cur.Data
