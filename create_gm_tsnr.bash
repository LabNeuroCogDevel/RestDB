#!/usr/bin/env bash

#
# for all 4dts nifti in restdb, parse corresponding tsnr text files into database rows
# run after gen_tsnr.bash has created ${preproc_dir}/tsnr/*.txt
#
# running for single study also updates txt/alltsnr.txt (in addition to creating txt/${study}tsnr.txt)
#

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

roi=gm # expect all to be gray matter masked
cnt=0  # update status every 100 

sqlite3 rest.db "select ses_id, study, preproc, min(adj_file) from rest group by ses_id, study, preproc having study like '$studyquery'" |
perl -F'\|' -MFile::Basename -slane '$a{dirname($F[3])."\t$F[2]"}=join("\t",@F[0..1]); END{ print "$_\t$a{$_}" for sort keys %a}' | 
while read dname preproc ses_id study; do
   # 20191125 N.B. study and preproc get swapped!?
   [ ! -r $dname/tsnr ] && echo "$dname: no tsnr" >&2 && continue

   # reverse sort. call the last one isfinal
   isfinal=""
   for f in $(ls $dname/tsnr/*txt |sort -r); do 

      # skip this file -- created in error
      [[ $f =~ usan_size.txt ]] && continue
      tsnrval=$(awk '{print $1}' < $f)

      # skip global signal if aroma (and not aroma_gsr), and file is gsr file
      [[ $study =~ aroma$ && $f =~ 'bgr' ]] && continue

      nprefix=$(basename $f) # 11-bgrnaswdktm_func_5.txt
      step=${nprefix%-*}    # 11
      fprefix=${nprefix#*-}  # bgrnaswdktm_func_5.txt
      prefix=${fprefix%%_*}   # bgrnaswdktm

      # tsnr nifti might have a few different names
      tsnr_d="$(dirname $f)"
      tsnrnii=$tsnr_d/${fprefix/.txt/}.nii.gz_tsnr.nii.gz
      [ ! -r "$tsnrnii" ] && tsnrnii=$tsnr_d/${prefix}_tsnr.nii.gz
      [ ! -r "$tsnrnii" ] && echo "cannot read $tsnrnii" >&2 && continue

      [ -z "$isfinal" ] && isfinal=1 || isfinal=0

      # set no prefix to underscore for easier query
      [ -z "$prefix" ] && prefix="_"
      # ouptput matching order of tsnr table
      line="$ses_id,$study,$preproc,$isfinal,$roi,$prefix,$tsnrnii,$step,$tsnrval"
      echo "$line"

      # report process so we know it's not stalled
      [ $(( $cnt % 100)) -eq 0 ] && echo "[$(date)] $cnt $line" >&2
      let ++cnt || continue
   done
done > txt/${study}tsnr.txt

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

