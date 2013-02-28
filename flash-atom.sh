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
        echo "FAILED: $1 produced exit code $exitStatus";
        exit 1;
    fi
    
    return $exitStatus;
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
    local faSize=$1;    isEmpty "$faSize";
    local   user=$2;    isEmpty   "$user";

    # Check to see if we have enough free memory on the system
    local totalMem=$(free -g | grep Mem: | awk {'print $2'});
    local availMem=$(free -g | grep Mem: | awk {'print $4'});
    local memToUse=$(expr $availMem - $MEMBUFFER);

    if [ $memToUse -le $faSize ] ; then
        echo "Not enough system memory. Requested: "$faSize"GB, available: "$availMem"GB from "$totalMem"GB with a "$MEMBUFFER"GB reserved buffer, leaving "$memToUse"GB available."
        exit 1;
    fi
    
    # Create the flash-Atom filesystem
    runCommand "mkdir -p $FALOCATION/$user/"
    
    # Mount the flash-Atom filesystem using tmpfs
    runCommand "mount -t tmpfs -o size="$faSize"G,mode=755,uid=$user,gid=users tmpfs $FALOCATION/$user/"


}

# This function will destroy the tmpfs
# Things to consider:
#  1: Destroy the mount -- *force* if necessary
#  2: store / log results
function destroyFA() {
	echo
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
                   :     sh $0 -c 20 aebrenne
                   : This will create 20GB of ramdisk with the user/folder of
                   : aebrenne in $DISKPATH
                   : First param is a limit in GB
                   : Second param is a valid username

    -d,--destroy   : Destroys a given ramdisk instance that was created. Example
                   :     sh $0 -d aebrenne
                   : This will create 20GB of ramdisk with the user/folder of
                   : aebrenne in $DISKPATH
                   : First param is a limit in GB
                   : Second param is a valid username

    -l,--list      : List current ramdisk instances. Example
                   :     sh $0 -l

END

}

##################################################################
# Execute the program
##################################################################

case "$1" in
   --create|-c)
      createFA "$2" "$3"
      exit 0;
   ;;
   --destroy|-d)
      destroyFA "$2"
      exit 0;
   ;;
   --list|-l)
      showList
      exit 0;
   ;;
   *)
      helpMenu
      exit 0;
   ;;
esac
exit 0;
