# Add atlas
  0. create nii roi mask
  1. create adj files for all pipelines: e.g. /Volumes/Zeus/preproc/scripts_finn/getAllAdj_ashley_vmpfc-str-vta.sh
        -> /Volumes/Zeus/preproc/scripts_finn/cog/08_extractROIs_R.sh
        -> ROI_TempCorr.R 
  2. add atlas names to atlas_list.m
  4. run `make` (remake mat files, populate db: ./00_create.bash; calc tsnr: gen_tsnr.bash)

# Add study
 expect `${study}rest_table.m` and `mats/${study}rest.mat`

  1. create copy of a `*_table.m`
  2. add to `build_db_mats.m` and save mat into `mats/` with *rest.mat* suffix
  3. mat will be picked up by `buildDB.m`. `ses.study` derived from  mat filename sans *rest.mat* suffix

# Add/update tsnr
  1. `gen_tsnr.bash $study`       -- generate $preprocdir/tsnr/*txt files for all ts4d niftis in restdb
  2. `create_gm_tsnr.bash $study` -- parse and add row for all *txt files created ^

# LOG
20191125
  siemens+ge for ncanda with tsnr
20190107
  added atlas_list.m to list all atlases. used by *rest_table.m
20181002
  added CogEmoROIs atals (FC)
  added R `restdb_widedf` function ot get roi-roi and subject info as one wide data frame

20180628
  tsnr: add script to generate final tsnr text file for all, and script to add the value into the db
  created Makefile
  update get_rest.m to include tsnr
  (update /opt/ni_tools/fmri_processing_scripts/ppf_tsnr with -O "only this file" option)

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
