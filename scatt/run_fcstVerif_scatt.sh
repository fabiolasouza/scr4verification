#!/bin/bash -x
module load python3
module load ecmwf-toolbox/2021.08.3.0
EXP='trunk_r17057_update'
scatt="hy-2b/25km"
scatt_name="HSCAT"
input_file_harm="/ec/res4/scratch/nkfs/data"
input_file_scatt="/ec/res4/scratch/nkfs/data/scatterometer"
output_file="/ec/res4/scratch/nkfs/data/verif_scatterometer/"$scatt"/"$EXP
year="2022"
month="07"
latS=49
latN=55
lonW=0
lonE=11
analyses="00 03 06 09 12 15 18 21"
for fcst in 00000 00100 00200 00300 00400 00500 00600 00700 00800 00900 01000 01100 01200 01300 01400 01500 01600 01700 01800 01900 02000 02100 02200 02300 02400 02700 03000 03300 03600 03900 04200 04500 04800; do
	leadtime=$fcst
	for day in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
		python3 fcstVerif_scatt.py $EXP $year $month $day "${analyses}" "$fcst" $input_file_harm $input_file_scatt $output_file $scatt $scatt_name $leadtime $latS $latN $lonW $lonE 
	done
done
