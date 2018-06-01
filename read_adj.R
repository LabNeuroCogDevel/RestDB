library(dbplyr)
library(dplyr)

#
# using rest.db with R
# see restdb_example()
# USAGE:
#   source('read_adj.R')
#   restdb_query(study,atlas) %>% db_to_2dmat
#

restdb_example <- function() {
   # see aviable  studies and atalses
   restdb_info()

   # query rest db for adj matrix of pnc w/ atlas hpc...
   # only take 100 for this example
   d <- restdb_query("pnc", "hpc_pfc_brainstem_rstg")  %>%
      head(n=100)
   print("db data")
   head(d, n=2) %>% print
   # ses_id         age sex   adj_file
   # <chr>        <dbl> <chr> <chr>
   # 600009963128    10 F     /Volumes/Zeus/.....

   # turn all the results into a matrix
   # rows of roi-roi pairs, columns of ses_id
   mats <- db_to_2dmat(d)
   print("roi-roi vecs by ses_id")
   str(mats)
   # num [1:59340, 1:100]

   # put one of the roi-roi vecs back into a 2d roi by roi matrix
   m <- undo.lower(mats[, "600009963128"])
   print("single ses back as roi x roi")
   str(m)
   # num [1:345, 1:345]
}


undo.lower <- function(v) {
   # use lower tri length to get number of symc matrix nrows (n rois)
   nr <- ceiling(sqrt(8*length(v) + 1) +1) /2
   # build NA matrix
   m <- matrix(NA, nrow=nr, ncol=nr)
   # fill lowr tri
   m[lower.tri(m)] <- v
   return(m)
   # TEST:
   # m<-matrix(1:25,nrow=5)
   # mlt <- m[lower.tri(m)]
   # m2<-undo.lower(mlt)
   # all(m2[lower.tri(m2)] == mlt)
}

adj_to_lowervec <- function(f) {
  tryCatch({
    af <- as.matrix(data.table::fread(f, header=F, sep=" "))
    af <- af[lower.tri(af)]
    return(af)
  },
  error=function(e) NULL)
}

db_to_2dmat <- function(d) {
  mats <- do.call(cbind, lapply(d$adj_file, adj_to_lowervec))
  colnames(mats) <- d$ses_id
  return(mats)
}

restdb_query <- function(study, atlas,
                         dbpath="/Volumes/Hera/Projects/RestDB/rest.db"){

  # load up database and table (quick, "lazy load")
  restdb <- src_sqlite(dbpath)
  rest <- tbl(restdb, "rest")
  ses  <- tbl(restdb, "ses")

  rest %>%
   filter(study == "pnc", atlas == "GordonHarOx" ) %>%
   inner_join(ses, by="ses_id") %>%
   select(ses_id, age, sex, adj_file) %>%
   collect # store in R, no longer lazy (slow)
}

restdb_info <-function(dbpath="/Volumes/Hera/Projects/RestDB/rest.db"){
  restdb <- src_sqlite(dbpath)
  rest <- tbl(restdb, "rest")
  showme <- function(x) x%>%collect%>%unlist%>%paste(collapse=", ")%>%cat("\n")
  # get list of all studies
  cat("studies: \n\t")
  rest %>% summarise(distinct(study)) %>% showme
  # cog, pet, pnc, rew
  cat("atlases: \n\t")
  rest %>% summarise(distinct(atlas)) %>% showme
  # GordonHarOx, hpc_pfc_brainstem_rstg, hpc_apriori_atlas_11
}
