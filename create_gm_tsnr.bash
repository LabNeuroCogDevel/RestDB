#!/usr/bin/env bash
roi=gm



sqlite3 rest.db 'select ses_id, study, preproc, min(adj_file) from rest group by ses_id, study, preproc' |
perl -F'\|' -MFile::Basename -slane '$a{dirname($F[3])."\t$F[2]"}=join("\t",@F[0..1]); END{ print "$_\t$a{$_}" for sort keys %a}' | 
while read dname study ses_id preproc; do
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
      tsnrnii=$(dirname $f)/${fprefix/.txt/}.nii.gz_tsnr.nii.gz
      [ ! -r $tsnrnii ] && tsnrnii=$(dirname $f)/${prefix}_tsnr.nii.gz
      [ ! -r $tsnrnii ] && echo "cannot read $tsnrnii" >&2 && continue

      [ -z "$isfinal" ] && isfinal=1 || isfinal=0

      # set no prefix to underscore for easier query
      [ -z "$prefix" ] && prefix="_"
      # ouptput matching order of tsnr table
      echo "$ses_id,$study,$preproc,$isfinal,$roi,$prefix,$tsnrnii,$step,$tsnrval"
   done
done |tee txt/alltsnr.txt

cat <<EOF  | sqlite3 rest.db 
delete from tsnr;
.mode csv
.import txt/alltsnr.txt tsnr
EOF

# check on it
sqlite3 rest.db 'select study,preproc,count(*) from tsnr  group by study,preproc limit 10 ;'
sqlite3 rest.db 'select * from tsnr order by tsnr desc limit 10;'
