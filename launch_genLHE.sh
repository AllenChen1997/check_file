#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/10/08
# the terminal need to be in the dictory with both .sh and genLHE.py
#############################
#define variables
echo "Start process"
filename=$(find testLHEfile/ -type f -name "${1}*.lhe")  # this shows more of "how to use find() "
dictory=`pwd`
echo $dictory
echo "input file is ${filename}"
newName=$(echo $filename|cut -d "_" -f 1|cut -d "/" -f 2)
echo "newName="$newName
newSetParticle=$2
newSetID=$3
#produce the py file to run
sed -e 's/FOLDERNAME/'${newName}'/g' -e 's/setParticle/'${newSetParticle}'/g' -e 's/setID/'${newSetID}'/g' $dictory/check_file/genLHE > ${newName}_genLHE.py
# run the python script
python ${newName}_genLHE.py
