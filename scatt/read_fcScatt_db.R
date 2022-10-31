#Function to read data from sqlite file containing scatterometer and forecast data
#read_fcScatt_db(start_date = '2022-07-01',
#		end_date = '2022-07-30',
#		fcst_model = 'trunk_r17057_update',
#		scatt = 'HSCAT',
#		path = '/ec/res4/scratch/nkfs/data/verif_scatterometer/hy-2b/25km',
#		param = 'S10m',
#		latN=55.9,
#		latS=49,
#		lonW=0,
#		lonE=11,
#		fcst=seq(0,12,6))
#TODO: query by dates
read_fcScatt_db <- function(start_date, end_date, fcst_model, scatt, path, param, latN, latS, lonW, lonE, fcst){
        message("Parameter: ", param)
        fcst_out <- list()
        file_list <- file.path(path, fcst_model, paste('HA_', {{scatt}}, '_', {{param}},'_', {{fcst_model}}, '.sqlite', sep=''))
        for (file in file_list) {
                message("Reading: ",file )
		#start_date <- julian(as.Date(paste(start_date)))
		#end_date <- julian(as.Date(paste(end_date)))
                con <- DBI::dbConnect(RSQLite::SQLite(), file, flags = RSQLite::SQLITE_RO, synchronous = NULL)
                df <- DBI::dbGetQuery(con, 'SELECT * FROM SCATT_FCST WHERE lat_scatt<= ? AND lat_scatt>= ? AND lon_scatt>= ? AND lon_scatt<= ?', params<-list(latN, latS, lonW, lonE))
		df$fcdate <- harpIO::unix2datetime(df$fcdate)
		df$validdate <- harpIO::unix2datetime(df$validdate)
		df <- subset(df, leadtime %in% fcst)
                df <- tidyr :: drop_na(df)
		fcst <- list(tibble :: tibble(df))
                fcst_out <- append(fcst_out, fcst)
                DBI::dbDisconnect(con)
        }
        names(fcst_out) <- c(fcst_model)
        fcst_out <- structure(fcst_out, class="harp_fcst")
        fcst_out
}

