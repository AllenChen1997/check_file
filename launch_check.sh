#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/11/27
# need to set magicCard.txt
#############################
#load some function

function compare_fn { # this is used for 'float point' value compare by awk
	local i=0
	# $fn_1 = list
	# $fn_2 = compare var
	for m in $fn_1; do
		((i+=1))
		local getV=$(grep "$(echo $m|sed -e s/"#"/"# "/g)"$ $aFile |tr -s ' ' |cut -d ' ' -f 3)
		local c=$(echo $fn_2|cut -d ' ' -f $i)
		local res=$(awk 'BEGIN{if ('$getV' == '$c') print 1; else print 0}')
		if [ $res != 1 ]; then
			flag=false
		fi
	done
}

function PDF_weight_fn { # this is use to check there are these PDF id in the lhe file or not
	> tmpfile.txt # empty the tmpfile.txt
	echo -n "the list of not found PDF= " >> tmpfile.txt 
	local c
	for m in $PDFWeight; do
		count=( $(echo $m|tr '-' ' ') ) 	# make min-max become (min max)
		if [ "${#count[@]}" = 2 ]; then 	# if the count has two words -> min max form, otherwise only check one id 
			local min=$(echo $m|cut -d '-' -f 1)
			local max=$(echo $m|cut -d '-' -f 2)			
			for ((i=${min}; i<=${max}; i++)); do
				c=$(grep 'PDF="'$i'"' $aFile |tr -d ' ') 	# get the line with the PDF id
				if [ -z $c ]; then					# see if it is a empty string
					flag=false
					echo -n " $i" >> tmpfile.txt  # write the PDF id into tmpfile.txt
				fi
			done
		else
			c=$(grep 'PDF="'$m'"' $aFile |tr -d ' ')
			if [ -z $c ]; then
				flag=false
				echo -n " $m" >> tmpfile.txt
			fi
		fi
	done
	# put the result into the xxx.txt (main save file)
	c=$(grep "not found PDF=" tmpfile.txt |cut -d '=' -f 2)
	if [ ! -z $(echo $c|tr -d ' ') ]; then
		echo " the list of not found PDF= $c" >> ${saveName}.txt
	fi
}

function get_mCompare_value {  # auto get the setting mass from the name of file/ directory
	local i=0
	for i in $mCompaP; do
		mCompa=$(echo $aFile|sed -e "s:$place::g" |cut -d '_' -f $i |tr -d 'a-zA-Z')
		fn_1=$mList
		fn_2=$mCompa
		compare_fn   
	done		
}

#define variables
echo "Start process"

> tmpfile.txt # clear all the lines in temp. file

# define variables
	place=$(grep "#the place" magicCard |cut -d ':' -f 2) # read the setting in the magic card
	saveName=$(grep "#the save" magicCard |cut -d ':' -f 2|tr -d " ")  # read the setting in the magic card
	SetID=$(grep "#the mother" magicCard |cut -d ':' -f 2)
	lheName=$(grep "#name for lhe" magicCard |cut -d ':' -f 2)
	mList=$(grep "#mass list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass list for mass compare sys.
	mCompaP=$(grep "#mass compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass compare for mass compare sys.
	mwList=$(grep "#mass width list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width list for mass compare sys.
	mwCompa=$(grep "#mass width compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width compare for mass compare sys.
	lhaid=$(grep "lhaid" magicCard |cut -d ':' -f 2| tr -d ' ')
	process=$(grep "process" magicCard |cut -d ':' -f 2| tr -d ' ')
	PDFWeight=$(grep "#PDF weight" magicCard |cut -d ':' -f 2|tr -d ' '|tr '|' " ")
	filename=$(find $place -name $lheName ) 
	directory=`pwd` # record where is this directory



# check if it can find the file
	if [ -z "$filename" ]; then  # test if filename is a zero length variables
		echo "can not detect the file"
		exit 1 # if there is no file, this macro will stop
	fi

#build scan file
> ${saveName}.txt  # if the file already exist, clean it 
echo "the rusult of the lhe compare" >> ${saveName}.txt
echo "save name=$saveName"

# do the check in lhe file
declare -a getV #used store the data get from lhe file
declare -i i
#declare -i length # use to collect the length of all the compare
for aFile in $filename; do
	flag=true # use for the compare state

	# setting mass check
	if [ ! -z $mList ]; then #check weather mList is empty or not
		echo "start $aFile mass check"
		get_mCompare_value
	else echo "pass the setting mass check"
	fi	

	# setting mass width check
	if [ ! -z $mwList ]; then
		echo "start $aFile mass width check"
		fn_1=$mwList
		fn_2=$mwCompa
		compare_fn 
	else echo "pass the setting mass width check"
	fi

	# PDF weight check
	if [ ! -z $(echo $PDFWeight |tr -d ' ') ]; then
		echo "start $aFile PDF weight check"
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
	# check if want to run root analysis and run root
	willRoo=$(grep "#want" magicCard|cut -d ':' -f 2|tr -d ' '|tr 'n' 'N')
	if [ $willRoo = "N" ]; then
		continue
	fi
	echo "start $aFile root analysis"
	echo "the result of root analysis" >> ${saveName}.txt
	# change the mother PID in .C file
	placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #find the line we want to change
	sed -i "${placeInC}a #define motherPID ${SetID}" ./TRootLHEFParticle.C
	sed -i "${placeInC}d" ./TRootLHEFParticle.C
	# run root
	findRoot=$(grep "#name for root" magicCard |cut -d ':' -f 2)
	rootName=$(find $place -type f -name $findRoot)
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
		ans2=$(grep "mother" ./tmpfile.txt)
		echo " " >> ${saveName}.txt
		echo -n " $b;" >> ${saveName}.txt
		echo -n " $ans1;" >> ${saveName}.txt
		echo -n " $ans2;" >> ${saveName}.txt
	done

echo "${saveName}.txt has build"
echo "process done"
