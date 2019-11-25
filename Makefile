MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
# petrest_table.m cogrest_table.m pncrest_table.m rewrest_table.m 
#
.PHONY: all
all: txt/alltsnr.txt
    
# NB: many of the table scripts do not need to be rerun (e.g. cog and reward are done)
#     UNLESS there are new atlases
# TODO: make rule mats/${x}rest.mat: ${x}rest_table -> matlab "try, redo_study(${x}), end quit()"
#
.make/mats.txt: build_db_mats.m atlas_list.m $(wildcard *rest_table.m)
	matlab -nodisplay -r "try, build_db_mats(), end; quit()" # mats/*.mat
	mkstat $@ 'mats/*rest.mat'

# track all the 4d time series
.make/ts4d.txt: .make/mats.txt buildDB.m
	./00_create.bash # runs buildDB.m on build_db_mats.m created mats/*.mat
	sqlite3 /Volumes/Hera/Projects/RestDB/rest.db -separator ' ' 'select ts4d from rest where  ts4d not like "%chunk%" group by ts4d order by ts4d' | mkifdiff $@

# list all the tsnr directoires that should be stored in the DB
.make/tsnrdir.txt: .make/ts4d.txt 
	./gen_tsnr.bash
	# replace ts name with tsnr: same as $(dirname $f)/tsnr
	sed 's:\(.*/\).*:\1tsnr/:' .make/ts4d.txt | xargs ls -d 2>/dev/null | mkifdiff $@

# add tsnr values to DB
txt/alltsnr.txt: .make/tsnrdir.txt ./create_gm_tsnr.bash
	./create_gm_tsnr.bash all
