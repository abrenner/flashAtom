#!/bin/bash
# Flash Atom Prolog Setup            (c) 2013 University of California, Irvine
# ----------------------------------------------------------------------------
# Flash Atom is an idea similar to SDSC's Flash Gordon system where instead of
# expensive solid state disks to use as scratch space, Flash Atom will use
# available system memory as the scratch space. System memory is faster and
# requires no hardware costs. Flash Atom is ideal for large compute nodes that
# can spare double/triple digit system memory for ramdisk.
#
# This prolog file is intended to run as an elevated user can mount and
# unmount filesystems owend by other users. In addition to kill processes of
# other users. Typically sge@prolog.sh will work or root@prolog.sh
#
# @author       Adam Brenner   <aebrenne@uci.edu>
# @version      1.0
# @date         03/2013

# This function will call flash-atom.sh to create the system.
# Thigs to consider:
#  1: Return value
#    a) 0 == okay!
#    b) 1 == error
#       action ==> quit job
#    c) 3 == not enough memory on system
#       action ==> requeue job || quit
function setupFA() {
    
    # Has the environmental variable (-v) FLASHATOM been exported
    if [[ ! -z $FLASHATOM ]] ; then
        
        if [[ $FLASHATOM != *[!0-9]* ]] ; then
            /bin/sh flash-atom.sh -c $FLASHATOM $USER $JOB_ID
            local exitStatus=$?;
            if [ $exitStatus -ne 0 ] ; then
                # At this point, flash-atom.sh should have emailed and logged
                # the issue. It is up to prolog.sh to requeue job or quit.
                #
                # A possible better solution might be to create a complex
                # resource host that works with each host so SGE will only
                # submit jobs to those nodes that have space.
                if [ $exitStatus -eq 3 ] ; then
                    # Not enough system memory able to create FA system. 
                    # What do we do? requeue job || quit
                    echo ;
                fi
            elif [ $exitStatus -eq 0 ] ; then
                # Flash Atom created successful
                echo "FA_DIR=/fa/$USER.$JOB_ID" >> $SGE_JOB_SPOOL_DIR/environment
            fi
        else
            # The FlashAtom variable contains something other then a number.
            # Not sure how to proceed. Quit?
            echo ;
        fi
    fi
}

# Call function setupFA
setupFA;
exit 0;

