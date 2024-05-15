Verification framework developed as part of the MIDAS project (https://www.eumetsat.int/mesoscale-improved-data-assimilations-scatterometer-winds-midas) to access the model 10-m wind performance over the ocean against scatterometer winds.

Pre-processing (previus to harp)
1. F90 software from OSISAF/KNMI converts scatterometer BUFR to ASCII selecting the right ambiguity for each lat/lon point (https://scatterometer.knmi.nl/bufr_reader/).
2. Python script to extract model data to compare to scatterometer data (nearest neighbour) and write the output into a file in ASCII format. This script is based on 
   a software developed in the scope of Visiting-Scientists/NWPSAF (Monteiro and Vogelzang, 2019).
	- fcstVerif_scatt.py
	- run_fcstVerif_scatt.sh
	- PS: model grid: regular_ll projection
3. R scripts to read ASCII files, convert them into SQLite tables and read the tables.
	- fcstScatt2sqlite.R
	- txt2db_scatt.R
	- read_fcScatt_db.R

harp:
With 'read_fcScatt_db.R' to read SQLite tables harp functions are used to compute summary scores (point verification).
	- plot_verify_scatt.R
