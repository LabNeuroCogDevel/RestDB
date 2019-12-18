#!/usr/bin/env bash

#
# generate ${preproc_dir}/tsnr/*txt files for all ts4d niftis in restdb
# run tsnr_gm_to_txt.bash after

[ $# -ne 1 ] && echo "USAGE: $0 all|rew|cog|ncsiemens|etc" >&2 && exit

RESTDB="/Volumes/Hera/Projects/RestDB/rest.db"

# figure out and check study
study=$1; shift
if [[ $study == "all" ]]; then
   studyquery="%"
else
   studies=",$(sqlite3 $RESTDB 'select study from rest group by study'|tr '\n' ',' )"
   ! [[ $studies =~ ,$study, ]] && echo "unknown study '$study', not in $studies" && exit 1
   studyquery="$study"
fi

i=0 # status updates printed to terminal every 500 ts4d files
sqlite3 $RESTDB -separator ' ' \
   "select ts4d, max(study), max(preproc), max(ses_id)
   from rest r
   natural left join tsnr t
   where
   ts4d not like '%chunk%' and
   study like '$studyquery' and
   tsnr is null
   group by ts4d" | 
   # 'select ts4d, max(study), max(preproc), max(ses_id) from rest where  ts4d like "%ncanda%" group by ts4d' | 
   #'select ts4d, max(study), max(preproc), max(ses_id) from rest where study like "pnc" and preproc like "aroma" and ts4d not like "%chunk%" group by ts4d limit 2' | 
 while read f info; do
    # print updates only occastionally
    let ++i
    [ $(( $i % 500)) -eq 0 ] && echo "$i $info"

    opts=""
    # this bit isn't strictly necessary. ppf_tsnr should skip if file exists
    [ -r $(dirname $f)/tsnr/*$(basename $f .nii.gz)*.txt ] &&  continue
    Rext=$(3dinfo -Rextent $f)
    case $Rext in
       -95.4*) std_dir=/opt/ni_tools/standard_old;;
       -96.0*) std_dir=/opt/ni_tools/standard;;
       *) echo "unknown Rextend ($Rext) for file $f. not sure if should use current or old standard mni template"; continue;;
    esac
    echo "f: $f R: $Rext f: $std_dir i: $info"

    # rew and ncanda are 3mm, others are 2.3
    [[ $info =~ rew|ncsiemen|ncge ]] && res=3 || res=2.3

    mnitemp=$std_dir/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_${res}mm.nii 
    gm_mask=$std_dir/mni_icbm152_nlin_asym_09c/mni_icbm152_gm_tal_nlin_asym_09c_${res}mm.nii

    opts="-g $gm_mask -t $mnitemp"
    #[[ $info =~ rew ]] && opts="-g $gm_mask -t $mnitemp"

    # we dont need to warp, so give dummpy file (existing template)
    # `-w` option placates ppf_tsnr's checks, but is not used
    [[ $info =~ "cog aroma" ]] && opts="-f -t $mnitemp -w $mnitemp -g $gm_mask"  
    [[ $info =~ "pnc aroma" ]] && opts="-t $mnitemp -w $mnitemp -g $gm_mask"
    ppf_tsnr $opts -O $(basename $f) $(dirname $f)  || echo "failed on $f"
done
