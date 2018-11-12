#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/11/13
# the terminal need to be in the dictory with both .sh and genLHE.py
#############################
#define variables
echo "Start process"
keyWord=$(grep "key word" magicCard |cut -d ':' -f 2)
place=$(grep "place" magicCard |cut -d ':' -f 2)
filename=$(find $place -type f -name "$keyWord*.lhe")  # this shows more of "how to use find() "
# check if it can find the file
declare -i enters=0
for a in $filename; do
	enters=$enters+1
done
if [ $enters -eq 0 ]; then
	echo "can not detect the file"
	exit 1
fi
dictory=`pwd`
# read the setting in the magic card
# if the cut in the filename become strange, please modify this line
newName=$keyWord$(echo $filename|cut -d "_" -f 1 |cut -d $keyWord -f 2)
###################################################################
echo newName=$newName
newSetParticle=$(grep "particle name" magicCard |cut -d ':' -f 2)
newSetID=$(grep "PID" magicCard |cut -d ':' -f 2)

#produce the py file to run
sed -e 's/FOLDERNAME/'${newName}'/g' -e 's/setParticle/'${newSetParticle}'/g' -e 's/setID/'${newSetID}'/g' $dictory/genLHE > $dictory/${newName}_genLHE.py
# run the python script
python ${newName}_genLHE.py

#change the mother PID in .C file
placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #find the line we want to change
sed -i ${placeInC}'a #define motherPID '$newSetID ./TRootLHEFParticle.C
sed -i ${placeInC}d ./TRootLHEFParticle.C
#run root
rootName=$(find $place -type f -name "$keyWord*.root")
for b in $rootName; do
	sed -e 's!ROOTNAME!'${b}'!g' $dictory/res.h > ./TRootLHEFParticle.h
	expect -c 'spawn -noecho root -l TRootLHEFParticle.C
           send "TRootLHEFParticle t\r"
			  send "t.Loop()\r"
           send ".q\r"
			  interact'
	ans1=$(grep "mass test" ./tmpfile.txt)
	ans2=$(grep "fail" ./tmpfile.txt|cut -d ":" -f 2)
	sed -i "/the check/a $ans2"  ./${newName}_scan.txt
	sed -i "/the check/a $ans1" ./${newName}_scan.txt
	sed -i "/the check/a ${b}" ./${newName}_scan.txt
done


