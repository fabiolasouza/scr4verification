#!/usr/local/apps/R/4.0.4/bin/Rscript
library(harp)
library(dplyr)
####################################INPUT###############################################
fcst_model = c("WFP_43h22tg3")
path = "/ec/res4/scratch/nkfs/data/verif_scatterometer/hy-2b/25km"
out_path = "/ec/res4/scratch/nkfs/data/verification/NL"
param = "S10m"
scatt="HSCAT"
start_date="20220701"
end_date ="20220730"
latN=55.9
latS=49
lonW=0
lonE=11
fcst=seq(0, 48,3)
########################################################################################
source('/home/nkfs/scr4verification/read_fcScatt_db.R')
fcst<- read_fcScatt_db(start_date, end_date, fcst_model, scatt, path, param, latN, latS, lonW, lonE, fcst)
fcst <- common_cases(fcst)
verify <- det_verify(fcst, param)
save_point_verif(verify, verif_path = out_path)
