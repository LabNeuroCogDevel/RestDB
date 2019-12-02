#!/usr/bin/env bash

#
# reset the database
#

set -e
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

cd $(dirname $0)
# recreate
[ -e rest.db ] && rm rest.db 
sqlite3 rest.db < schema.sql
chmod g+w rest.db

# might need to regenerate mat/*rest.mat files first (slow!)
#echo "NOT RUNNING:   matlab -nodisplay -r \"try, build_db_mats(), end; quit()\"" # actually run in buildDB
matlab -nodisplay -r "try, buildDB(1),catch e, disp(e), end; quit()"

# check whats going on
sqlite3 rest.db 'select count(*), study from rest group by study'
sqlite3 rest.db 'select ts4d from rest where study like "pet"'|cut -f 5 -d/|sort|uniq -c
# sqlite3 rest.db 'select ses_id, atlas, substr(ts4d,65) from rest where study like "pet" and ses_id like "10195_20160317" order by ses_id, atlas,ts4d'
