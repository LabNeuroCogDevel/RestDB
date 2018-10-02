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
echo "NOT RUNNING:   matlab -nodisplay -r \"try, build_db_mats(), end; quit()\""
matlab -nodisplay -r "try, buildDB, end; quit()"
