# get start
this work includes the bash script, and root macro to check some words in the files and do some analysis.

this work also use the ExRootLHEFConverter in ExRootAnalysis.
# install the ExRootAnalysis
● if you already had Madgraph :

	MG5_aMC>install ExRootAnalysis 

you will see the ExRootLHEFConverter at (path)/MG5_aMC_xxx/ExRootAnalysis/

● if you didn't have Madgraph, you can use in terminal:

	wget http://madgraph.phys.ucl.ac.be/Downloads/ExRootAnalysis/ExRootAnalysis_V1.1.5.tar.gz
	tar zxvf ExRootAnalysis_V1.1.5.tar.gz
	cd ExRootAnalysis/
	make

● how to use ExRootLHEFConverter

	(path)/ExRootAnalysis/ExRootLHEFConverter input_name.lhe output_name.root
	

# The choose of the v2 or not v2
if you won't need to select the saved name of the files and the read name of the LHE files, you can choose launch_check_v2.sh and magicCard_v2.txt.

it will reduce some options in it. But you need to put the launch_check_v2.sh, magicCard_v2.txt, TRootLHEFParticle.h, and TRootLHEFParticle.C in the directory where you put the LHE files.

# How to use?(not v2)
(1) put the magicCard.txt, TRootLHEFParticle.C, TRootLHEFParticle.h, and launch_check.sh in the same directory

(2) open the magicCard.txt and edit what you want to check in lhe files

(3) open terminal in the dictory at (1)

(4) do 

	bash launch_check.sh

(5) you will see {setting save name}.txt in the dictory in (1) 

# How to use?(v2)
(1) put the magicCard_v2.txt, TRootLHEFParticle.C, TRootLHEFParticle.h, and launch_check_v2.sh in the directory where you put the LHE files

(2) open the magicCard_v2.txt and edit what you want to check in lhe files

(3) open terminal in the dictory at (1)

(4) do 

	bash launch_check_v2.sh

(5) you will see check_result.txt in the dictory at (1) 

# Quick testing

	git clone https://github.com/AllenChen1997/check_file.git
	cd check_file/
	bash launch_check.sh

you will see test_scan.txt being built.
