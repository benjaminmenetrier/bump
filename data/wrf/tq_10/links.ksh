#!/bin/ksh
# ----------------------------------------------------------------------
# Korn shell script: wrf/tq_10/links.ksh
# Author: Benjamin Menetrier
# Licensing: this code is distributed under the CeCILL-C license
# Copyright © 2017 METEO-FRANCE
# ----------------------------------------------------------------------

# Link members
i=1
typeset -RZ4 i
while [[ ${i} -le 250 ]] ; do
   ln -sf ../../../../../data/WRF/tq_10/wrf_en${i}.nc ens1_${i}.nc
   ln -sf ../../../../../data/WRF/tq_10_lr/wrf_en${i}.nc ens2_${i}.nc
   let i=i+1
done

# Generate grid.nc with ncks and ncwa
ORIGIN_FILE="ens1_0001.nc"
rm -f grid.nc
ncks -O -v XLONG,XLAT ${ORIGIN_FILE} grid.nc
ncwa -O -v PB -a Time,south_north,west_east ${ORIGIN_FILE} pressure.nc
ncks -A -v PB pressure.nc grid.nc
rm -f pressure.nc
