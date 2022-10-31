#############################################################################
# script to read the ASCII files containing scatterometer and model data
# and save the data with harp template.
#NOTE: The hour of scatterometer overpass the domain is temporarily named SID
##############################################################################
#example
#fcstScatt2sqlite(fcst_model = "WFP_43h22tg3",
#	start_date = "20220701",
#	end_date = "20220702",
#	by = 1,
#	fcst=seq(0, 24, 12),
#	path = "/ec/res4/scratch/nkfs/data/verif_scatterometer/hy-2b/25km",
#	scatt="HSCAT",
#	param = "U10m")
#############################################
fcstScatt2sqlite <- function(fcst_model, start_date, end_date, by, fcst, path, scatt, param){
	# sequance of dates to make a list of files
	start_date <- as.Date(start_date, format = "%Y%m%d")
	end_date <- as.Date(end_date, format = "%Y%m%d")
	all_dates <- seq(start_date, end_date, by)
	all_dates <- format(all_dates,"%Y%m%d")
	# make a list with ascii files
	list_files <- list.files(path =file.path(path, fcst_model), pattern = paste0(all_dates, collapse= "|"), full.names = TRUE)
	# Read all files
	data <- lapply(list_files, read.table, header=T)
	df <- do.call(rbind, data)
	df <- subset(df, leadtime %in% fcst)
	# define the output file name
	model_save <- paste("HA_", {{scatt}}, "_", {{param}}, "_", {{fcst_model}}, ".sqlite", sep="")
	# define the forecast column name as harp reads it
	model_det <-  paste({{fcst_model}}, "_det", sep="")
	#Select parameter to write an sqlite file
	if ({{param}} == 'S10m'){
		s10m <- df[, c("analyses_date_time_harm", "valid_date_time_harm", "hour_scatt", "leadtime", "lat_scatt", "lon_scatt", "u10_scatt", "v10_scatt", "u10_harm", "v10_harm")]
		s10m_scatt <- sqrt(s10m$u10_scatt **2 + s10m$v10_scatt ** 2)
		s10m_exp <- sqrt(s10m$u10_harm **2 + s10m$v10_harm ** 2)
		# add columns to the dataframe 
		s10m <- within(s10m, c(S10m_scatt <- s10m_scatt, S10m_exp <- s10m_exp, units <- "m/s"))
		s10m <- s10m[, c("analyses_date_time_harm", "valid_date_time_harm", "hour_scatt", "leadtime", "lat_scatt", "lon_scatt", "S10m_scatt", "S10m_exp", "units")]
		# rename the columns as harp reads
		s10m <- dplyr::rename(s10m, fcdate = analyses_date_time_harm, validdate = valid_date_time_harm, SID = hour_scatt, {{param}} := S10m_scatt, {{model_det}} := S10m_exp)
		s10m$fcdate <- as.POSIXct(s10m$fcdate, format="%Y-%m-%d %H:%M:%S")
                s10m$validdate <- as.POSIXct(s10m$validdate, format="%Y-%m-%d %H:%M:%S")
		# save the output
		message("Writing :", file.path(path, fcst_model, model_save))
		con <- DBI::dbConnect(RSQLite::SQLite(), file.path(path, fcst_model, model_save))
		DBI::dbWriteTable(con, 'SCATT_FCST', s10m, overwrite = TRUE)
		DBI::dbDisconnect(con)
		} else if ({{param}} == 'U10m'){
		u10m <- df[, c("analyses_date_time_harm", "valid_date_time_harm", "hour_scatt", "leadtime", "lat_scatt", "lon_scatt", "u10_scatt","u10_harm")]
		u10m <- within(u10m, c(units <- "m/s"))
		u10m <- dplyr::rename(u10m, fcdate = analyses_date_time_harm, validdate = valid_date_time_harm, SID = hour_scatt, {{param}} := u10_scatt, {{model_det}} := u10_harm)
		u10m$fcdate <- as.POSIXct(u10m$fcdate, format="%Y-%m-%d %H:%M:%S")
		u10m$validdate <- as.POSIXct(u10m$validdate, format="%Y-%m-%d %H:%M:%S")
		message("Writing :", file.path(path, fcst_model, model_save))
		con <- DBI::dbConnect(RSQLite::SQLite(), file.path(path, fcst_model, model_save))
		DBI::dbWriteTable(con, 'SCATT_FCST', u10m, overwrite = TRUE)
		DBI::dbDisconnect(con)
		} else if ({{param}} == 'V10m'){
		v10m <- df[, c("analyses_date_time_harm", "valid_date_time_harm", "hour_scatt", "leadtime", "lat_scatt", "lon_scatt", "v10_scatt","v10_harm")]
		v10m <- within(v10m, c(units <- "m/s"))
		v10m <- dplyr::rename(v10m, fcdate = analyses_date_time_harm, validdate = valid_date_time_harm, SID = hour_scatt, {{param}} := v10_scatt, {{model_det}} := v10_harm)
		v10m$fcdate <- as.POSIXct(v10m$fcdate, format="%Y-%m-%d %H:%M:%S")
                v10m$validdate <- as.POSIXct(v10m$validdate, format="%Y-%m-%d %H:%M:%S")
		message("Writing :", file.path(path, fcst_model, model_save))
		con <- DBI::dbConnect(RSQLite::SQLite(), file.path(path, fcst_model, model_save))
		DBI::dbWriteTable(con, 'SCATT_FCST', v10m, overwrite = TRUE)
		DBI::dbDisconnect(con)}
}
