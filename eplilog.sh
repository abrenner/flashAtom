#!/bin/bash
# Flash Atom Eplilog Setup           (c) 2013 University of California, Irvine
# ----------------------------------------------------------------------------
# Flash Atom is an idea similar to SDSC's Flash Gordon system where instead of
# expensive solid state disks to use as scratch space, Flash Atom will use
# available system memory as the scratch space. System memory is faster and
# requires no hardware costs. Flash Atom is ideal for large compute nodes that
# can spare double/triple digit system memory for ramdisk.
#
# This eplilog file is intended to run as an elevated user can mount and
# unmount filesystems owend by other users. In addition to kill processes of
# other users. Typically sge@eplilog.sh will work or root@eplilog.sh
#
# @author       Adam Brenner   <aebrenne@uci.edu>
# @version      1.0
# @date         03/2013


###### Main Functions
# Just call flash-atom script to force an unmount.
function destroyFA() {
    
    # Has the environmental variable (-v) FLASHATOM been exported
    if [[ ! -z $FLASHATOM ]] ; then
        /bin/sh flash-atom.sh -d $USER $JOB_ID
    fi
}

destroyFA;
exit 0;

