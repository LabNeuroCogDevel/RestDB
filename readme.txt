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
