#!/bin/bash
# Scratch Cron Job for GE            (c) 2013 University of California, Irvine
# ----------------------------------------------------------------------------
# This cronjob is desigend to update the complex resource for SGE on the 
# available compute node.
#
# @author       Adam Brenner   <aebrenne@uci.edu>
# @version      1.0
# @date         03/2013

####### Global Variables
VERSION=1.0
LOCATION=/scratch

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


###### Main Functions
function run() {

    HOSTNAME=$(hostname -s);
    # Check to see if we have enough free memory on the system
    local availSpace=$(df -h -B G $LOCATION | awk {'print $4'} | tail -n +2);
    #df -h $LOCATION | awk {'print $4'} | tail -n +2 | while read availSpace ; do
        #echo "Scratch Space: $availSpace on $HOSTNAME";
        runCommand "qconf -mattr exechost complex_values scratch_size=${availSpace} $HOSTNAME"
   # done;

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
    -r,--run       : Will run and update the complex resource for scratch so
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