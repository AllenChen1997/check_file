#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/11/27
# need to set magicCard.txt
#############################
#define variables
echo "Start process"

> tmpfile.txt # clear all the lines in temp. file
# define variables
keyWord=$(grep "#key word" magicCard |cut -d ':' -f 2)  # read the setting in the magic card
place=$(grep "#place" magicCard |cut -d ':' -f 2) # read the setting in the magic card
SetParticle=$(grep "#particle name" magicCard |cut -d ':' -f 2)
SetID=$(grep "#PID" magicCard |cut -d ':' -f 2)
list=$(grep "#list:" magicCard |cut -d ':' -f 2)
declare -i length
length=$(grep "#list length" magicCard |cut -d ':' -f 2|tr -d " ")
compare=$(grep "#compare" magicCard |cut -d ':' -f 2 |tr -d ' ' |sed -e s/"|"/" "/g)
filename=$(find $place -type f -name "$keyWord*.lhe")  # this shows more of "how to use find() "
dictory=`pwd` # record where is this dictory
declare -a getV

# check if it can find the file
if [ -z "$filename" ]; then  # test if filename is a zero length variables
	echo "can not detect the file"
	exit 1 # if there is no file, this macro will stop
fi

#build scan file
# if the cut in the filename become strange, please modify this line
newName=$keyWord$(echo $filename|cut -d "_" -f 1 |cut -d $keyWord -f 2)
###################################################################
echo newName=$newName

# do the check in lhe file
for aFile in $filename; do
	# check_list
	getLHAID=$(grep "lhaid" $aFile |cut -d '=' -f 1)
	#echo $getLHAID >> ${newName}_scan.txt
	getProc=$(grep ^generate $aFile |sed -e s/generate//g |tr -d ' ')
	#echo $getProc >> ${newName}_scan.txt	
	getWh=$(grep wh$ $aFile |tr ' ' '!' |cut -d '!' -f 3)
	#echo $getWh >> ${newName}_scan.txt	
	getV=(0 $getLHAID $getProc $getWh)
	flag=true
	for ((c=1; c<=$length; c++)); do
		if [ ${getV[c]} != $(echo $compare|cut -d " " -f $c) ]; then 
			flag=false
		fi
	done
	if [ $flag = true ]; then
		echo "$aFile true" >> tmpfile.txt
	fi
done

# output
> ${newName}_scan.txt
echo $list >> ${newName}_scan.txt
column -t tmpfile.txt >> ${newName}_scan.txt

#change the mother PID in .C file
#placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #find the line we want to change
#sed -i ${placeInC}'a #define motherPID '$newSetID ./TRootLHEFParticle.C
#sed -i ${placeInC}d ./TRootLHEFParticle.C
#run root
#rootName=$(find $place -type f -name "$keyWord*.root")
#for b in $rootName; do
#	sed -e 's!ROOTNAME!'${b}'!g' $dictory/res.h > ./TRootLHEFParticle.h
#	expect -c 'spawn -noecho root -l TRootLHEFParticle.C
 #          send "TRootLHEFParticle t\r"
	#		  send "t.Loop()\r"
    #       send ".q\r"
		#	  interact'
	#ans1=$(grep "mass test" ./tmpfile.txt)
	#ans2=$(grep "fail" ./tmpfile.txt|cut -d ":" -f 2)
	#sed -i "/the check/a $ans2"  ./${newName}_scan.txt
	#sed -i "/the check/a $ans1" ./${newName}_scan.txt
	#sed -i "/the check/a ${b}" ./${newName}_scan.txt
#done
