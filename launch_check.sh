#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/11/27
# need to set magicCard.txt
#############################
#load some function

function compare_fn { # this is used for float point value compare
	local i=0
	# $1 = filename
	# $2 = list
	# $3 = compare var
	for m in $fn_1; do
		((i+=1))
		#echo "i=$i"
		local getV=$(grep "$(echo $m|sed -e s/"#"/"# "/g)"$ $aFile |tr -s ' ' |cut -d ' ' -f 3)
		echo "getV=$getV"
		local c=$(echo $fn_2|cut -d ' ' -f $i)
		echo "c=$c"
		local res=$(awk 'BEGIN{if ('$getV' == '$c') print 1; else print 0}')
		echo "res=$res"
		if [ $res != 1 ]; then
			flag=false
		fi
	done
}

function PDF_weight_fn {
	> tmpfile.txt
	echo -n "no find PDF=" >> tmpfile.txt
	local c
	for m in $PDFWeight; do
		count=( $(echo $m|tr '-' ' ') )
		if [ "${#count[@]}" = 2 ]; then
			local min=$(echo $m|cut -d '-' -f 1)
			local max=$(echo $m|cut -d '-' -f 2)			
			for ((i=${min}; i<=${max}; i++)); do
				c=$(grep 'PDF="'$i'"' $aFile |tr -d ' ')
				if [ -z $c ]; then					
					flag=false
					echo -n " $i" >> tmpfile.txt
				fi
			done
		else
			c=$(grep 'PDF="'$i'"' $aFile |tr -d ' ')
			if [ -z $c ]; then
				flag=false
				echo -n " $i" >> tmpfile.txt
			fi
		fi
	done
	c=$(grep "no find PDF=" tmpfile.txt |cut -d '=' -f 2)
	if [ ! -z $(echo $c|tr -d ' ') ]; then
		echo "no find PDF= $c" >> ${saveName}.txt
	fi
}

function get_mCompare_value {
	local i=0
	for i in $mCompaP; do
		mCompa=$(echo $aFile|sed -e "s:$place::g" |cut -d '_' -f $i |tr -d 'a-zA-Z')
		echo "mC=$mCompa"
		fn_1=$mList
		fn_2=$mCompa
		compare_fn   
	done		
}

#define variables
echo "Start process"

> tmpfile.txt # clear all the lines in temp. file

# define variables
place=$(grep "#place" magicCard |cut -d ':' -f 2) # read the setting in the magic card
saveName=$(grep "#save file name" magicCard |cut -d ':' -f 2|tr -d " ")  # read the setting in the magic card
SetID=$(grep "#PID" magicCard |cut -d ':' -f 2)
mList=$(grep "#mass list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass list for mass compare sys.
mCompaP=$(grep "#mass compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass compare for mass compare sys.
mwList=$(grep "#mass width list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width list for mass compare sys.
mwCompa=$(grep "#mass width compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width compare for mass compare sys.
lhaid=$(grep "lhaid" magicCard |cut -d ':' -f 2| tr -d ' ')
process=$(grep "process" magicCard |cut -d ':' -f 2| tr -d ' ')
PDFWeight=$(grep "#PDF weight" magicCard |cut -d ':' -f 2|tr -d ' '|tr '|' " ")
filename=$(find $place/j*/c*.lhe ) 
dictory=`pwd` # record where is this dictory



# check if it can find the file
if [ -z "$filename" ]; then  # test if filename is a zero length variables
	echo "can not detect the file"
	exit 1 # if there is no file, this macro will stop
fi

#build scan file
> ${saveName}.txt  # if the file already exist, clean it 
echo "save name=$saveName"

# do the check in lhe file
declare -a getV #used store the data get from lhe file
declare -i i
#declare -i length # use to collect the length of all the compare
for aFile in $filename; do
	flag=true # use for the compare state
	# setting mass check
	echo "start $aFile mass check"
	if [ ! -z $mList ]; then #check weather mList is empty or not
		get_mCompare_value
	else echo "pass the setting mass check"
	fi	
	#((length+=$i))
	#echo $length

	# setting mass width check
	echo "start $aFile mass width check"
	if [ ! -z $mwList ]; then
		fn_1=$mwList
		fn_2=$mwCompa
		compare_fn 
	else echo "pass the setting mass width check"
	fi

	# PDF weight check
	echo "start $aFile PDF weight check"
	if [ ! -z $(echo $PDFWeight |tr -d ' ') ]; then
		PDF_weight_fn
	else echo "pass the PDF weight check"	
	fi

	# defualt check (lhaid / process)
	echo "start $aFile defualt check"
	if [ ! -z $lhaid ]; then
		getLHAID=$(grep "lhaid" $aFile |cut -d '=' -f 1)
		if [ $getLHAID != $lhaid ]; then
			flag=false
		fi
	else echo "pass lhaid check"	
	fi	
	if [ ! -z $process ]; then
		getProc=$(grep ^generate $aFile |sed -e s/generate//g |tr -d ' ')
		if [ $getProc != $process ]; then 
			flag=false
		fi
	else echo "pass process check"	
	fi
	
	# see the final state of flag and print result into tmpfile
	> tmpfile.txt
	if [ $flag = true ]; then
		echo "$aFile true" >> tmpfile.txt
	else
		echo "$aFile false" >> tmpfile.txt
	fi
# output
column -t tmpfile.txt >> ${saveName}.txt
done


# check if want to run root analysis
willRoo=$(grep "#root analysis" magicCard|cut -d ':' -f 2|tr -d ' ')
if [ $willRoo = "N" ]; then
	echo "${saveName}.txt has build"
	echo "process done"
	exit 1
fi
	echo "start root analysis"
	echo "the result in root analysis" >> ${saveName}.txt
	> tmpfile.txt
	# change the mother PID in .C file
	placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #find the line we want to change
	sed -i "${placeInC}a #define motherPID ${SetID}" ./TRootLHEFParticle.C
	sed -i "${placeInC}d" ./TRootLHEFParticle.C
	# run root
	rootName=$(find $place -type f -name "$keyWord*.root")
	for b in $rootName; do
		stringP=$(grep -n string TRootLHEFParticle.h|cut -d ':' -f 1)
		sed -i ''${stringP}'a \   \string fileName = "'${b}'";' ./TRootLHEFParticle.h
		sed -i "${stringP}d" ./TRootLHEFParticle.h
		expect -c 'spawn -noecho root -l TRootLHEFParticle.C
		        send "TRootLHEFParticle t\r"
				  send "t.Loop()\r"
		        send ".q\r"
				  interact'
	# output
		ans1=$(grep "mass test" ./tmpfile.txt)
		ans2=$(grep "fail" ./tmpfile.txt)
		echo " " >> ${saveName}.txt
		echo -n " $b;" >> ${saveName}.txt
		echo -n " $ans1;" >> ${saveName}.txt
		echo -n " $ans2;" >> ${saveName}.txt
	done
	echo "${saveName}_scan.txt has build"
	echo "process done"