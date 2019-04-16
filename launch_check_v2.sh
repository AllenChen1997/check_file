#!/bin/bash
# fileName launch_genLHE
# built by Kong-Xiang Chen
# Date 2019/02/19
# need to run with magicCard.txt, TRootLHEFParticle.C TRootLHEFParticle.h
#############################
## load some function
# function called by function
function fileExistCheck_fn { # this is use to see if the file is exist or not
	# the meaning of the variables in the function:
	# $fn_1 = file name	
	# if the file is exist, it will sent the alert into the terminal and see if the user want to continue
	if [ -e $fn_1 ]; then
		read -p "$fn_1 had already exist, do you want to continue? Y / N (continue will delete it): " ans
		if [ $(echo $ans |tr -d ' '|tr 'y' 'Y') != "Y" ]; then
			echo "process canceled"
			exit 1  # if the answer is yes, the program will stop
		fi
	fi 
}

function compare_fn { # just compare two variables equal or not. science notification can be used
	# the meaning of the variables in the function:
	# $fn_1 = true value
	# $fn_2 = compare value
	# $fn_3 = compare name
	local res=$(awk 'BEGIN{if ('$fn_1' == '$fn_2' ) print 1; else print 0}')
	if [ $res != 1 ]; then
		flag=false
		echo "$fn_3 = $fn_2 compare $fn_1 = false" >> detail.txt
		else echo "$fn_3 = $fn_2 compare $fn_1 = true" >> detail.txt
	fi	
}

function compare_withError_fn {
	# the meaning of the variables in the function:
	# $fn_1 = true value
	# $fn_2 = compare value
	# $fn_3 = compare name
	# $fn_4 = error
	local add="$fn_2 + $fn_4"
	local minus="$fn_2 - $fn_4"
	# if the true value is in the range of compare value +- error, result is true.
	if [ `echo "$fn_1 < $add"|bc` == 1 ] && [ `echo " $fn_1 > $minus"|bc` == 1 ]; then
		echo "$fn_3 = $fn_2 +- $fn_4 compare $fn_1 = true" >> detail.txt
	else 
		echo "$fn_3 = $fn_2 +- $fn_4 compare $fn_1 = false" >> detail.txt
		flag=false
	fi
}

function findPID_fn {
	local mCode=`echo $process|cut -d ">" -f 2|tr -d ' '` # cut the second element of the process as the code of mother particle
	SetID=`grep "${mCode}$" $aFile|cut -d ' ' -f 3`
	echo $SetID
}

# function called by main
function define_variables_fn {  # define variables
	place="./" # the directory to the place which can find the lhe files
	saveName="check_result"  # the save file name (the comparing result will save into this file)
	mList=$(grep "#mass list" magicCard_v2.txt |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass list for mass compare sys.
	mCompaP=$(grep "#mass compare" magicCard_v2.txt |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass compare position for mass compare sys.
	mwList=$(grep "#mass width list" magicCard_v2.txt |cut -d ':' -f 2 |tr -d " "|tr "|" " ") # mass width list for mass compare sys.
	lhaid=$(grep "lhaid" magicCard_v2.txt |cut -d ':' -f 2| tr -d ' ') # the true value of the lhaid for comparing
	process=$(grep "process" magicCard_v2.txt |cut -d ':' -f 2| tr -d ' ') # the true value of the generate process(all the space will be delete)
	PDFWeight=$(grep "#PDF weight" magicCard_v2.txt |cut -d ':' -f 2|tr -d ' '|tr '|' " ") # the PDF ID for the PDF id comparing sys.
	filename=$(find $place -name "*.lhe" ) # the directories to the lhe file 
	# check if it can find the file
	if [ -z "$filename" ]; then  # test if filename is a zero length variables
		echo "can not detect the lhe file"
		exit 1 # if there is no file, this macro will stop
	fi
}

function build_file_fn { # build the necessary files( tmpfile.txt/ detail.txt)
	fn_1="tmpfile.txt"; fileExistCheck_fn # see if the file is already exist or not
	> tmpfile.txt # clear all the lines in tempfile.txt
	fn_1="${saveName}.txt"; fileExistCheck_fn # if the file already exist, clean it 
	> ${saveName}.txt 
	fn_1="detail.txt"; fileExistCheck_fn
	> detail.txt
}

function settingMassCheck_fn { # all the work in setting mass compare
	if [ ! -z $mList ]; then # check weather mList is empty or not, if it is not empty, do the check
		echo "start $aFile mass check"
		local i=0
		if [ -z $mCompaP ]; then # see the if there is the setting value place
			echo 'the "#mass compare value" place in the magicCard_v2.txt needed being setted.'; exit
		else
			for j in $mCompaP; do
				((i+=1))
				fn_1=$(echo $aFile|sed -e "s:$place::g" |cut -d '_' -f $j |tr -d 'a-zA-Z')
				fn_3=$(echo $mList|cut -d ' ' -f $j)
				fn_2=$(grep "$(echo $fn_3|sed -e s/"#"/"# "/g)"$ $aFile |tr -s ' ' |cut -d ' ' -f 3) 
				compare_fn
			done	
		fi
	else echo "pass the setting mass check"; echo "pass the setting mass check" >> detail.txt
	fi	
}

function pdfWeightCheck_fn { # all the work in the PDF weight ID check
	if [ ! -z $(echo $PDFWeight |tr -d ' ') ]; then # see do the PDF check or not
		echo "start $aFile PDF weight check"
		echo -n "the list of not found PDF= " >> detail.txt 
		for m in $PDFWeight; do
			local count=( $(echo $m|tr '-' ' ') ) 	# make min-max become (min max)
			if [ "${#count[@]}" -eq 2 ]; then 	# if the count has two words means min max form -> check from min to max 
				local min=$(echo $m|cut -d '-' -f 1)
				local max=$(echo $m|cut -d '-' -f 2)			
				for ((i=${min}; i<=${max}; i++)); do
					local c=$(grep 'PDF="'$i'"' $aFile |cut -d ' ' -f 1) 	# get the line with the PDF id
					if [ -z $c ]; then					# see if it is a empty string
						flag=false
						echo -n " $i" >> detail.txt  # write the PDF id into detail.txt
					fi
				done
			else # otherwise only check one id
				c=$(grep 'PDF="'$m'"' $aFile |cut -d ' ' -f 1) # do the same thing like above
				if [ -z $c ]; then
					flag=false 
					echo -n " $m" >> detail.txt
				fi
			fi
		done
		echo "" >> detail.txt
	else echo "pass the PDF weight check";	echo "pass the PDF weight check"	>> detail.txt
	fi
}

function defaultCheck_fn { # check the setting process and lhaid 
	if [ ! -z $lhaid ]; then # see if need do lhaid check
		echo "start $aFile lhaid check"
		getLHAID=$(grep "lhaid" $aFile |cut -d '=' -f 1|tr -d ' ')
		if [ $getLHAID != $lhaid ]; then
			flag=false
			echo "LHAID = $getLHAID compare $lhaid = false" >> detail.txt # send text into detail.txt
		else echo "LHAID = $getLHAID compare $lhaid = true" >> detail.txt
		fi
	else echo "pass lhaid check";	echo "pass lhaid check"	>> detail.txt
	fi	

	if [ ! -z $process ]; then # see if need do process check
		getProc=$(grep ^generate $aFile |sed -e s/generate//g |tr -d ' ')
		if [ $getProc != $process ]; then 
			flag=false
			echo "Process = $getProc compare $process = false" >> detail.txt
		else echo "Process = $getProc compare $process = true" >> detail.txt
		fi
	else echo "pass process check"; echo "pass process check" >> detail.txt
	fi
}

function runRoot_fn {
	# check if want to run root analysis and run root
	willRoo=$(grep "#want to" magicCard_v2.txt|cut -d ':' -f 2|tr -d ' '|tr 'n' 'N')
	if [ $willRoo = "N" ]; then
		return 1 # pass all the code in this function and go to the next for loop(the other lhe file name)
	fi
	# auto convert the lhe file to the root file
	exRoot=$(grep "#place" magicCard_v2.txt|cut -d ':' -f 2|tr -d '"') # this is the directory to the program "ExRootLHEFConverter"
	aRoot=$(echo $aFile| sed -e 's/.lhe/.root/g' )		
	$exRoot $aFile $aRoot 2> /dev/null # call the program and let lhe files become root file (with the same name xxx.lhe -> xxx.root)

	# check root file is exist
	if [ -z "$aRoot" ]; then  # test if filename is a zero length variables
		echo "can not detect the root file, pass the root analysis"
		echo "pass the root analysis because the root file does not exist" >> detail.txt
		return 1 # if there is no root file, exit this function
	fi
	echo "start root analysis in $aRoot "

	# change the define of mother PID/ min/ max / docostheta in .C file 
	sed -i "/#define motherPID/c #define motherPID ${SetID}" ./TRootLHEFParticle.C  # use new line replace the old line	
		# find the setting mass
	local range=`grep -n "BLOCK MASS" $aFile|cut -d ':' -f 1`
	local mid_line=`sed -n ''$range','$(echo "$range + 15"|bc)'p' $aFile|grep "$SetID "`
	local mid=`echo $mid_line|cut -d ' ' -f 2`
	local mid_t=`awk "BEGIN { print $mid }"` #turn science notification into normal numbers
		# put the setting values into it
	sed -i '/#define min/c #define min '`echo "$mid_t - 1000"|bc`'' ./TRootLHEFParticle.C
	sed -i '/#define max/c #define max '`echo "$mid_t + 1000"|bc`'' ./TRootLHEFParticle.C	
		# find the spin of mother particle
	local range=`grep -n "BLOCK QNUMBERS ${SetID}" $aFile|cut -d ':' -f 1`
	local spinflag=`sed -n ''$(echo "$range + 2"|bc)'p' $aFile|tr -s ' '|cut -d ' ' -f 3`
	if [ $spinflag == "1" ]; then
		sed -i '/#define docostheta/c #define docostheta 1' ./TRootLHEFParticle.C
	else 	sed -i '/#define docostheta/c #define docostheta 0' ./TRootLHEFParticle.C
	fi
	stringP=$(grep -n string TRootLHEFParticle.h|cut -d ':' -f 1)
	sed -i '/string fileName/c \   \string fileName = "'${aRoot}'";' ./TRootLHEFParticle.h # change which file need to run in .h file
	# open the root and automatically send the commands
	expect -c '
			  spawn -noecho root -l TRootLHEFParticle.C
	        send "TRootLHEFParticle t\r"
			  send "t.Loop()\r"
	        send ".q\r"
			  interact
	'
	
	# deal with the tmpfile.txt output from root 
		#if you want to see tmpfile.txt, please delete "rm ./detail.txt ./tmpfile.txt"
	ans1=$(grep "kinetic" ./tmpfile.txt|cut -d ':' -f 2|tr -d ' ')
	ans2=$(grep "mass test" ./tmpfile.txt |cut -d ' ' -f 3)
	ans3=$(grep "^mother" ./tmpfile.txt |cut -d ' ' -f 4)
	ans3_2=$(grep "^mother" ./tmpfile.txt |cut -d ' ' -f 6)
	mwCompa=$(grep "mass width" ./tmpfile.txt |cut -d ' ' -f 4|tr -d ' ')
	mwCompa_2=$(grep "mass width" ./tmpfile.txt |cut -d ' ' -f 6|tr -d ' ')

	# see the result in kinetic analysis
	if [ $ans1 != true ]; then
		flag=false
	fi
	# see the result in mother particle mass and resonanse check
	if [ $ans2 != true ]; then
		flag=false
	fi
	# check the 5% 10% width/mass ratio
	fn_2=$ans3; fn_3="mass width/ mass"; fn_4=$ans3_2
		#decide which is fn_1 and run compare_withError_fn
	ten=`echo "$ans3 - 10"|bc`
	five=`echo "$ans3 - 5"|bc`
	if [ `echo "$five*$five < $ten*$ten"|bc` == 1 ]; then
		fn_1="5"; compare_withError_fn
	else fn_1="10"; compare_withError_fn
	fi
	# cos theta check( if spin=0 )
	if [ $spinflag == "1" ]; then
		local cosflag=true
		local fit=$(grep "fit" ./tmpfile.txt |cut -d ':' -f 2| tr -d ' '|tr '|' ' ')
		for fit_t in $fit; do
			local res=$(awk 'BEGIN{if ('${fit_t}*$fit_t' > 0.5 ) print 1; else print 0}')
			if [ `echo "$fit_t*$fit_t > 0.5"|bc` -eq 1 ] ;then
				cosflag=false
				break
			fi
		done
		if [ $cosflag == true ]; then
			echo "cos theta* is flat = true" >> detail.txt
		else 
			echo "cos theta* is not flat = false" >> detail.txt
			flag=false
		fi
	fi
	# setting mass width check
	if [ ! -z $mwList ]; then
		echo "start $aFile mass width check"
		local mwVal=$(grep "$(echo $mwList|sed -e s/"#"/"# "/g)"$ $aFile |tr -s ' ' |cut -d ' ' -f 3)
		fn_1=`awk "BEGIN { print $mwVal }"`
		fn_2=$mwCompa
		fn_3=$mwList				
		fn_4=$mwCompa_2;	compare_withError_fn 
	else echo "pass the setting mass width check"
	fi
	sed -i '3,5d' tmpfile.txt  # delete the line which no need to be shown
	grep '' tmpfile.txt >> detail.txt # put all the output into detail.txt
}

# main code
echo "Start process"
define_variables_fn # call the function defined above
build_file_fn
# check all files
for aFile in $filename; do  # pick the directory to the lhe one by one in the loop
	flag=true # use for expressing the compare state
	if [ -z $SetID ];then 
		findPID_fn
	fi
	echo "< $aFile >" >> detail.txt
	settingMassCheck_fn
	pdfWeightCheck_fn
	defaultCheck_fn
	runRoot_fn
	# see the final state of flag and print result into tmpfile
	if [ $flag = true ]; then
		echo "$aFile true" >> ${saveName}.txt
	else	echo "$aFile false" >> ${saveName}.txt
	fi
	echo "-----------------------------------------------" >> detail.txt
done
# put the data in the detail.txt into the save file and remove the detail.txt
echo " " >> ${saveName}.txt ; echo "these are the comparing detail: " >> ${saveName}.txt 
grep '' ./detail.txt >> ${saveName}.txt # put all the content in the detail.txt into save file
rm ./detail.txt ./tmpfile.txt # delete two necessary file
echo "${saveName}.txt has build"
echo "process done"
