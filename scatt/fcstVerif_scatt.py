#!-*-coding:utf8-*-
#########################################################################
#	Script to read model grib files (grid regular_ll) and           # 
#       scatterometer data to extract files       			# 
#	used in the statistical verification over the ocean. 		#
#	Ref: https://scikit-learn.org/stable/modules/generated/		#
#			sklearn.neighbors.BallTree.html			#
#	     https://jakevdp.github.io/blog/2013/04/29/		        #
#		    benchmarking-nearest-neighbor-searches-in-python/   #   
#########################################################################
import xarray as xr 
import numpy as np
import pandas as pd
from sklearn.neighbors import BallTree
import datetime
import sys
import os
##################################################################
try:
	EXP = sys.argv[1]
	year = sys.argv[2]
	month = sys.argv[3]
	day = sys.argv[4]
	analyses = sys.argv[5]
	fcst = sys.argv[6]
	input_file_harm = sys.argv[7]
	input_file_scatt = sys.argv[8]
	output_file = sys.argv[9]
	scatt = sys.argv[10]
	scatt_name = sys.argv[11]
	leadtime = sys.argv[12]
	latS = sys.argv[13]
	latN = sys.argv[14]
	lonW = sys.argv[15]
	lonE = sys.argv[16]
	model_file = sys.argv[17]
except:
        print("Insert the arguments EXP year month days analyses fcst input_file_harm input_file_scatt output_file scatt scatt_name")
        raise TypeError("Incomplete arguments!!")
#days = days.split()
analyses = analyses.split()
####################################################################
#create an empty dataframe to receive the data resulting from the search for the nearest neighbor 
output=pd.DataFrame(columns=['date_scatt', 'hour_scatt', 'lat_scatt', 'lon_scatt', 'ws_scatt', 'wdir_scatt', 'u10_scatt', 'v10_scatt', 'analyses_date_time_harm', 
							'valid_date_time_harm','lat_harm', 'lon_harm', 'ws_harm', 'wdir_harm', 'u10_harm', 'v10_harm', 'leadtime', 'cycle'])
#start of pre-processing considering each day and DA cycle
#for day in days:
for HH in analyses:
	Harmonie_path = '{}/{}/{}/{}/{}/{}'.format(input_file_harm, EXP, year, month, day, HH)
	file_harm = model_file.replace('HH', HH)
	print('Harmonie_file_path: ', '{}/{}'.format(Harmonie_path,file_harm))
	data_harm_ws = xr.open_dataset('{}/{}'.format(Harmonie_path, file_harm), engine='cfgrib', backend_kwargs={'filter_by_keys':{'stepType':'instant','typeOfLevel':'heightAboveGround', 'shortName':'ws'}, 'indexpath': ''})
	data_harm_wdir = xr.open_dataset('{}/{}'.format(Harmonie_path, file_harm), engine='cfgrib', backend_kwargs={'filter_by_keys':{'stepType':'instant','typeOfLevel':'heightAboveGround', 'shortName':'wdir'}, 'indexpath': ''})
	analyses_date_time_harm = data_harm_ws['time'].values #analyses date and time 
	valid_date_time_harm = pd.to_datetime(data_harm_ws['valid_time'].values, format='%Y%m%d%H%M') #forecats valid time,  e.g. fc_wsp2020020803+024grib_fp correspond to 2020-02-09 at 03UTC
	print('analyses_date_time_harm: ', analyses_date_time_harm, 'valid_date_time_harm: ', valid_date_time_harm)
	lat_harm = data_harm_ws['latitude'].values
	lon_harm = data_harm_ws['longitude'].values
	ws_harm = data_harm_ws['ws'].values
	wdir_harm = data_harm_wdir['wdir'].values
#correspondent date in scatt file
	date = valid_date_time_harm.isoformat().replace("-", "")
	date_file_scatt = date.split("T")[0]
#time restiction
	time1 = valid_date_time_harm - datetime.timedelta(minutes=30)
	time2 = valid_date_time_harm + datetime.timedelta(minutes=30)
#open scatterometer file
	scatt_path = '{}/{}'.format(input_file_scatt,scatt)
	scatt_file = '{}_u10m_{}.txt'.format(scatt_name, date_file_scatt)
	print('Scatt_file_path:', '{}/{}'.format(scatt_path, scatt_file))
	scatt_file_size = os.path.getsize('{}/{}'.format(scatt_path, scatt_file))
	if scatt_file_size == 0:
		print('scatt_file is EMPTY')
	else:
		print('scatt_file is OK')
		data_scatt = pd.read_csv('{}/{}'.format(scatt_path, scatt_file), sep='\s+', header=None,skiprows=[0], converters={2:str, 3:str}, low_memory=False, error_bad_lines=False)
		data_scatt = data_scatt.where((data_scatt[0] > float(latS)) & (data_scatt[0] < float(latN)) & (data_scatt[1] > float(lonW)) & (data_scatt[1] < float(lonE)))
		data_scatt.dropna(subset = [0], inplace=True)
		date_scatt = data_scatt[2]
		time_scatt = data_scatt[3]
		date_time_scatt = data_scatt[2]+data_scatt[3]
		date_time_scatt = pd.to_datetime(date_time_scatt)
		data_scatt.index = date_time_scatt #adding date_time_scatt as index
		slice_data_scatt = data_scatt.loc[time1:time2,:] #1st slice data_scatt considering only date_time_scatt closer to valid_date_time_harm 
#check if the 1st slice data_scatt file is empty
		if slice_data_scatt.empty:
			print('slice_data_scatt is EMPTY -> there are no times to do the 1st slice')
		else:
			print('slice_data_scatt is OK!')
			lat_scatt = slice_data_scatt[0].values
			lon_scatt = slice_data_scatt[1].values
#convert degrees to radians and write lat/lon as vectors
			bt = BallTree(np.deg2rad(np.c_[lat_harm.flatten(),lon_harm.flatten()]), metric='haversine')
#takes distance between harm and scatt points (distances assuming a sphere of radius 1)
			distances, indices = bt.query(np.deg2rad(np.c_[lat_scatt[:], lon_scatt[:]]))
#convert distances on the earth in km multiply by radius = 6371km
			distances_km=distances*6371
#consider only points that the distances between harm and scatt are less than 2.5km 
			distances_valid = distances_km[distances_km<2.5]
			print('Number of points satisfying the distance condition in the {}+{}:'.format(HH, fcst), len(distances_valid))
#takes correspondent indices
			indices_valid = indices[distances_km<2.5]
#Convert flattened index to multidimensional indexs (harm)
			index_harm = np.unravel_index(indices_valid, lon_harm.shape)
#shape iqual to scatt shape
			distances_km = distances_km[:,0]
#takes scatt lat/lon and ws/wdir in accord with distances_km 
			slice_data_scatt_valid = slice_data_scatt[distances_km<2.5]
			slice_data_scatt_valid = slice_data_scatt_valid.rename(columns={2:'date_scatt', 3:'hour_scatt', 0:'lat_scatt', 	1:'lon_scatt', 4:'ws_scatt', 5:'wdir_scatt'})
			ws_scatt = slice_data_scatt_valid['ws_scatt'].values
			wdir_scatt = slice_data_scatt_valid['wdir_scatt'].values
			u10_scatt = ws_scatt * np.cos(np.pi*(-90-wdir_scatt)/180.)
			v10_scatt = ws_scatt * np.sin(np.pi*(-90-wdir_scatt)/180.)
			#slice_data_scatt_valid = slice_data_scatt_valid[['date_scatt', 'hour_scatt', 'lat_scatt', 'lon_scatt', 'ws_scatt', 'wdir_scatt']]
			slice_data_scatt_valid = slice_data_scatt_valid.assign(u10_scatt = u10_scatt, v10_scatt = v10_scatt)
#takes harm lat/lon and u/v in accord with distances_km
			lat_harm_valid=(lat_harm[index_harm])
			lon_harm_valid=(lon_harm[index_harm])
			ws_harm_valid = ws_harm[index_harm]
			wdir_harm_valid = wdir_harm[index_harm]
			u10_harm_valid = ws_harm_valid * np.cos(np.pi*(-90-wdir_harm_valid)/180.)
			v10_harm_valid = ws_harm_valid * np.sin(np.pi*(-90-wdir_harm_valid)/180.)
#add harmonie data in slice_data_scatt_valid DataFrame
			data_valid=slice_data_scatt_valid.assign(analyses_date_time_harm=analyses_date_time_harm, valid_date_time_harm=valid_date_time_harm, lat_harm=lat_harm_valid, lon_harm=lon_harm_valid, ws_harm= ws_harm_valid, wdir_harm= wdir_harm_valid, u10_harm=u10_harm_valid, v10_harm=v10_harm_valid, leadtime=leadtime, cycle=HH)
			output=output.append(data_valid)
#save the file in the correct directory
output.to_csv('{}/HA_{}_F{}_{}{}{}{}.txt'.format(output_file, scatt_name, fcst, EXP, year, month, day), sep=' ', index=None, float_format='%.4f')
print('Tea!')
