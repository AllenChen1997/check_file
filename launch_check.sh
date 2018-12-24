<<<<<<< HEAD
This file is use to modify the strings in python script
the options will look like "#option: value", and only modify the words after the ":"
if you let the options empty, it means pass that check.
the explain can be see below all the settings.

	part 1
#the place of the lhe and root file: ./unit_test/
#name for lhe: *.lhe
#the save file name: test_scan
#the mother particle ID PID: 39
#lhaid: 320900
#process: p p > y > H H

	part 2
#mass list: # mgr
#mass compare value place: 5

	part 3
#PDF weight: 315200-315300 | 263400
	part 4
#want to run root analysis?(Y or N) :Y
#mass width list: # wgr
#place of the ExRootLHEFConverter: "/home/allen/programs/MG5_aMC_v2_6_2/ExRootAnalysis/ExRootLHEFConverter"


	explains
----------------------------------------------------------
-part 1 the setting for find files
if all the lhe file are in the different directorys, but all the directorys are in the same directory.
you can use that directory as the choosen place.
the default set of name for lhe file is "*.lhe" means find all lhe file, you can add some word before *.
	
----------------------------------------------------------
- part 2 setting mass check list 
How to use:
1. use "|" as delimiter 
2. use the name in the lhe file/param cards
(Ex:       4 0.000000e+00 # mc  -> so we choose # mc )
(the multiple compare list Ex: #mgr | # mb )

		*******************************************************************************************
		* if the file name looks like:(use "_" as delimeter) 													*
		* job_Zprime_A0h_A0chichi_MZp600_MA0300_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz.lhe	*
		*  1    2     3     4       5      6     7     8     9      10  ...								*
		* choose the mass compare place: 5 | 6   																	*
		* for the check (mzp | ma0) setting mass value 															*
		*******************************************************************************************
----------------------------------------------------------
- part 3 PDF weight check
	Ex: 123-456 | 555 (it will see weather the PDF id from 123 to 456 and 555 exist or not)
----------------------------------------------------------
- part 4 root analysis 
		if not run root, mass width/ kinetic test/ mother and duaghter mass test/ won't be done.
	 	the ExRootConverter will run automatically. If you have already had the root file, please use the
		same name as the lhe file and put it in the same directory.
=======
#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2018/12/15
# need to set magicCard.txt, TRootLHEFParticle.C TRootLHEFParticle.h
#############################
#load some function
function fileExistCheck_fn { # this is use to see if the file is exist or not
	# the meaning of the variables in the function:
	# $fn_1 = file name	
	fileFind=$(find $fn_1 2> /dev/null) # check if the detail.txt is exist
# if the file is exist, it will sent the alert into the terminal and see if the user want to continue
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
	# the meaning of the variables in the function:
	# $fn_1 = list
	# $fn_2 = compare var
	for m in $fn_1; do
		((i+=1))
		local getV=$(grep "$(echo $m|sed -e s/"#"/"# "/g)"$ $aFile |tr -s ' ' |cut -d ' ' -f 3)
		local c=$(echo $fn_2|cut -d ' ' -f $i)
		local cal="sqrt((float)($getV-$c)*($getV-$c))/$c*100"
		local res=$(awk 'BEGIN{if ('$cal' < '1' ) print 1; else print 0}')
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
			c=$(grep 'PDF="'$m'"' $aFile |tr -d ' ') # do the same thing like above
			if [ -z $c ]; then
				flag=false
				echo -n " $m" >> detail.txt
			fi
		fi
	done
	echo "" >> detail.txt
}

function get_mCompare_value_fn {  # auto get the setting mass from the name of file/ directory
	local i=0
	if [ -z $mCompaP ]; then
		echo 'the "#mass compare value" place in the magicCard needed being setted.'
		exit
	else
		for i in $mCompaP; do
			mCompa=$(echo $aFile|sed -e "s:$place::g" |cut -d '_' -f $i |tr -d 'a-zA-Z')
			fn_1=$mList; fn_2=$mCompa; compare_fn   
		done	
	fi	
}

echo "Start process"
# define variables
	place=$(grep "#the place" magicCard |cut -d ':' -f 2) # the directory to the place which can find the lhe files
	saveName=$(grep "#the save" magicCard |cut -d ':' -f 2|tr -d " ")  # the save file name (the comparing result will save into this file)
	SetID=$(grep "#the mother" magicCard |cut -d ':' -f 2) # the mother particle ID (will be used in root)
	lheName=$(grep "#name for lhe" magicCard |cut -d ':' -f 2) # the name will be used in find function to find the lhe file
	mList=$(grep "#mass list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass list for mass compare sys.
	mCompaP=$(grep "#mass compare" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass compare position for mass compare sys.
	mwList=$(grep "#mass width list" magicCard |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width list for mass compare sys.
	lhaid=$(grep "lhaid" magicCard |cut -d ':' -f 2| tr -d ' ') # the true value of the lhaid for comparing
	process=$(grep "process" magicCard |cut -d ':' -f 2| tr -d ' ') # the true value of the generate process(all the space will be delete)
	PDFWeight=$(grep "#PDF weight" magicCard |cut -d ':' -f 2|tr -d ' '|tr '|' " ") # the PDF ID for the PDF id comparing sys.
	filename=$(find $place -name $lheName ) # the directories to the lhe file 

# check if it can find the file
	if [ -z "$filename" ]; then  # test if filename is a zero length variables
		echo "can not detect the lhe file"
		exit 1 # if there is no file, this macro will stop
	fi

# build scan file
fn_1="tmpfile.txt"; fileExistCheck_fn # see if the file is already exist or not
> tmpfile.txt # clear all the lines in tempfile.txt
fn_1="${saveName}.txt"; fileExistCheck_fn # if the file already exist, clean it 
> ${saveName}.txt 
fn_1="detail.txt"; fileExistCheck_fn
> detail.txt

# do the check in lhe file
for aFile in $filename; do  # pick the directory to the lhe one by one in the loop
	flag=true # use for expressing the compare state

	# setting mass check
	if [ ! -z $mList ]; then # check weather mList is empty or not, if it is not empty, do the check
		echo "start $aFile mass check"
		echo "< $aFile >" >> detail.txt
		get_mCompare_value_fn # call the function which defined above
	else 
		echo "pass the setting mass check"
		echo "pass the setting mass check" >> detail.txt
	fi	

	# PDF weight check
	if [ ! -z $(echo $PDFWeight |tr -d ' ') ]; then
		echo "start $aFile PDF weight check"
		PDF_weight_fn
	else 
		echo "pass the PDF weight check"	
		echo "pass the PDF weight check"	>> detail.txt
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
	else 
		echo "pass lhaid check"	
		echo "pass lhaid check"	>> detail.txt
	fi	

	if [ ! -z $process ]; then
		getProc=$(grep ^generate $aFile |sed -e s/generate//g |tr -d ' ')
		if [ $getProc != $process ]; then 
			flag=false
			echo "Process = $getProc compare $process = false" >> detail.txt
		else echo "Process = $getProc compare $process = true" >> detail.txt
		fi
	else 
		echo "pass process check"	
		echo "pass process check" >> detail.txt
	fi
	
	# check if want to run root analysis and run root
	willRoo=$(grep "#want to" magicCard|cut -d ':' -f 2|tr -d ' '|tr 'n' 'N')
	if [ $willRoo = "N" ]; then
		continue # pass all the code below and go to the next for loop(the other lhe file name)
	fi
	# auto convert the lhe file to the root file
		exRoot=$(grep "#place" magicCard|cut -d ':' -f 2|tr -d '"') # this is the directory to the program "ExRootLHEFConverter"
		aRoot=$(echo $aFile| sed -e 's/.lhe/.root/g' )		
		$exRoot $aFile $aRoot 2> /dev/null # call the program and let lhe files become root file (with the same name xxx.lhe -> xxx.root)

	# check root file is exist
	if [ -z "$aRoot" ]; then  # test if filename is a zero length variables
		echo "can not detect the root file, pass the root analysis"
		echo "pass the root analysis because the root file does not exist" >> detail.txt
		continue # if there is no file, this macro will stop
	fi

	echo "start root analysis in $aRoot "
	# change the mother PID in .C file 
	placeInC=$(grep -n "define motherPID" ./TRootLHEFParticle.C|cut -d ":" -f 1) #f ind the line we want to change
	sed -i "${placeInC}a #define motherPID ${SetID}" ./TRootLHEFParticle.C  # write the new line (in the order of "placeInC") into TRootLHEFParticle.C
	sed -i "${placeInC}d" ./TRootLHEFParticle.C # delete the old line in the TRootLHEFParticle.C

	# run root
	stringP=$(grep -n string TRootLHEFParticle.h|cut -d ':' -f 1)
	sed -i ''${stringP}'a \   \string fileName = "'${aRoot}'";' ./TRootLHEFParticle.h # change which file need to run in .h file
	sed -i "${stringP}d" ./TRootLHEFParticle.h
		# open the root and automatically send the commands
	expect -c 'spawn -noecho root -l TRootLHEFParticle.C
	        send "TRootLHEFParticle t\r"
			  send "t.Loop()\r"
	        send ".q\r"
			  interact'
	
	# deal with the tmpfile.txt output from root 
		#although the tmpfile.txt will be delete, the grep things also can be see in the save file.
	ans1=$(grep "there" tmpfile.txt  |cut -d '(' -f 2|cut -d '%' -f 1)
	ans2=$(grep "kinetic" ./tmpfile.txt|cut -d ':' -f 2|tr -d ' ')
	ans3=$(grep "mass test" ./tmpfile.txt |cut -d ' ' -f 3)
	ans4=$(grep "^mother" ./tmpfile.txt |cut -d ' ' -f 4)
	mwCompa=$(grep "mass width" ./tmpfile.txt |cut -d '=' -f 2 |tr -d ' ') 
	fit=$(grep "fit" ./tmpfile.txt |cut -d ':' -f 2| tr -d ' ')
	fit1=$(echo $fit|cut -d '|' -f 1)
	fit2=$(echo $fit|cut -d '|' -f 2)
	# the entries without mother particle check
	if [ `echo "$ans1 > 1"|bc` -eq 1 ]; then
		flag=false
		sed -i "s/)/) > 1%: false/g" ./tmpfile.txt
	else sed -i "s/)/) < 1%: true/g" ./tmpfile.txt
	fi
	# see the result in kinetic analysis
	if [ $ans2 != true ]; then
		flag=false
	fi
	# see the result in mother particle mass and resonanse check
	if [ $ans3 != true ]; then
		flag=false
	fi
	# check the 5% 10% width/mass ratio
	for c in 5 10; do
		cal="sqrt((float)($ans4-$c)*($ans4-$c))/$c*100"
		res=$(awk 'BEGIN{if ('$cal' < '1' ) print 1; else print 0}')
		if [ $flagtmp = true ];then continue; fi
		if [ $res != 1 ]; then
			flagtmp=false
		else 
			flagtmp=true
			echo "width/mass = $ans4 compare $c = true" >> detail.txt
		fi	
	done
	if [ $flagtmp = false ];then
		flag=false
		echo "width/mass = $ans4 = false" >>detail.txt
	fi
	unset flagtmp
	# cos theta check
	if [ `echo "$fit1*$fit1 > 0.5"|bc` -eq 1 ] || [ `echo "$fit2*$fit2 > 0.5"|bc` -eq 1 ] ;then
		echo "cos theta* is not flat" >> detail.txt
	else echo "cos theta* is flat" >> detail.txt
	fi
	# setting mass width check
	if [ ! -z $mwList ]; then
		echo "start $aFile mass width check"
		fn_1=$mwList
		fn_2=$mwCompa
		compare_fn 
	else echo "pass the setting mass width check"
	fi
	sed -i '4,6d' tmpfile.txt  # delete the line which no need to be shown
	grep '' tmpfile.txt >> detail.txt # put all the output into detail.txt
	# see the final state of flag and print result into tmpfile
	if [ $flag = true ]; then
		echo "$aFile true" >> ${saveName}.txt
	else	echo "$aFile false" >> ${saveName}.txt
	fi
	echo "-----------------------------------------------" >> detail.txt
done # end loop all lhe file
# put the data in the detail.txt into the save file and remove the detail.txt
echo " " >> ${saveName}.txt ; echo "these are the comparing detail: " >> ${saveName}.txt 
grep '' ./detail.txt >> ${saveName}.txt # put all the content in the detail.txt into save file
rm ./detail.txt ./tmpfile.txt # delete two file

echo "${saveName}.txt has build"
echo "process done"
>>>>>>> cb2c9005b0beca651e49ff47dc90af1d616d8458
