#!/usr/local/apps/R/4.0.4/bin/Rscript
###################################################################################
source('/home/nkfs/scr4verification/fcstScatt2sqlite.R')
fcstScatt2sqlite(fcst_model = "WFP_43h22tg3",
		start_date = "20220701",
		end_date = "20220730",
		by = 1,
		fcst=seq(0, 48, 3),
		path = "/ec/res4/scratch/nkfs/data/verif_scatterometer/hy-2b/25km",
		scatt="HSCAT",
		param = "S10m")

