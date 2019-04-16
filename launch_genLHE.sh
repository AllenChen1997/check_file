#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/10/08
#############################
#define variables
echo "Start process"
filename=$(find testLHEfile/ -type f -name "${1}*.lhe")  # this shows more of "how to use find() "
dictory=`pwd`
echo $dictory
echo "input file is ${filename}"
newName=$(echo $filename|cut -d "_" -f 1|cut -d "/" -f 2)
echo "newName="$newName

#produce the py file to run
sed -e 's/FOLDERNAME/'${newName}'/g' $dictory/genLHE > $dictory/${newName}_genLHE.py
# run the python script
python $dictory/${newName}_genLHE.py
