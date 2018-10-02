library(dbplyr)
library(dplyr)
library(RSQLite)

dbpath="/Volumes/Hera/Projects/RestDB/rest.db"

restdb <- src_sqlite(dbpath)
rest <- tbl(restdb, "rest")
ses  <- tbl(restdb, "ses")

out <- rest %>%
  filter(atlas == "GordonHarOx", preproc == "aroma_gsr" ) %>%
  inner_join(ses, by="ses_id", suffix = c(".x","")) %>%
#  select(ses_id, age, sex, fd_mean, motion_pct_cens, preproc, study, adj_file, ts_file) %>%
  collect # store in R, no longer lazy (slow)

mats <- do.call(cbind, lapply(out$adj_file, adj_to_lowervec))
#colnames(mats) <- out$ses_id

#mats <- db_to_2dmat(out)
#adj_to_lowervec <- function(f) {
#  tryCatch({
#    af <- as.matrix(data.table::fread(f, header=F, sep=" "))
#    af <- af[lower.tri(af)]
#    return(af)
#  },
#  error=function(e) NULL)
#}

#db_to_2dmat <- function(d) {
#  mats <- do.call(cbind, lapply(d$adj_file, adj_to_lowervec))
#  colnames(mats) <- d$ses_id
#  return(mats)
#}
