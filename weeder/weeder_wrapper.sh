#!/bin/sh -e
#
# Wrapper script to run weeder as a Galaxy tool
#
# Usage: weeder_wrapper.sh FASTA_IN MIX_OUT WEE_OUT MATRICES_ALL MATRICES_BEST [ ARGS... ]
#
# ARGS: one or more arguments to supply directly to weeder
#
# Process command line
FASTA_IN=$1
MIX_OUT=$2
WEE_OUT=$3
MATRICES_ALL=$4
MATRICES_BEST=$5
#
# Other arguments
ARGS=""
while [ ! -z "$6" ] ; do
    ARGS="$ARGS $6"
    shift
done
#
# Tool directory i.e. location where this script is held
# Need this to locate the supplementary perl script
TOOL_DIR=`dirname $0`
#
# Link to input file
ln -s $FASTA_IN
#
# Locate the weeder programs and make links to them in the
# working directory - this hack is ugly but seems to be
# necessary in order to get the weeder pipeline to run
for prog in weederlauncher.out weederTFBS.out adviser.out ; do
    exe=`which $prog 2>&1 | grep -v "no $prog"`
    if [ ! -z "$exe" ] ; then
	echo "Linking $prog to $exe"
	ln -s $exe $prog
    else
	echo "ERROR $0 cannot locate executable for $prog"
	exit 1
    fi
done
#
# Also link to the FreqFiles directory
# PJB actually this doesn't appear to be necessary for our local
# RPM install so commented out for now
##freqfiles_dir=/usr/share/weeder-1.4.2/FreqFiles
##if [ -d $freqfiles_dir ] ; then
##    echo "Linking to FreqFiles directory"
##    ln -s $freqfiles_dir FreqFiles
##else
##    echo "ERROR FreqFiles directory not found" >&2
##    exit 1
##fi
#
# Construct names of input and output files
fasta=`basename $FASTA_IN`
mix=$fasta.mix
wee=$fasta.wee
#
# Construct and run weeder command
# NB weeder logs output to stderr eso redirect to stdout
# to prevent the Galaxy tool reporting failure
weeder_cmd="./weederlauncher.out $fasta $ARGS"
echo "Running $weeder_cmd"
$weeder_cmd 2>&1 | tee weeder.log
#
# NB advisor.out is started as a background process (why???)
# so keep checking the log file - when we encounter
# "Job completed" then the process has finished
running=
while [ -z "$running" ] ; do
    running=`tail weeder.log | grep "Job completed"`
    sleep 5s
done
#
# Extract matrices
if [ -e $wee ] ; then
    perl ${TOOL_DIR}/ExtractWeederMatrices.pl $wee
fi
#
# Move outputs to final destinations
if [ -e $mix ] ; then
    /bin/mv $mix $MIX_OUT
fi
if [ -e $wee ] ; then
    /bin/mv $wee $WEE_OUT
fi
if [ -e ${wee}_ALL_matrix.txt ] ; then
    /bin/mv ${wee}_ALL_matrix.txt $MATRICES_ALL
fi
if [ -e ${wee}_BEST_matrix.txt ] ; then
    /bin/mv ${wee}_BEST_matrix.txt $MATRICES_BEST
fi  
#
# Done
