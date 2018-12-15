#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/12/15
# need to set magicCard.txt, TRootLHEFParticle.C TRootLHEFParticle.h
#############################
#load some function
function fileExistCheck_fn {
	# fn_1 = file name	
	fileFind=$(find $fn_1 2> /dev/null) # check if the detail.txt is exist
	if [ ! -z $fileFind ]; then
		read -p "$fn_1 had already exist, do you want to continue? Y / N (continue will delete it): " ans
		if [ $(echo $ans |tr -d ' '|tr 'y' 'Y') != "Y" ]; then
			echo "process canceled"
			exit 1
		fi
	fi 
}

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
			echo "$m = $getV compare $c = false" >> detail.txt
		else echo "$m = $getV compare $c = true" >> detail.txt
		fi		
	done
}

function PDF_weight_fn { # this is use to check there are these PDF id in the lhe file or not
	> tmpfile.txt # empty the tmpfile.txt
	echo -n "the list of not found PDF= " >> detail.txt 
	local c
	for m in $PDFWeight; do
		local count=( $(echo $m|tr '-' ' ') ) 	# make min-max become (min max)
		if [ "${#count[@]}" -eq 2 ]; then 	# if the count has two words -> min max form -> check from min to max, otherwise only check one id 
			local min=$(echo $m|cut -d '-' -f 1)
			local max=$(echo $m|cut -d '-' -f 2)			
			for ((i=${min}; i<=${max}; i++)); do
				c=$(grep 'PDF="'$i'"' $aFile |tr -d ' ') 	# get the line with the PDF id
				if [ -z $c ]; then					# see if it is a empty string
					flag=false
					echo -n " $i" >> detail.txt  # write the PDF id into detail.txt
				fi
			done
		else
			c=$(grep 'PDF="'$m'"' $aFile |tr -d ' ')
			if [ -z $c ]; then
				flag=false
				echo -n " $m" >> detail.txt
			fi
		fi
	done
	echo "" >> detail.txt
	# put the result into the xxx.txt (main save file)
	#c=$(grep "not found PDF=" tmpfile.txt |cut -d '=' -f 2)
	#if [ ! -z $(echo $c|tr -d ' ') ]; then
	#	echo " the list of not found PDF= $c" >> ${saveName}.txt
	#fi
}

function get_mCompare_value {  # auto get the setting mass from the name of file/ directory
	local i=0
	for i in $mCompaP; do
		mCompa=$(echo $aFile|sed -e "s:$place::g" |cut -d '_' -f $i |tr -d 'a-zA-Z')
		fn_1=$mList; fn_2=$mCompa; compare_fn   
	done		
}

echo "Start process"
# define variables
	place=$(grep "#the place" magicCard |cut -d ':' -f 2) # read the setting in the magic card
	saveName=$(grep "#the save" magicCard |cut -d ':' -f 2|tr -d " ")  # read the setting in the magic card
	SetID=$(grep "#the mother" magicCard |cut -d ':' -f 2)
	lheName=$(grep "#name for lhe" magicCard |cut -d ':' -f 2)
	mList=$(grep "#mass list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass list for mass compare sys.
	mCompaP=$(grep "#mass compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass compare for mass compare sys.
	mwList=$(grep "#mass width list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width list for mass compare sys.
	lhaid=$(grep "lhaid" magicCard |cut -d ':' -f 2| tr -d ' ')
	process=$(grep "process" magicCard |cut -d ':' -f 2| tr -d ' ')
	PDFWeight=$(grep "#PDF weight" magicCard |cut -d ':' -f 2|tr -d ' '|tr '|' " ")
	filename=$(find $place -name $lheName ) # the directories to the lhe file 
	findRoot=$(grep "#name for root" magicCard |cut -d ':' -f 2)
	rootName=$(find $place -type f -name $findRoot) # the directories to the root file
	declare -i rootI; rootI=0 # used as the index of the root
	directory=`pwd` # record where is this directory

# check if it can find the file
	if [ -z "$filename" ]; then  # test if filename is a zero length variables
		echo "can not detect the lhe file"
		exit 1 # if there is no file, this macro will stop
	fi

# build scan file
fn_1="tmpfile.txt"; fileExistCheck_fn # see if the file is already exist or not
> tmpfile.txt # clear all the lines in tempfile.txt
fn_1="${saveName}.txt"; fileExistCheck_fn
> ${saveName}.txt  # if the file already exist, clean it 
fn_1="detail.txt"; fileExistCheck_fn
> detail.txt
echo "save name=$saveName"
	
# do the check in lhe file
declare -a getV #used store the data get from lhe file

for aFile in $filename; do
	flag=true # use for the compare state

	# setting mass check
	if [ ! -z $mList ]; then #check weather mList is empty or not
		echo "start $aFile mass check"
		echo "< $aFile >" >> detail.txt
		get_mCompare_value
	else echo "pass the setting mass check"
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
		getLHAID=$(grep "lhaid" $aFile |cut -d '=' -f 1|tr -d ' ')
		if [ $getLHAID != $lhaid ]; then
			flag=false
			echo "LHAID = $getLHAID compare $lhaid = false" >> detail.txt
		else echo "LHAID = $getLHAID compare $lhaid = true" >> detail.txt
		fi
	else echo "pass lhaid check"	
	fi	

	if [ ! -z $process ]; then
		getProc=$(grep ^generate $aFile |sed -e s/generate//g |tr -d ' ')
		if [ $getProc != $process ]; then 
			flag=false
			echo "Process = $getProc compare $process = false" >> detail.txt
		else echo "Process = $getProc compare $process = true" >> detail.txt
		fi
	else echo "pass process check"	
	fi
	
	# check if want to run root analysis and run root
	willRoo=$(grep "#want to" magicCard|cut -d ':' -f 2|tr -d ' '|tr 'n' 'N')
	if [ $willRoo = "N" ]; then
		continue
	fi
	# auto convert the lhe file to the root file
		exRoot=$(grep "#place" magicCard|cut -d ':' -f 2|tr -d '"')
		aRoot=$(echo $aFile| sed -e 's/.lhe/.root/g' )		
		$exRoot $aFile $aRoot

	# check root file is exist
	if [ -z "$aRoot" ]; then  # test if filename is a zero length variables
		echo "can not detect the root file, pass the root analysis"
		echo "pass the root analysis because the root file does not exist" >> detail.txt
		continue # if there is no file, this macro will stop
	fi

	echo "start root analysis in $aRoot "
	((rootI+=1))
	# change the mother PID in .C file
	placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #find the line we want to change
	sed -i "${placeInC}a #define motherPID ${SetID}" ./TRootLHEFParticle.C
	sed -i "${placeInC}d" ./TRootLHEFParticle.C

	# run root
	stringP=$(grep -n string TRootLHEFParticle.h|cut -d ':' -f 1)
	sed -i ''${stringP}'a \   \string fileName = "'${aRoot}'";' ./TRootLHEFParticle.h # change which file need to run in .h file
	sed -i "${stringP}d" ./TRootLHEFParticle.h
	expect -c 'spawn -noecho root -l TRootLHEFParticle.C
	        send "TRootLHEFParticle t\r"
			  send "t.Loop()\r"
	        send ".q\r"
			  interact'
	
	# deal with the tmpfile.txt output
	ans2=$(grep "kinetic" ./tmpfile.txt|cut -d ':' -f 2|tr -d ' ')
	ans3=$(grep "mass test" ./tmpfile.txt |cut -d ' ' -f 3)
	ans1=$(grep "there" tmpfile.txt  |cut -d '(' -f 2|cut -d '%' -f 1)
	mwCompa=$(grep "mass width" ./tmpfile.txt |cut -d '=' -f 2 |tr -d ' ') 
	if [ `echo "$ans1 > 1"|bc` -eq 1 ]; then
		flag=false
		sed -i "s/)/) > 1%: false/g" ./tmpfile.txt
	else sed -i "s/)/) < 1%: true/g" ./tmpfile.txt
	fi
	if [ $ans2 != true ]; then
		flag=false
	fi
	if [ $ans3 != true ]; then
		flag=false
	fi
	sed -i '4d' tmpfile.txt
	grep '' tmpfile.txt >> detail.txt # put all the output into detail.txt

	# setting mass width check
	if [ ! -z $mwList ]; then
		echo "start $aFile mass width check"
		fn_1=$mwList
		fn_2=$mwCompa
		compare_fn 
	else echo "pass the setting mass width check"
	fi

	# see the final state of flag and print result into tmpfile
	if [ $flag = true ]; then
		echo "$aFile true" >> ${saveName}.txt
	else
		echo "$aFile false" >> ${saveName}.txt
	fi
	echo "-----------------------------------------------" >> detail.txt
done # end loop all file
# put the data in the detail.txt into the save file and remove the detail.txt
echo " " >> ${saveName}.txt ; echo "these are the comparing detail: " >> ${saveName}.txt 
grep '' ./detail.txt >> ${saveName}.txt
rm ./detail.txt ./tmpfile.txt

echo "${saveName}.txt has build"
echo "process done"
