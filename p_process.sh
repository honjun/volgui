#/bin/bash
#
# This script is designed to do the basic initial investigation for a memory image.
# By: Matthew Ulm
# Date: May 25, 2015
#
# This script was built using the SIFT workstation 3.0
# First it will hash the memory file with MD5 and SHA1.
# then dump pslist, pstree, psxview.
# It will then look at the svchost processes, and compare all of them together.
# Then it attempts to dump the svchost processes using procexedump.
# It will then MD5 hash those files, and compare them to some online engines.
#
### Set some variables
##########################
USER="/home/sansforensics";
HOME="/cases";
VOL="vol.py";
DSVT="/home/sansforensics/volgui/tools/dsvtsearch.py"
DSUB="/home/sansforensics/volgui/tools/dsvtsubmit.py"
ADMC="/home/sansforensics/volgui/tools/adobemc.py"
HEADER="Accept: text/html"
UA20="Mozilla/5.0 Gecko/20010527 Firefox/22.3"
TODAY=$(date +"%Y-%m-%d")
FTIME="$(date)"
#
#
### Get some information from the user.
#######################################
# 
echo "This particular script will look at the processes found within the memory file. "
echo "First we will pull the process list after hashing the memory image "
echo "Then I will dump the svchost processes, and compare those to each other. "
echo " "
echo " "
#
# SECTION 00
# Get Information from the USER
#
# Get the case name from the user.
echo "I need to get some information first... "
echo "What is the case name?"
echo "For me this is the folder name in the cases folder.....:"
read CASE
if [ ! -d "$HOME/$CASE" ]; then
        echo "It does not look as if the case has been setup just yet.";
        echo " "; sleep 1; exit;
fi
#
# What is the memory file name
echo "What is the memory file name? :"
read FILE
if [ ! -f "$HOME/$CASE/$FILE" ]; then
        echo "It does not look as if the file you gave me is in the right place.";
        echo "Please make sure the file is in this location. $HOME/$CASE ... ";
        echo " "; 
	echo "Please check the file lcoation, and try the script again."
	exit;
fi
echo " "
echo "What is your Virus Total API Key "
read APIK
#
#############################################################
#
# SECTION 01
#	Administrative Setup and checks for the script
#
# Check for some directories
#
setupdir=( text evidence pdump )
for i in "${setupdir[@]}"; do
	if [ ! -d "$HOME/$CASE/$i" ]; then
		mkdir -p $HOME/$CASE/$i
	fi
done
echo " "
#
#
# Hash the memory file
echo "I am going to take some hashes of the memory now. " >> $HOME/$CASE/evidence/$CASE.process.log;
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log
echo "The file being analyzed is: $FILE" >> $HOME/$CASE/evidence/$CASE.process.log;
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log
#
# MD5 hash first
echo "I will first take an MD5 hash now";
echo "I will first take an MD5 hash now" >> $HOME/$CASE/evidence/$CASE.process.log
md5sum $HOME/$CASE/$FILE >> $HOME/$CASE/evidence/$CASE.process.log
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log;
#
# Now time for the SHA1 hash.
echo "I will take a SHA1 hash now";
echo "I will take a SHA1 hash now" >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
sha1sum $HOME/$CASE/$FILE >> $HOME/$CASE/evidence/$CASE.process.log
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log;
#
# Now time for the SHA256 hash.
echo "I will take a SHA256 hash now";
echo "I will take a SHA256 hash now" >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
sha256sum $HOME/$CASE/$FILE >> $HOME/$CASE/evidence/$CASE.process.log
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; 
#
echo "Here are the hashes from the process module run: " >> $HOME/$CASE/evidence/memory.hash.list
cat $HOME/$CASE/evidence/$CASE.process.log >> $HOME/$CASE/evidence/memory.hash.list
echo "" >> $HOME/$CASE/evidence/memory.hash.list
echo "" >> $HOME/$CASE/evidence/memory.hash.list
#
##################################################################
#
# SECTION 02
#	First runs at the memory file.
#
# Let's figure out what image we are working with.
# Ask the user if they know what profile to use.
# Find out for them if they do not know.
#
echo "One last bit of information is needed......"
echo "Do you know what profile to use on this memory sample? (y/n):"
read RESP
case $RESP in
	y|Y )	echo "OK, then......"
        	echo "What profile would you like to use? :"
        	read PRFL;
        	echo " ";;
	n|N )	echo " "
		echo "Let's run our imageinfo module and take a look at what we might have now. "
		vol.py -f $HOME/$CASE/$FILE imageinfo
		# Ask the user what they want to use
		echo "What profile do you want to use for these scans? :"
		read PRFL
		echo " ";;
	* ) 	echo " ";
		echo "That is unexpected input";
		echo "Stopping"
		exit;;
esac
echo " ";
echo "This is the profile being used: $PRFL" >> $HOME/$CASE/evidence/$CASE.process.log;
echo "------------------------------------------------------------" >> $HOME/$CASE/evidence/$CASE.process.log;
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " "; echo " ";
#
#
# Let's do our process scans to get started on our analysis
# First move into our CASE directory
cd $HOME/$CASE
#
# Set an array and loop please.
process=( pslist psscan )
for i in "${process[@]}"; do
	if [ ! -f "text/$i.txt" ]; then
		echo "$i module has been run at $(date), against the memory file."
                echo "$i module has been run at $(date), against the memory file." >> $HOME/$CASE/evidence/$CASE.process.log
		echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo "";
		$VOL -f $FILE --profile=$PRFL $i > text/$i.txt
		echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
		sleep 1;
	else 
		echo "It looks as if the $i module has already been run."
		echo "I am skipping this step for now. "
		sleep 1; echo " ";
	fi
done
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
#
####################################################################
# SECTION 03
#	Let's do First start by looking at our svchost process.
#
cd $HOME/$CASE/text;
cat pslist.txt | grep svchost | awk '{ print $3 }' >> svchost.pids.list.working
cat pslist.txt | grep svchost | awk '{ print $4 }' >> svchost.parent.list.working
cat psscan.txt | grep svchost | awk '{ print $3 }' >> svchost.pids.list.working
cat psscan.txt | grep svchost | awk '{ print $4 }' >> svchost.parent.list.working
cat svchost.pids.list.working | sort -u >> svchost.pids.list
cat svchost.parent.list.working | sort -u >> svchost.parent.list
rm -rf svchost.pids.list.working 
rm -rf svchost.parent.list.working
#
# Let's print information about the svchost processes found.
SVCHC=($(wc -l svchost.pids.list))
echo "There ( is - are ) $SVCHC svchost process(es) discovered within RAM."
echo "There ( is - are ) $SVCHC svchost process(es) discovered within RAM." >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.process.log; echo " ";
echo "Here ( is - are ) all of the svchost PIDs ";
cat svchost.pids.list; echo " "; sleep 3;   
# The sleep is to give you some time to read it.
# Now to the log file.
echo "Here ( is - are ) all of the svchost PIDSs " >> $HOME/$CASE/evidence/$CASE.process.log
cat svchost.pids.list >> $HOME/$CASE/evidence/$CASE.process.log
#
#
# Work with the SVChost parent processes
SVCPC=($(wc -l svchost.parent.list))
echo "There ( is - are ) $SVCPC unique svchost parent process(es) "
echo "There ( is - are ) $SVCPC unique svchost parent process(es) " >> $HOME/$CASE/evidence/$CASE.process.log
echo " " >> $HOME/$CASE/evidence/$CASE.log; echo " ";
echo "Here ( is - are ) the svchost parent(s) processes.... ";
cat svchost.parent.list; echo " "; echo " "; sleep 3;
# the sleep is to give you time to read it.
# Now for the log file again.
echo "Here ( is - are ) the svchost parent(s) processes.... "; >> $HOME/$CASE/evidence/$CASE.process.log
cat svchost.parent.list >> $HOME/$CASE/evidence/$CASE.process.log
#
#
cd $HOME/$CASE/pdump; 
mkdir svchost;
cp $HOME/$CASE/text/svchost.pids.list $HOME/$CASE/pdump
while read r; do
	$VOL -f $HOME/$CASE/$FILE --profile=$PRFL procdump -p $r -D svchost
done < svchost.pids.list
#
cd svchost;
for i in *.exe; do
	md5sum $i >> svchost.md5.full
	sha1sum $i >> svchost.sha1.full
	sha256sum $i >> svchosr.256.full
done
#
#
cat svchost.md5.full | cut -c 1-32 | sort -u >> svchost.md5.list
cat svchost.sha1.full | cut -c 1-40 | sort -u >> svchost.sha1.list
cat svchost.256.full | cut -c 1-64 | sort -u >> svchost.256.list
#
#
cat svchost.md5.list >> $HOME/$CASE/evidence/$CASE.md5.list;
cat svchost.md5.full >> $HOME/$CASE/evidence/$CASE.md5.full;
cat svchost.sha1.list >> $HOME/$CASE/evidence/$CASE.sha1.list;
cat svchost.sha1.full >> $HOME/$CASE/evidence/$CASE.sha1.full;
cat svchost.256.list >> $HOME/$CASE/evidence/$CASE.256.list;
cat svchost.256.full >> $HOME/$CASE/evidence/$CASE.256.full;
#
#
# Let's do some stuff online now.
# ## Will need to make some directories, and files and what not.
#
# Thes are for the MD5 hashes.
mkdir vxv te th mdb;
echo "Going to check the MD5 hashes online now. ";
echo "Going to check the MD5 hashes online now. " >>  $HOME/$CASE/evidence/$CASE.process.svchost.log;
while read r; do
	# trying to keep the timing around to 20 seconds for a hash.
	sleep 1;
	echo "Check $r with VX Vault.....";
	echo "Check $r with VX Vault....." >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.md5.html.log;
	wget --header="$HEADER" --user-agent="$UA20" "http://vxvault.siri-urz.net/ViriList.php?MD5=$r" -O "vxv/$r.vxv.html"
	sleep 5;
	echo "Check $r with Threat Expert.....";
	echo "Check $r with Threat Expert....." >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	wget --header="$HEADER" --user-agent="$UA20" "http://www.threatexpert.com/report.aspx?md5=$r" -O "te/$r.te.html"
	echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.sha1.html.log;
	sleep 4;
	echo "Check with Total Hash.....";
	echo "Check with Total Hash....." >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	wget --header="$HEADER" --user-agent="$UA20" --no-check-certificate "http://totalhash.com/search/hash:$r" -O "th/$r.th.html"
	echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.256.html.log;
	sleep 5;
	wget --header="$HEADER" --user-agent="$UA20" "http://malwaredb.malekal.com/index.php?hash=$r" -O "mdb/$r.mdb.html"
done < svchost.md5.list
python $DSVT -k $APIK -f svchost.md5.list;
#
#
# Let's look through some of the SHA 256 hashes now. 
# For VT we are going to go a bit slower on these files.
mkdir vt_256;
echo "Going to check the SHA 256 hashes super quick.";
echo "Going to check the SHA 256 hashes super quick." >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
while read r; do
	echo "Check $r with Virus Total ......";
	echo "Check $r with Virus Total ......" >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	wget --header="$HEADER" --user-agent="UA20" "https://www.virustotal.com/en/file/$variable/analysis/" -O "vt_256/$r.vt_256.html"
	sleep 20;
done < svchost.256.list;
#

#
#
# TO DO:
# Need to include some file parsing here so we can remove hashes that have no hits.
# Also should look at including the other hash sets.
ssdeep -b -a -p *.exe >> $HOME/$CASE/pdump/svchost/ssdeep.svchost.log;
cat $HOME/$CASE/pdump/svchost/ssdeep.svchost.log >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
cat $HOME/$CASE/pdump/svchost/ssdeep.svchost.log;
echo " "; sleep 3; echo " ";
#
#
for i in *.exe; do
	echo "-----------------------------------" >> $HOME/$CASE/evidence/$CASE.process.svchost.log
	file $i >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	# /usr/local/bin/pescan $i >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	# echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	echo "Adobe Malware Classifier....." >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	python $ADMC -f $i -n 1 >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	python $ADMC -f $i -n 2 >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	python $ADMC -f $i -n 3 >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	python $ADMC -f $i -n 4 >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
        python $ADMC -f $i >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	echo " " >> $HOME/$CASE/evidence/$CASE.process.svchost.log;
	strings -a -e l $i >> $i.strings
	echo "----------" >> $i.strings; echo "----------" >> $i.strings;
	strings -a -e b $i >> $i.strings;
	echo "----------" >> $i.strings; echo "----------" >> $i.strings;
	strings -a $i >> $i.strings;
done
#
#
##########################################################
# SECTION 04
# Finishing up.

# Run a couple more process things to get some last bits of information.
cd $HOME/$CASE
$VOL -f $FILE --profile=$PRFL pstree -v >> text/pstree.verbose.txt
$VOL -f $FILE --profile=$PRFL psxview >> text/psxview.txt


#
# Lets look for more of the SANS Find Evil poster.





#
# EOF
