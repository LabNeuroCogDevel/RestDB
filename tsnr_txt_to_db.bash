#!/usr/bin/env bash
set -euo pipefail
trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error"' EXIT

#
# add txt/alltsnr.txt or txt/${study}tsnr.txt to db
#  20191202WF  init

# copied from tsnr_gm_to_txt.bash
[ $# -ne 1 ] && echo "
USAGE: $0 all|ncsiemens|rew|...
 regenerate all tsnr rows for a study (or all studies)
" && exit 1

# figure out and check study
study=$1; shift
if [[ $study == "all" ]]; then
   studyquery="%"
else
   studies=",$(sqlite3 rest.db 'select study from rest group by study'|tr '\n' ',' )"
   ! [[ $studies =~ ,$study, ]] && echo "unknown study '$study', not in $studies" && exit 1
   studyquery="$study"
fi


# update in database
cat <<EOF  | sqlite3 rest.db 
delete from tsnr where study like '$studyquery';
.mode csv
.import txt/${study}tsnr.txt tsnr
EOF

# keep alltsnr.txt up-to-date
if [[ $study != all ]]; then
   #grep -v ",$study," txt/alltsnr.txt | sponge txt/alltsnr.txt
   cp txt/alltsnr.txt{,.bak}
   grep -v ",$study," txt/alltsnr.txt.bak > txt/alltsnr.txt
   cat txt/${study}tsnr.txt >> txt/alltsnr.txt
fi

# check on it
echo
echo "study, preproc, count:"
sqlite3 rest.db "select study,preproc,count(*) from tsnr  group by study,preproc having study like '$studyquery' limit 10 ;"
echo
echo "tsnr:"
sqlite3 rest.db "select * from tsnr where study like '$studyquery' order by tsnr, ses_id desc limit 10;"

