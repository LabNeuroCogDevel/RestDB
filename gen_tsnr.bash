#!/usr/bin/env bash
mnitemp=/opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_2.3mm.nii 
sqlite3 /Volumes/Hera/Projects/RestDB/rest.db -separator ' ' \
   'select ts4d, max(study), max(preproc), max(ses_id) from rest where  ts4d not like "%chunk%" group by ts4d' | 
   #'select ts4d, max(study), max(preproc), max(ses_id) from rest where study like "pnc" and preproc like "aroma" and ts4d not like "%chunk%" group by ts4d limit 2' | 
 while read f info; do
    echo "$info"
    opts=""
    # this bit isn't strictly necessary. ppf_tsnr should skip if file exists
    [ -r $(dirname $f)/tsnr/*$(basename $f .nii.gz)*.txt ] &&  continue

    [[ $info =~ rew ]] && opts="-g /opt/ni_tools/standard/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_3mm.nii"
    # we dont need to warp, so give dummpy file (existing template)
    [[ $info =~ "cog aroma" ]] && opts="-f -t $mnitemp -w $mnitemp"  
    [[ $info =~ "pnc aroma" ]] && opts="-t $mnitemp -w $mnitemp"
    ppf_tsnr $opts -O $(basename $f) $(dirname $f)  || echo "failed on $f"
done
