#!/bin/bash
# Flash Atom RAMDISK Setup           (c) 2013 University of California, Irvine
# ----------------------------------------------------------------------------
# Flash Atom is an idea similar to SDSC's Flash Gordon system where instead of
# expensive solid state disks to use as scratch space, Flash Atom will use
# available system memory as the scratch space. System memory is faster and
# requires no hardware costs. Flash Atom is ideal for large compute nodes that
# can spare double/triple digit system memory for ramdisk.
#
# @author       Adam Brenner   <aebrenne@uci.edu>
# @version      1.0
# @date         02/2013

####### Global Variables
VERSION=1.0
MEMBUFFER=10 # Value in GB of the buffer we should set aside for system process
             # This value is subtracted from the $availMem in createFA function
FALOCATION=/fa
GUSER=""

###### Helper Methods
# isEmpty checks all passed in params and exits if any are empty 
function isEmpty() {
    for i in "$@"
    do
        if [[ -z $i ]] ; then
            echo "At least one agrument is empty or missing";
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
        local error="FAILED: $1 produced exit code $exitStatus";
        echo $error;
        log "$error";
        exit 1;
    fi
    
    return $exitStatus;
}


# Helper Function for log and createFA
function storeFAInstances() {
    # Grab a list of all mount points for flash atom and
    # store to file.
    df -h | grep $FALOCATION | awk {'print $6, $2, $3'} | while read MTNPOINT USED LIMIT ; do
        echo "$MTNPOINT using $USED of $LIMIT limit." >> $0.tmp
    done;
}

# Log and Send emails on errors
function log() {
    
    # Do we have the correct params being passed in?
    local message=$1;
    local    user=$GUSER;
    local    node=$(hostname -s);
    
    storeFAInstances;
    local runningFAs=$(cat $0.tmp);
    local getMemory=$(free -g);
    #To: $user@hpc.oit.uci.edu
    #cc: aebrenne@uci.edu, hmangala@uci.edu, jfarran@uci.edu
    
    # Debugging Purposes
    /usr/sbin/sendmail -t << EOF
To: $user@hpc.oit.uci.edu
Cc: aebrenne@uci.edu
Subject: [FA Failed] $user on $node

FlashAtom has failed on $node. Should you have questions, please contact HPC staff. FlashAtom guide available here: http://hpc.oit.uci.edu/flashAtom
    
Error Message:
$message

Debug:
[root@$node ~]# flash-atom --list
$runningFAs
[root@$node ~]# free -g
$getMemory
EOF

    rm -rf $0.tmp

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
function createFA() {

    # Do we have the correct params being passed in?
    local  faSize=$1;    isEmpty    "$faSize";
    local    user=$2;    isEmpty      "$user";
    local geJobId=$3;    isEmpty   "$geJobId";
    GUSER="$user";

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
    
    if [ $memToUse -le $faSize ] ; then
        local error="Not enough system memory. Requested: "$faSize"GB, available: "$availMem"GB from "$totalMem"GB with a "$MEMBUFFER"GB reserved buffer, leaving "$memToUse"GB available."
        echo $error;
        log "$error";
        exit 1;
    fi
    
    # If flash-Atom system already exists, remove it. This is an edge case at
    # best, but it doesn't hurt to include it.
    destroyFA "$user" "$geJobId"
    
    # Create the flash-Atom filesystem
    runCommand "mkdir -p $FALOCATION/$user.$geJobId"
    
    # Mount the flash-Atom filesystem using tmpfs
    runCommand "mount -t tmpfs -o size="$faSize"G,mode=755,uid=$user,gid=users tmpfs $FALOCATION/$user.$geJobId"

}

# This function will destroy the tmpfs
# Things to consider:
#  1: Destroy the mount -- *force* if necessary
#  2: store / log results
function destroyFA() {
    # Do we have the correct params being passed in?
    local    user=$1;    isEmpty      "$user";
    local geJobId=$2;    isEmpty   "$geJobId";
    GUSER="$user";
    
    # If flash-Atom system already exists, remove it.
    local isFAPresent=$(df -h | grep $FALOCATION/$user.$geJobId | wc -l);
    if [ $isFAPresent -ne 0 ]; then 
        # Grab a list of all mount points for this user. Best case, only one
        # instance, however edge case, multiple (script failed?)...hence for.
        for i in $(lsof $FALOCATION/$user.$geJobId | awk {'print $2'} | tail -n +2) ; do
            runCommand "kill -9 $i";
        done;
        
        runCommand "umount $FALOCATION/$user.$geJobId";
        runCommand "rm -rf $FALOCATION/$user.$geJobId";
    fi
}

# This function will show all running instances of flash atom
function showFAInstances() {
    # Grab a list of all mount points for flash atom.
    df -h | grep $FALOCATION | awk {'print $6, $2, $3'} | while read MTNPOINT USED LIMIT ; do
        echo "$MTNPOINT using $USED of $LIMIT limit.";
    done;
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
    -c,--create    : Will create a fixed size of memory to be used as a tmpfs.
                   : Available parameters / example are below:
                   :     sh $0 -c 20 aebrenne 183300
                   : This will create 20GB of ramdisk with the user/folder of
                   : aebrenne in $FALOCATION/aebrenne.183300
                   :    First param --> is a limit in GB
                   :   Second param --> is a valid username
                   :    Third param --> is the SGE job id

    -d,--destroy   : Destroys a given flash atom instance that was created.
                   :     sh $0 -d aebrenne 183300
                   : This will destroy $FALOCATION/aebrenne.183300 and return
                   : the memory for system use.
                   :    First param --> is a valid username
                   :   Second param --> is the SGE job id

    -l,--list      : List current flash atom instances. Example
                   :     sh $0 -l

END

}

##################################################################
# Execute the program
##################################################################

case "$1" in
   --create|-c)
      createFA "$2" "$3" "$4"
      exit 0;
   ;;
   --destroy|-d)
      destroyFA "$2" "$3"
      exit 0;
   ;;
   --list|-l)
      showFAInstances
      exit 0;
   ;;
   *)
      helpMenu
      exit 0;
   ;;
esac
exit 0;