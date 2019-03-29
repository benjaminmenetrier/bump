#!/bin/ksh
#----------------------------------------------------------------------
# Korn shell script: clean
# Author: Benjamin Menetrier
# Licensing: this code is distributed under the CeCILL-C license
# Copyright © 2015-... UCAR, CERFACS, METEO-FRANCE and IRIT
#----------------------------------------------------------------------


# Clean temporary files
echo '--- Clean temporary files'
cd ..
find . -type f -name '*~' -delete
cd script

# Remove blanks at end of lines
echo '--- Remove blanks at end of lines'
cd ../src
source=`find . -type f -exec egrep -l " +$" {} \;`
for file in ${source} ; do
   sed -i 's/ *$//' ${file}
done
cd ../standalone
source=`find . -type f -exec egrep -l " +$" {} \;`
for file in ${source} ; do
   sed -i 's/ *$//' ${file}
done
cd ../script
source=`find . -type f -exec egrep -l " +$" {} \;`
for file in ${source} ; do
   if test "${file}" != "namelist.sqlite" ; then
      sed -i 's/ *$//' ${file}
   fi
done
cd ../ncl/script
source=`find . -type f -exec egrep -l " +$" {} \;`
for file in ${source} ; do
   sed -i 's/ *$//' ${file}
done
cd ${HOME}/code/ufo-bundle/oops/src/oops/generic/bump
source=`find . -type f -exec egrep -l " +$" {} \;`
for file in ${source} ; do
   sed -i 's/ *$//' ${file}
done
