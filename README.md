# check_file
this work includes the bash script, and root macro to check some words in the files and do some analysis.

this work also use the ExRootLHEFConverter in ExRootAnalysis.
if you already had Madgraph :
...
MG5_aMC>install ExRootAnalysis 
...
you will see the ExRootLHEFConverter at MG5_aMC_xxx/ExRootAnalysis/
if you didn't have Madgraph, you can see: https://launchpad.net/mg5amcnlo

# How to use?
(1) put the magicCard.txt, TRootLHEFParticle.C, TRootLHEFParticle.h, and launch_check.sh in the same directory

(2) open the magicCard.txt and edit what you want to check in lhe files

(3) open terminal with the dictory in (1)

(4) do $bash launch_check.sh

(5) you will see {setting save name}.txt in the dictory in (1) 

# Quick testing
(1) put magicCard.txt, TRootLHEFParticle.C, TRootLHEFParticle.h, launch_check.sh, and unit_test/ in the same directory

(2) do:
...
$bash lanch_check.sh
...
(3) you will see test_scan.txt being built.
