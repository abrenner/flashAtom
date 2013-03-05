#!/bin/bash
# Flash Atom Cron Job for GE         (c) 2013 University of California, Irvine
# ----------------------------------------------------------------------------
# Flash Atom is an idea similar to SDSC's Flash Gordon system where instead of
# expensive solid state disks to use as scratch space, Flash Atom will use
# available system memory as the scratch space. System memory is faster and
# requires no hardware costs. Flash Atom is ideal for large compute nodes that
# can spare double/triple digit system memory for ramdisk.
#
# This cronjob is desigend to update the complex resource for SGE on the 
# available compute node.
#
# @author       Adam Brenner   <aebrenne@uci.edu>
# @version      1.0
# @date         03/2013

####### Global Variables
VERSION=1.0
MEMBUFFER=10 # Value in GB of the buffer we should set aside for system process
             # This value is subtracted from the $availMem in run function
FALOCATION=/fa

###### Helper Methods
# isEmpty checks all passed in params and exits if any are empty 
function isEmpty() {
    for i in "$@"
    do
        if [[ -z $i ]] ; then
            echo "At least one argument is empty or missing";
            exit 1;
        fi
    done
}

# runCommand runs a command and checks the return status. If the return
# status is not zero, it echos and fails.
function runCommand() {
    
    # Runs the command
    $@
    #echo "$@"

    local exitStatus=$?;
    if [ $exitStatus -ne 0 ]; then
        # exitStatus of 126 is permission problem
        # exitStatus of 127 is command not found (check path)
        local error="FAILED: $1 produced exit code $exitStatus";
        echo $error;
        exit 1;
    fi
    
    return $exitStatus;
}


# Helper Function for log and createFA
function storeFAInstances() {
    # Grab a list of all mount points for flash atom and
    # store to file.
    echo "" > $0.tmp > /dev/null
    df -h | grep $FALOCATION | awk {'print $6, $2, $3'} | while read MTNPOINT USED LIMIT ; do
        echo "$MTNPOINT using $USED of $LIMIT limit." >> $0.tmp
    done;
}


###### Main Functions
# This function will create the tmpfs
# Thigs to consider:
#  1: Does system have enough free memory for this?
#  2: Are the correct directories / permissions in place?
#  3: Create flash-atom
#    a) mount
#    b) test read/write
#    c) store / log results
function run() {

    # Check to see if we have enough free memory on the system
    local totalMem=$(free -g | grep Mem: | awk {'print $2'});
    local availMem=$(free -g | grep Mem: | awk {'print $4'});
    local activeFA="0";
    # Do not want to over commit memory set aside by FA. Memory is only used
    # as files populate FA system -- it will not show up under free -g
    storeFAInstances;
    for i in $(cat $0.tmp | awk {'print $3'} | sed s'/.$//') ; do
        activeFA=$(($activeFA + $i));
    done
    local memToUse=$(($availMem - $MEMBUFFER - $activeFA));
    rm -rf $0.tmp

    echo "$memToUse on system";
}

# This function prints the help menu
function helpMenu() {
	cat << END

  Usage: $0 [OPTIONS]
Version: $VERSION
 Author: Adam Brenner <aebrenne@uci.edu>

    General Commands:
    ---------------------------------------------------------------------------
    -h,--help      : Print this help screen

    Program Commands:
    ---------------------------------------------------------------------------
    -r,--run       : Will run and update the complex resource for flash atom so
                   : GE can queue jobs correctly. Example below:
                   :     sh $0 -r

END

}

##################################################################
# Execute the program
##################################################################

case "$1" in
   --run|-r)
      run
      exit 0;
   ;;
   *)
      helpMenu
      exit 0;
   ;;
esac
exit 0;