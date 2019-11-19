MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
TABLESCRIPTS = $(wildcard *_table)
# petrest_table.m cogrest_table.m pncrest_table.m rewrest_table.m 
#
.PHONY: all
all: txt/alltsnr.txt
    
# NB: many of the table scripts do not need to be rerun (e.g. cog and reward are done)
#     UNLESS there are new atlases
# TODO: make rule mats/${x}.mat -> matlab "try, ${x}_table, end quit()"
.make/mats.txt: build_db_mats.m atlas_list.m ${TABLESCRIPTS}
	matlab -nodisplay -r "try, build_db_mats(), end; quit()" # mats/*.mat
	mkstat $@ 'mats/*.mat'

.make/ts4d.txt: .make/mats.txt buildDB.m
	./00_create.bash # runs buildDB.m on build_db_mats.m created mats/*.mat
	sqlite3 /Volumes/Hera/Projects/RestDB/rest.db -separator ' ' 'select ts4d from rest where  ts4d not like "%chunk%" group by ts4d order by ts4d' | mkifdiff $@

.make/tsnrdir.txt: .make/ts4d.txt 
	./gen_tsnr.bash
	sed 's:\(.*/\).*:\1tsnr/:' .make/ts4d.txt | xargs ls -d 2>/dev/null | mkifdiff $@

txt/alltsnr.txt: .make/tsnrdir.txt
	./create_gm_tsnr.bash
