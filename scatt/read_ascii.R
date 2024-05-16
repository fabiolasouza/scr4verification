#Function to read verification ASCII files
#read radiosonde/model files 
#read_ascii(start_date = '2023022000',
#		end_date = '2023022006',
#		fcst_model = c('ecds_v2'),
#		obs = 'TEMP',
#		path = '/ec/res4/scratch/duuw/verification/ecflow/UACGRIB',
#		param = 'T',
#		lead_time = seq(0,24,3),
#		by = 6,
#       level = seq(50, 1000, 10))
#
#read scatterometer/model files
#read_ascii(start_date = '2023022000',
#		end_date = '2023022006',
#		fcst_model = c('ecds_v2'),
#		obs = 'hscat',
#		path = '/ec/res4/scratch/nkfs/data/verif_scatterometer',
#		param = 'U10m',
#		lead_time = seq(0,24,3),
#		by = 6,
#       name_domain = 'NorthSea',
#       domain = c(55, 10, 57, 16))

read_ascii <- function(start_date, end_date, fcst_model, obs, path, param, lead_time, by, level = NULL, name_domain = NULL, domain = NULL){
        message('Parameter: ', param)
        fcst_out <- list()   
        #set parameter 
		if ({{param}} == 'S'){
		    fcst_param <- 'wsp_fcst'
			unit <- 'm/s'
		} else if ({{param}} == 'T'){
			fcst_param <- 't_fcst'
			unit <- 'K'
		} else if ({{param}} == 'Q'){
			fcst_param <- 'q_fcst'
			unit <- 'g/g'
		} else if ({{param}} == 'D'){
			fcst_param <- 'wdir_fcst'
			unit <- 'degrees'
		} else if ({{param}} == 'TD'){
			fcst_param <- 'td_fcst'
			unit <- 'K'	
		} else if ({{param}} == 'RH'){
			fcst_param <- 'rh_fcst'
			unit <- 'percent'
		} else if ({{param}} == 'U10m'){
            param_obs <- 'u10_scatt'
			fcst_param <- 'u10_harm'
			unit <- 'm/s'
		} else if ({{param}} == 'V10m'){
            param_obs <- 'v10_scatt'
			fcst_param <- 'v10_harm'
			unit <- 'm/s' 
        } else if ({{param}} == 'S10m'){
            param_obs <- 'ws_scatt'
			fcst_param <- 'ws_harm'
			unit <- 'm/s'
        } else if ({{param}} == 'D10m'){
            param_obs <- 'wdir_scatt'
			fcst_param <- 'wdir_harm'
			unit <- 'degrees'
        }     
        #read each model 
        for (model in fcst_model){
            message(model)
            df_total = data.frame()
            #create a list of dates 
            list_date <- seq(as.POSIXct(start_date, format='%Y%m%d %H'), as.POSIXct(end_date, format='%Y%m%d %H'), by=paste0(by, ' hour', sep=''))
            #define the forecast column name compatible with harp
		    model_det <-  paste(model, "_det", sep="")
            for (i in list_date){
                date <- as.POSIXct(i, origin="1970-01-01")
                year <- format(date, format='%Y')
                month <- format(date, format='%m')
                day <- format(date, format='%d')
                HH <- format(date, format='%H')
                file_list <- list.files(path = file.path(path, model, year, month, day, HH), pattern = paste0(obs,"_",sprintf("F%03d", lead_time), collapse = "|"), full.names = TRUE)
                for (i in file_list){
			        message("Reading: ", i)
		        }
                data <- lapply(file_list, read.table, header=T)
                df <- do.call(rbind, data)
                df_total <- rbind(df_total, df)
            }
		    if (is.null(level) == FALSE){
                fcst_df <- df_total[, c("fcdate", "vdate", "SID", "cycle", "leadtime", "latitude", "longitude", "P", param, paste0(fcst_param))]
		        fcst_df <- within(fcst_df, c(units <- unit))
		        fcst_df <- dplyr::rename(fcst_df, validdate = vdate, p = P, {{model_det}} := all_of(fcst_param), fcst_cycle = cycle)
                message('Reading parameter in specified levels')
                fcst_df$p <- fcst_df$p/100
                fcst_df <- subset(fcst_df, p %in% level)
                #NOTE:  poor filter to avoid duplicate rows when the radiosonde horizontal displacement is not significant. 
                        #Future this filter should be included in the script that extract the field from the model.
                fcst_df <- fcst_df[!duplicated(fcst_df[ , c("fcdate", "SID", "p")]), ] #, "validdate"
            } else {
                message('Reading surface parameter')
                fcst_df <- df_total[, c("analyses_date_time_harm", "valid_date_time_harm", "hour_scatt", "cycle", "leadtime", "lat_scatt", "lon_scatt", paste0(param_obs), paste0(fcst_param))]
                if (is.null(name_domain) == FALSE){
		    if (name_domain != "All"){
                        fcst_df = subset(fcst_df, lat_scatt >= domain[1] & lat_scatt <= domain[3] & lon_scatt >= domain[2] & lon_scatt <= domain[4])
		    }
                }
		        fcst_df <- within(fcst_df, c(units <- unit))
		        fcst_df <- dplyr::rename(fcst_df, fcdate = analyses_date_time_harm, validdate = valid_date_time_harm, SID = hour_scatt, latitude = lat_scatt, longitude = lon_scatt, {{param}} := all_of(param_obs), {{model_det}} := all_of(fcst_param), fcst_cycle = cycle)
            }
            fcst_df$fcdate <- as.POSIXct(fcst_df$fcdate, format="%Y-%m-%d %H:%M:%S")
            fcst_df$validdate <- as.POSIXct(fcst_df$validdate, format="%Y-%m-%d %H:%M:%S")
            fcst_df$fcdate <- harpIO::unix2datetime(fcst_df$fcdate)
		    fcst_df$validdate <- harpIO::unix2datetime(fcst_df$validdate)
            fcst_df <- tidyr :: drop_na(fcst_df)
		    fc <- list(tibble :: tibble(fcst_df))
            fcst_out <- append(fcst_out, fc)
        }
        names(fcst_out) <- c(fcst_model)
        fcst_out <- structure(fcst_out, class="harp_fcst")
}




   
