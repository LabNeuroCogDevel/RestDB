MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
# petrest_table.m cogrest_table.m pncrest_table.m rewrest_table.m 
#
.PHONY: all
all: txt/alltsnr.txt

###########
# these rules are not explictly required anywhere. 
# they depend on study specific file locations
# can force run manually:
#   make -B txt/pettsnr.txt # would redo pet

# rest matlab structure comes from the corresponding *rest_table.m
# e.g. rewrest_table.m -> mats/rewrest.mat => rest.db: rest.ts4d, study='rew'
mats/%rest.mat: redo_study.m %rest_table.m
	matlab -nodisplay -r "try, redo_study($*), end; quit()"

# make intermatate file to incase redo doesn't add any new ts4d rows
.make/%_dbstat.txt: mats/%rest.mat
	sqlite3 rest.db -separator ' ' "select ts4d from rest where ts4d not like '%chunk%' and study like '$*' group by ts4d order by ts4d" | mkifdiff $@
# tsnr if db state has changed
txt/%tsnr.txt: .make/%_dbstat.txt
	./gen_tsnr.bash $*
	./create_gm_tsnr.bash $*
###########

    
# NB: many of the table scripts do not need to be rerun (e.g. no new scans for cog nor reward)
#     UNLESS there are new atlases
#    see above for running invidual study
.make/mats.txt: build_db_mats.m atlas_list.m $(wildcard *rest_table.m)
	matlab -nodisplay -r "try, build_db_mats(), end; quit()" # mats/*.mat
	mkstat $@ 'mats/*rest.mat'

# track all the 4d time series
.make/ts4d.txt: .make/mats.txt buildDB.m
	./00_create.bash # runs buildDB.m on build_db_mats.m created mats/*.mat
	sqlite3 /Volumes/Hera/Projects/RestDB/rest.db -separator ' ' 'select ts4d from rest where  ts4d not like "%chunk%" group by ts4d order by ts4d' | mkifdiff $@

# list all the tsnr directoires that should be stored in the DB
# NB. to generate for single study: ./gen_tsnr.bash $study
.make/tsnrdir.txt: .make/ts4d.txt 
	./gen_tsnr.bash all
	# replace ts name with tsnr: same as $(dirname $f)/tsnr
	sed 's:\(.*/\).*:\1tsnr/:' .make/ts4d.txt | xargs ls -d 2>/dev/null | mkifdiff $@

# add tsnr values to DB
# NB. to update just one study: ./create_gm_tsnr.bash $study
txt/alltsnr.txt: .make/tsnrdir.txt ./create_gm_tsnr.bash
	./create_gm_tsnr.bash all
