all: tsnr_to_db

recreate_mat:
	matlab -nodisplay -r "try, build_db_mats(), end; quit()"

# sort of depends on recreate_mat
recreate_db:
	./00_create.bash

tsnr_txt_files:
	./gen_tsnr.bash

tsnr_to_db: tsnr_txt_files
	./create_gm_tsnr.bash

.PHONY: tsnr_txt_files tsnr_to_db all recreate_db recreate_mat
