#       FULL BACKUP UYILITY FOR ENIGMA2/OPENPLI, SUPPORTS VARIOUS MODELS      #
#                   MAKES A FULLBACK-UP READY FOR FLASHING.                   #
#                                                                             #
###############################################################################
#
#!/bin/sh

## ADD A POSTRM ROUTINE TO ENSURE A CLEAN UNINSTALL
## This is normally added while building but despite several requests it isn't added yet
## So therefore this workaround.
POSTRM="/var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.postrm"
if [ ! -f $POSTRM ] ; then
	echo "#!/bin/sh" > "$POSTRM"
	echo "rm -rf /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite" >> "$POSTRM"
	echo 'echo "Plugin removed!"' >> "$POSTRM"
	echo "exit 0" >> "$POSTRM"
	chmod 755 "$POSTRM"
fi
## END WORKAROUND

##TESTING IF PROGRAM IS RUN FROM COMMANDLINE OR CONSOLE, JUST FOR THE COLORS ##
if tty > /dev/null ; then		# Commandline
	RED='-e \e[00;31m'
	GREEN='-e \e[00;32m'
	YELLOW='-e \e[01;33m'
	BLUE='-e \e[01;34m'
	PURPLE='-e \e[01;31m'
	WHITE='-e \e[00;37m'
else							# On the STB
	RED='\c00??0000'
	GREEN='\c0000??00'
	YELLOW='\c00????00'
	BLUE='\c0000????'
	PURPLE='\c00?:55>7'   
	WHITE='\c00??????'
fi
###################### FIRST DEFINE SOME PROGRAM BLOCKS #######################
############################# START LOGGING ###################################
log()
{
echo "$*" >> $LOGFILE
}
########################## DEFINE CLEAN-UP ROUTINE ############################
clean_up()
{
umount /tmp/bi/root > /dev/null 2>&1
rmdir /tmp/bi/root > /dev/null 2>&1
rmdir /tmp/bi > /dev/null 2>&1
rm -rf "$WORKDIR" > /dev/null 2>&1
}
###################### BIG OOPS!, HOLY SH... (SHELL SCRIPT :-))################
big_fail()
{
if [ -d $WORKDIR ] ; then 
	log "FAIL!"
	log "Content so far of the working directory $WORKDIR "
	ls -el $WORKDIR >> $LOGFILE
fi
clean_up
echo $RED
$SHOW "message15" 2>&1 | tee -a $LOGFILE # Image creation FAILED!
echo $WHITE
exit 0
}
############################ DEFINE IMAGE_VERSION #############################
image_version()
{
echo "Back-up = $BACKUPDATE"
echo "Version = $IMVER"
echo "Flashed = $FLASHED"
echo "Updated = $LASTUPDATE"
echo -n "Drivers = "
opkg list-installed | grep dvb-modules
echo "Enigma2 = $ENIGMA2DATE"
echo 
echo $LINE
}
#################### CLEAN UP AND MAKE DESTINATION FOLDERS ####################
make_folders()
{
rm -rf "$MAINDEST"
log "Removed directory  = $MAINDEST"
mkdir -p "$MAINDEST"
log "Created directory  = $MAINDEST"
}
################ CHECK FOR THE NEEDED BINARIES IF THEY EXIST ##################
checkbinary()
{
if [ ! -f "$1" ] ; then {
	echo -n "$1 " ; $SHOW "message05"
	} 2>&1 | tee -a $LOGFILE
	big_fail
elif [ ! -x "$1" ] ; then
	{
	echo "Error: $1 " ; $SHOW "message35"
	} 2>&1 | tee -a $LOGFILE
	big_fail
fi
}
############## CHECK FOR THE NEEDED DEPENDENCIES IF THEY EXIST ################
check_dependency()
{
   log "Checking Dependencies ..."
   UPDATE=0
   for pkg in mtd-utils mtd-utils-ubifs;
   do   
      opkg status $pkg | grep -q "install user installed"
      if [ $? -ne 0 ] ; then
         [ $UPDATE -eq 0 ] && opkg update && UPDATE=1
         opkg install $pkg 2>/dev/null
      fi
   done
}
############## CHECK FOR THE NEEDED DEPENDENCIES IF THEY EXIST ################
check_dependency_old()
{
   log "Checking Dependencies ..."
   UPDATE=0
   for pkg in mtd-utils-jffs2 dreambox-buildimage;
   do   
      opkg status $pkg | grep -q "install user installed"
      if [ $? -ne 0 ] ; then
         [ $UPDATE -eq 0 ] && opkg update && UPDATE=1
         opkg install $pkg 2>/dev/null
      fi
   done
}
############## CHECK FOR THE NEEDED DEPENDENCIES IF THEY EXIST ################
check_dependency_xz()
{
   log "Checking Dependencies ..."
   UPDATE=0
   for pkg in xz;
   do   
      opkg status $pkg | grep -q "install user installed"
      if [ $? -ne 0 ] ; then
         [ $UPDATE -eq 0 ] && opkg update && UPDATE=1
         opkg install $pkg 2>/dev/null
      fi
   done
}
################### BACK-UP MADE AND REPORTING SIZE ETC. ######################
backup_made()
{
{
echo $LINE
$SHOW "message10" ; echo "$MAINDEST" 	# USB Image created in: 
$SHOW "message23"		# "The content of the folder is:"
ls "$MAINDEST" -e1rSh | sed 's/-.........    1//' 
echo $LINE
if  [ $HARDDISK != 1 ]; then
	$SHOW "message11" ; echo "$EXTRA"		# and there is made an extra copy in:
	echo $LINE
fi
} 2>&1 | tee -a $LOGFILE
}
################### BACK-UP MADE AND REPORTING SIZE ETC. ######################
backup_made_nfi()
{
{
echo $LINE
$SHOW "message42" ; echo "$MAINDEST" 	# NFI Image created in: 
$SHOW "message23"		# "The content of the folder is:"
ls "$MAINDEST" -e1rSh | sed 's/-.........    1//' 
echo $LINE
if  [ $HARDDISK != 1 ]; then
	$SHOW "message11" ; echo "$EXTRA"		# and there is made an extra copy in:
	echo $LINE
fi
} 2>&1 | tee -a $LOGFILE
}
############################## END PROGRAM BLOCKS #############################


########################## DECLARATION OF VARIABLES ###########################
BACKUPDATE=`date +%Y.%m.%d_%H:%M`
DATE=`date +%Y%m%d_%H%M`
if [ -f "/usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt" ] ; then
	ESTSPEED=`cat /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt`
	if [ $ESTSPEED -lt 50 ] ; then 
		ESTSPEED="250"
	fi
else
	ESTSPEED="250"
fi
FLASHED=`date -r /etc/version +%Y.%m.%d_%H:%M`
ISSUE=`cat /etc/issue | grep . | tail -n 1 ` 
IMVER=${ISSUE%?????}
LASTUPDATE=`date -r /var/lib/opkg/status +%Y.%m.%d_%H:%M`
ENIGMA2DATE=`cat /tmp/enigma2version`
LOGFILE=/tmp/BackupSuite.log
MEDIA="$1"
MKFS=/usr/sbin/mkfs.ubifs
MKFSJFFS2=/usr/sbin/mkfs.jffs2
BUILDIMAGE=/usr/bin/buildimage
XZBINARY=/usr/bin/xz
MTDPLACE=`cat /proc/mtd | grep -w "kernel" | cut -d ":" -f 1`
NANDDUMP=/usr/sbin/nanddump
START=$(date +%s)
if [ -f "/etc/lookuptable.txt" ] ; then
	LOOKUP="/etc/lookuptable.txt"
	$SHOW "message36"
else
	LOOKUP="/usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/lookuptable.txt"
fi
TARGET="XX"
UBINIZE=/usr/sbin/ubinize
USEDsizebytes=`df -B 1 /usr/ | grep [0-9]% | tr -s " " | cut -d " " -f 3`
USEDsizekb=`df -k /usr/ | grep [0-9]% | tr -s " " | cut -d " " -f 3` 
if [ -f "/var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control" ] ; then
	VERSION="Version: "`cat /var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control | grep "Version: " | cut -d "+" -f 2`
else
	VERSION=`$SHOW "message37"`
fi
WORKDIR="$MEDIA/bi"

######################### START THE LOGFILE $LOGFILE ##########################
echo -n "" > $LOGFILE
log "*** THIS BACKUP IS CREATED WITH THE PLUGIN BACKUPSUITE ***"
log "***** ********************************************* ******"
log $LINE
log "Plugin version     = "`cat /var/lib/opkg/info/enigma2-plugin-extensions-backupsuite.control | grep "Version: " | cut -d "+" -f 2- | cut -d "-" -f1`
log "Back-up media      = $MEDIA"
df -h "$MEDIA"  >> $LOGFILE
log $LINE
image_version >> $LOGFILE
log "Working directory  = $WORKDIR"

###### TESTING IF ALL THE BINARIES FOR THE BUILDING PROCESS ARE PRESENT #######
echo $RED
check_dependency
checkbinary $NANDDUMP
checkbinary $MKFS
checkbinary $UBINIZE
echo -n $WHITE

#############################################################################
# TEST IF RECEIVER IS SUPPORTED AND READ THE VARIABLES FROM THE LOOKUPTABLE #

if [ -f /proc/stb/info/hwmodel ] ; then				# New Xsarius models
	log "Not a dreambox?"
	exit 1
fi

if [ -f /proc/stb/info/gbmodel ] ; then			# Gigablue models
	log "Not a dreambox?"
	exit 1
fi

if [ -f /proc/stb/info/boxtype ] ; then			# All models except Vu+
	log "Not a dreambox?"
	exit 1
fi

if [ -f /proc/stb/info/vumodel ] ; then		# Vu+ models
	log "Not a dreambox?"
	exit 1

if [ -f /proc/stb/info/model ] ; then
	SEARCH=$( cat /proc/stb/info/model )
else
	echo $RED
	$SHOW "message01" 2>&1 | tee -a $LOGFILE # No supported receiver found!
	big_fail
fi

############################## DM9X0 Situation ##############################
dm9x0_situation()
{
log "Found dm9x0, bz2 mode"
MODEL=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 2`
SHOWNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 3`
FOLDER="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 4`"
EXTR1="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 5`/$DATE"
EXTR2="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 6`"
EXTRA="$MEDIA$EXTR1$EXTR2"
if  [ $HARDDISK = 1 ]; then
	MAINDEST="$MEDIA$EXTR1$FOLDER"
else 
	MAINDEST="$MEDIA$FOLDER"
fi
MKUBIFS_ARGS=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 7`
UBINIZE_ARGS=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 8`
ROOTNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 9`
KERNELNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 10`
ACTION=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 11`
if [ $ROOTNAME = "rootfs.tar.bz2" ] ; then
	MKFS=/bin/tar
	checkbinary $MKFS
	BZIP2=/usr/bin/bzip2
	if [ ! -f "$BZIP2" ] ; then
		echo "$BZIP2 " ; $SHOW "message38"
		opkg update > /dev/null 2>&1
		opkg install bzip2 > /dev/null 2>&1
		checkbinary $MKFS
	fi
fi
log "Destination        = $MAINDEST"
log $LINE

############# START TO SHOW SOME INFORMATION ABOUT BRAND & MODEL ##############
echo -n $PURPLE
echo -n "$SHOWNAME " | tr  a-z A-Z		# Shows the receiver brand and model
$SHOW "message02"  			# BACK-UP TOOL FOR MAKING A COMPLETE BACK-UP 
echo $BLUE
log "RECEIVER = $SHOWNAME "
log "MKUBIFS_ARGS = $MKUBIFS_ARGS"
log "UBINIZE_ARGS = $UBINIZE_ARGS"
echo "$VERSION"
echo $WHITE

############ CALCULATE SIZE, ESTIMATED SPEED AND SHOW IT ON SCREEN ############
$SHOW "message06" 	#"Some information about the task:"

if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	KERNELHEX=`cat /proc/mtd | grep -w "kernel" | cut -d " " -f 2` # Kernelsize in Hex
else
	KERNELHEX=800000 # Not the real size (will be added later)
fi
KERNEL=$((0x$KERNELHEX))			# Total Kernel size in bytes
TOTAL=$(($USEDsizebytes+$KERNEL))	# Total ROOTFS + Kernel size in bytes
KILOBYTES=$(($TOTAL/1024))			# Total ROOTFS + Kernel size in KB
MEGABYTES=$(($KILOBYTES/1024))
{
echo -n "KERNEL" ; $SHOW "message04" ; printf '%6s' $(($KERNEL/1024)); echo ' KB'
echo -n "ROOTFS" ; $SHOW "message04" ; printf '%6s' $USEDsizekb; echo ' KB'
echo -n "=TOTAL" ; $SHOW "message04" ; printf '%6s' $KILOBYTES; echo " KB (= $MEGABYTES MB)"
} 2>&1 | tee -a $LOGFILE
if [ $ROOTNAME = "rootfs.tar.bz2" ] ; then
	ESTTIMESEC=$(($KILOBYTES/($ESTSPEED*3)))
else
	ESTTIMESEC=$(($KILOBYTES/$ESTSPEED))
fi
ESTMINUTES=$(( $ESTTIMESEC/60 ))
ESTSECONDS=$(( $ESTTIMESEC-(( 60*$ESTMINUTES ))))
echo $LINE
{
$SHOW "message03"  ; printf "%d.%02d " $ESTMINUTES $ESTSECONDS ; $SHOW "message25" # estimated time in minutes 
echo $LINE
} 2>&1 | tee -a $LOGFILE

####### WARNING IF THE IMAGESIZE OF THE XTRENDS GETS TOO BIG TO RESTORE ########
if [ ${MODEL:0:2} = "et" -a ${MODEL:0:3} != "et8" -a ${MODEL:0:3} != "et1" -a ${MODEL:0:3} != "et7" ] ; then
	if [ $MEGABYTES -gt 120 ] ; then
    echo -n $RED
	$SHOW "message28" 2>&1 | tee -a $LOGFILE #Image probably too big to restore
	echo $WHITE
	elif [ $MEGABYTES -gt 110 ] ; then
	echo -n $YELLOW
	$SHOW "message29" 2>&1 | tee -a $LOGFILE #Image between 111 and 120MB could cause problems
	echo $WHITE
	fi
fi

#=================================================================================
#exit 0  #USE FOR DEBUGGING/TESTING ###########################################
#=================================================================================

##################### PREPARING THE BUILDING ENVIRONMENT ######################
log "*** FIRST SOME HOUSEKEEPING ***"
rm -rf "$WORKDIR"		# GETTING RID OF THE OLD REMAINS IF ANY
log "Remove directory   = $WORKDIR"
mkdir -p "$WORKDIR"		# MAKING THE WORKING FOLDER WHERE EVERYTHING HAPPENS
log "Recreate directory = $WORKDIR"
mkdir -p /tmp/bi/root # this is where the complete content will be available
log "Create directory   = /tmp/bi/root"
sync
mount --bind / /tmp/bi/root # the complete root at /tmp/bi/root
## TEMPORARY WORKAROUND FOR OPENPLI 6 TO REMOVE 
##      /var/lib/samba/private/msg.sock
## WHICH GIVES AN ERRORMESSAGE WHEN NOT REMOVED
if [ -d /tmp/bi/root/var/lib/samba/private/msg.sock ] ; then 
	rm -rf /tmp/bi/root/var/lib/samba/private/msg.sock
fi

####################### START THE REAL BACK-UP PROCESS ########################
############################# MAKING UBINIZE.CFG ##############################
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	echo \[ubifs\] > "$WORKDIR/ubinize.cfg"
	echo mode=ubi >> "$WORKDIR/ubinize.cfg"
	echo image="$WORKDIR/root.ubi" >> "$WORKDIR/ubinize.cfg"
	echo vol_id=0 >> "$WORKDIR/ubinize.cfg"
	echo vol_type=dynamic >> "$WORKDIR/ubinize.cfg"
	echo vol_name=rootfs >> "$WORKDIR/ubinize.cfg"
	echo vol_flags=autoresize >> "$WORKDIR/ubinize.cfg"
	log $LINE
	log "UBINIZE.CFG CREATED WITH THE CONTENT:"
	cat "$WORKDIR/ubinize.cfg"  >> $LOGFILE
	touch "$WORKDIR/root.ubi"
	chmod 644 "$WORKDIR/root.ubi"
	log "--------------------------"
fi
############################## MAKING KERNELDUMP ##############################
log $LINE
$SHOW "message07" 2>&1 | tee -a $LOGFILE			# Create: kerneldump
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	log "Kernel resides on $MTDPLACE" 					# Just for testing purposes 

	$NANDDUMP /dev/$MTDPLACE -qf "$WORKDIR/$KERNELNAME"
	if [ -f "$WORKDIR/$KERNELNAME" ] ; then
		echo -n "Kernel dumped  :"  >> $LOGFILE
		ls -e1 "$WORKDIR/$KERNELNAME" | sed 's/-r.*   1//' >> $LOGFILE
	else 
		log "$WORKDIR/$KERNELNAME NOT FOUND"
		big_fail
	fi
	log "--------------------------"
else
	python /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/findkerneldevice.py
	KERNEL=`cat /sys/firmware/devicetree/base/chosen/kerneldev` 
	KERNELNAME=${KERNEL:11:7}.bin
	echo "$KERNELNAME = STARTUP_${KERNEL:17:1}"
	log "$KERNELNAME = STARTUP_${KERNEL:17:1}"
	dd if=/dev/kernel of=$WORKDIR/$KERNELNAME > /dev/null 2>&1
fi

#############################  MAKING ROOT.UBI(FS) ############################
$SHOW "message06a" 2>&1 | tee -a $LOGFILE		#Create: root.ubifs
log $LINE
if [ $ROOTNAME != "rootfs.tar.bz2" ] ; then
	$MKFS -r /tmp/bi/root -o "$WORKDIR/root.ubi" $MKUBIFS_ARGS
	if [ -f "$WORKDIR/root.ubi" ] ; then
		echo -n "ROOT.UBI MADE  :" >> $LOGFILE
		ls -e1 "$WORKDIR/root.ubi" | sed 's/-r.*   1//' >> $LOGFILE
		UBISIZE=`cat "$WORKDIR/root.ubi" | wc -c`
		if [ "$UBISIZE" -eq 0 ] ; then 
			$SHOW "message39" 2>&1 | tee -a $LOGFILE
			big_fail
		fi
	else 
		log "$WORKDIR/root.ubi NOT FOUND"
		big_fail
	fi
	log $LINE
	echo "Start UBINIZING" >> $LOGFILE
	$UBINIZE -o "$WORKDIR/$ROOTNAME" $UBINIZE_ARGS "$WORKDIR/ubinize.cfg" >/dev/null
	chmod 644 "$WORKDIR/$ROOTNAME"
	if [ -f "$WORKDIR/$ROOTNAME" ] ; then
		echo -n "$ROOTNAME MADE:" >> $LOGFILE
		ls -e1 "$WORKDIR/$ROOTNAME" | sed 's/-r.*   1//' >> $LOGFILE
	else 
		echo "$WORKDIR/$ROOTNAME NOT FOUND"  >> $LOGFILE
		big_fail
	fi
	echo
else 
	$MKFS -cf $WORKDIR/rootfs.tar -C /tmp/bi/root --exclude=/var/nmbd/* .
	$BZIP2 $WORKDIR/rootfs.tar
fi


############################ ASSEMBLING THE IMAGE #############################
make_folders
mv "$WORKDIR/$ROOTNAME" "$MAINDEST/$ROOTNAME" 
mv "$WORKDIR/$KERNELNAME" "$MAINDEST/$KERNELNAME"
if [ $ACTION = "noforce" ] ; then
	echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce"; 
elif [ $ACTION = "reboot" ] ; then
	echo "rename this file to 'force.update' to force an update without confirmation" > "$MAINDEST/reboot.update"
elif [ $ACTION = "force" ] ; then
	echo "rename this file to 'force.update' to be able to flash this backup" > "$MAINDEST/noforce.update"
	echo "Rename the file in the folder /vuplus/$SEARCH/noforce.update to /vuplus/$SEARCH/force.update to flash this image"
fi

image_version > "$MAINDEST/imageversion" 
if  [ $HARDDISK != 1 ]; then
	mkdir -p "$EXTRA"
	echo "Created directory  = $EXTRA" >> $LOGFILE
	cp -r "$MAINDEST" "$EXTRA" 	#copy the made back-up to images
fi
if [ -f "$MAINDEST/$ROOTNAME" -a -f "$MAINDEST/$KERNELNAME" -a -f "$MAINDEST/imageversion" ] ; then
		backup_made
		$SHOW "message14" 			# Instructions on how to restore the image.
		echo $LINE
else
	big_fail
fi

#################### CHECKING FOR AN EXTRA BACKUP STORAGE #####################
if  [ $HARDDISK = 1 ]; then						# looking for a valid usb-stick
	for candidate in `cut -d ' ' -f 2 /proc/mounts | grep '^/media/'`
	do
		if [ -f "${candidate}/"*[Bb][Aa][Cc][Kk][Uu][Pp][Ss][Tt][Ii][Cc][Kk]* ]
		then
		TARGET="${candidate}"
		fi    
	done
	if [ "$TARGET" != "XX" ] ; then
		echo -n $GREEN
		$SHOW "message17" 2>&1 | tee -a $LOGFILE 	# Valid USB-flashdrive detected, making an extra copy
		echo $LINE
		TOTALSIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $2'})"
		FREESIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $4'})"
		{
		$SHOW "message09" ; echo -n "$TARGET ($TOTALSIZE, " ; $SHOW "message16" ; echo "$FREESIZE)"
		} 2>&1 | tee -a $LOGFILE
		rm -rf "$TARGET$FOLDER"
		mkdir -p "$TARGET$FOLDER"
		cp -r "$MAINDEST/." "$TARGET$FOLDER"
		echo $LINE >> $LOGFILE
		echo "MADE AN EXTRA COPY IN: $TARGET" >> $LOGFILE
		df -h "$TARGET"  >> $LOGFILE
		$SHOW "message19" 2>&1 | tee -a $LOGFILE	# Backup finished and copied to your USB-flashdrive
	else 
		$SHOW "message40" >> $LOGFILE
	fi
sync
fi
######################### END OF EXTRA BACKUP STORAGE #########################

################## CLEANING UP AND REPORTING SOME STATISTICS ##################
clean_up
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
echo -n $YELLOW
{
$SHOW "message24"  ; printf "%d.%02d " $MINUTES $SECONDS ; $SHOW "message25"
} 2>&1 | tee -a $LOGFILE

ROOTSIZE=`ls "$MAINDEST" -e1S | grep root | awk {'print $3'} ` 
KERNELSIZE=`ls "$MAINDEST" -e1S | grep kernel | awk {'print $3'} ` 
TOTALSIZE=$((($ROOTSIZE+$KERNELSIZE)/1024))
SPEED=$(( $TOTALSIZE/$DIFF ))

echo $SPEED > /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt
echo $LINE >> $LOGFILE
# "Back up done with $SPEED KB per second" 
{
$SHOW "message26" ; echo -n "$SPEED" ; $SHOW "message27"
} 2>&1 | tee -a $LOGFILE
#### ADD A LIST OF THE INSTALLED PACKAGES TO THE BackupSuite.LOG ####
echo $LINE >> $LOGFILE
echo $LINE >> $LOGFILE
$SHOW "message41" >> $LOGFILE
echo "--------------------------------------------" >> $LOGFILE
opkg list-installed >> $LOGFILE

######################## COPY LOGFILE TO MAINDESTINATION ######################
echo -n $WHITE
cp $LOGFILE "$MAINDEST"
if  [ $HARDDISK != 1 ]; then
	cp $LOGFILE "$MEDIA$EXTR1"
	mv "$MEDIA$EXTR1$FOLDER"/imageversion "$MEDIA$EXTR1"
else
	mv -f "$MAINDEST"/BackupSuite.log "$MEDIA$EXTR1"
	cp "$MAINDEST"/imageversion "$MEDIA$EXTR1"
fi
if [ "$TARGET" != "XX" ] ; then
	cp $LOGFILE "$TARGET$FOLDER"
fi
############### END OF PROGRAMM ################
}
############################## DM9X0 Situation ##############################

if [ $SEARCH = "dm900" ] || [ $SEARCH = "dm920" ] ; then
	dm9x0_situation
fi

######################## DM52X,DM7080,DM820 Situation ########################
dm52x_dm7080_dm820_situation()
{
log "Found dm52x,dm7080,dm820, xz mode"

###### TESTING IF ALL THE BINARIES FOR THE BUILDING PROCESS ARE PRESENT #######
echo $RED
check_dependency_xz
checkbinary $XZBINARY
echo -n $WHITE

MODEL=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 2`
SHOWNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 3`
FOLDER="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 4`"
EXTR1="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 5`/$DATE"
EXTR2="`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 6`"
EXTRA="$MEDIA$EXTR1$EXTR2"
if  [ $HARDDISK = 1 ]; then
	MAINDEST="$MEDIA$EXTR1$FOLDER"
else 
	MAINDEST="$MEDIA$FOLDER"
fi
MKUBIFS_ARGS=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 7`
UBINIZE_ARGS=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 8`
ROOTNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 9`
KERNELNAME=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 10`
ACTION=`cat $LOOKUP | grep -w -m1 "$SEARCH" | cut -f 11`
if [ $ROOTNAME = "rootfs.tar.xz" ] ; then
	MKFS=/bin/tar
	checkbinary $MKFS
	XZBINARY=/usr/bin/xz
	if [ ! -f "$XZBINARY" ] ; then
		echo "$XZBINARY " ; $SHOW "message38"
		opkg update > /dev/null 2>&1
		opkg install xz > /dev/null 2>&1
		checkbinary $MKFS
	fi
fi
log "Destination        = $MAINDEST"
log $LINE

############# START TO SHOW SOME INFORMATION ABOUT BRAND & MODEL ##############
echo -n $PURPLE
echo -n "$SHOWNAME " | tr  a-z A-Z		# Shows the receiver brand and model
$SHOW "message02"  			# BACK-UP TOOL FOR MAKING A COMPLETE BACK-UP 
echo $BLUE
log "RECEIVER = $SHOWNAME "
log "MKUBIFS_ARGS = $MKUBIFS_ARGS"
log "UBINIZE_ARGS = $UBINIZE_ARGS"
echo "$VERSION"
echo $WHITE

############ CALCULATE SIZE, ESTIMATED SPEED AND SHOW IT ON SCREEN ############
$SHOW "message06" 	#"Some information about the task:"

if [ $ROOTNAME != "rootfs.tar.xz" ] ; then
	KERNELHEX=`cat /proc/mtd | grep -w "kernel" | cut -d " " -f 2` # Kernelsize in Hex
else
	KERNELHEX=800000 # Not the real size (will be added later)
fi
KERNEL=$((0x$KERNELHEX))			# Total Kernel size in bytes
TOTAL=$(($USEDsizebytes+$KERNEL))	# Total ROOTFS + Kernel size in bytes
KILOBYTES=$(($TOTAL/1024))			# Total ROOTFS + Kernel size in KB
MEGABYTES=$(($KILOBYTES/1024))
{
echo -n "KERNEL" ; $SHOW "message04" ; printf '%6s' $(($KERNEL/1024)); echo ' KB'
echo -n "ROOTFS" ; $SHOW "message04" ; printf '%6s' $USEDsizekb; echo ' KB'
echo -n "=TOTAL" ; $SHOW "message04" ; printf '%6s' $KILOBYTES; echo " KB (= $MEGABYTES MB)"
} 2>&1 | tee -a $LOGFILE
if [ $ROOTNAME = "rootfs.tar.xz" ] ; then
	ESTTIMESEC=$(($KILOBYTES/($ESTSPEED*3)))
else
	ESTTIMESEC=$(($KILOBYTES/$ESTSPEED))
fi
ESTMINUTES=$(( $ESTTIMESEC/60 ))
ESTSECONDS=$(( $ESTTIMESEC-(( 60*$ESTMINUTES ))))
echo $LINE
{
$SHOW "message03"  ; printf "%d.%02d " $ESTMINUTES $ESTSECONDS ; $SHOW "message25" # estimated time in minutes 
echo $LINE
} 2>&1 | tee -a $LOGFILE

####### WARNING IF THE IMAGESIZE OF THE XTRENDS GETS TOO BIG TO RESTORE ########
if [ ${MODEL:0:2} = "et" -a ${MODEL:0:3} != "et8" -a ${MODEL:0:3} != "et1" -a ${MODEL:0:3} != "et7" ] ; then
	if [ $MEGABYTES -gt 120 ] ; then
    echo -n $RED
	$SHOW "message28" 2>&1 | tee -a $LOGFILE #Image probably too big to restore
	echo $WHITE
	elif [ $MEGABYTES -gt 110 ] ; then
	echo -n $YELLOW
	$SHOW "message29" 2>&1 | tee -a $LOGFILE #Image between 111 and 120MB could cause problems
	echo $WHITE
	fi
fi

#=================================================================================
#exit 0  #USE FOR DEBUGGING/TESTING ###########################################
#=================================================================================

##################### PREPARING THE BUILDING ENVIRONMENT ######################
log "*** FIRST SOME HOUSEKEEPING ***"
rm -rf "$WORKDIR"		# GETTING RID OF THE OLD REMAINS IF ANY
log "Remove directory   = $WORKDIR"
mkdir -p "$WORKDIR"		# MAKING THE WORKING FOLDER WHERE EVERYTHING HAPPENS
log "Recreate directory = $WORKDIR"
mkdir -p /tmp/bi/root # this is where the complete content will be available
log "Create directory   = /tmp/bi/root"
sync
mount --bind / /tmp/bi/root # the complete root at /tmp/bi/root
## TEMPORARY WORKAROUND FOR OPENPLI 6 TO REMOVE 
##      /var/lib/samba/private/msg.sock
## WHICH GIVES AN ERRORMESSAGE WHEN NOT REMOVED
if [ -d /tmp/bi/root/var/lib/samba/private/msg.sock ] ; then 
	rm -rf /tmp/bi/root/var/lib/samba/private/msg.sock
fi

####################### START THE REAL BACK-UP PROCESS ########################
############################# MAKING UBINIZE.CFG ##############################
if [ $ROOTNAME != "rootfs.tar.xz" ] ; then
	echo \[ubifs\] > "$WORKDIR/ubinize.cfg"
	echo mode=ubi >> "$WORKDIR/ubinize.cfg"
	echo image="$WORKDIR/root.ubi" >> "$WORKDIR/ubinize.cfg"
	echo vol_id=0 >> "$WORKDIR/ubinize.cfg"
	echo vol_type=dynamic >> "$WORKDIR/ubinize.cfg"
	echo vol_name=rootfs >> "$WORKDIR/ubinize.cfg"
	echo vol_flags=autoresize >> "$WORKDIR/ubinize.cfg"
	log $LINE
	log "UBINIZE.CFG CREATED WITH THE CONTENT:"
	cat "$WORKDIR/ubinize.cfg"  >> $LOGFILE
	touch "$WORKDIR/root.ubi"
	chmod 644 "$WORKDIR/root.ubi"
	log "--------------------------"
fi
############################## MAKING KERNELDUMP ##############################
log $LINE
$SHOW "message07" 2>&1 | tee -a $LOGFILE			# Create: kerneldump
if [ $ROOTNAME != "rootfs.tar.xz" ] ; then
	log "Kernel resides on $MTDPLACE" 					# Just for testing purposes 

	$NANDDUMP /dev/$MTDPLACE -qf "$WORKDIR/$KERNELNAME"
	if [ -f "$WORKDIR/$KERNELNAME" ] ; then
		echo -n "Kernel dumped  :"  >> $LOGFILE
		ls -e1 "$WORKDIR/$KERNELNAME" | sed 's/-r.*   1//' >> $LOGFILE
	else 
		log "$WORKDIR/$KERNELNAME NOT FOUND"
		big_fail
	fi
	log "--------------------------"
else
	python /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/findkerneldevice.py
	KERNEL=`cat /sys/firmware/devicetree/base/chosen/kerneldev` 
	KERNELNAME=${KERNEL:11:7}.bin
	echo "$KERNELNAME = STARTUP_${KERNEL:17:1}"
	log "$KERNELNAME = STARTUP_${KERNEL:17:1}"
	dd if=/dev/kernel of=$WORKDIR/$KERNELNAME > /dev/null 2>&1
fi

#############################  MAKING ROOT.UBI(FS) ############################
$SHOW "message06a" 2>&1 | tee -a $LOGFILE		#Create: root.ubifs
log $LINE
if [ $ROOTNAME != "rootfs.tar.xz" ] ; then
	$MKFS -r /tmp/bi/root -o "$WORKDIR/root.ubi" $MKUBIFS_ARGS
	if [ -f "$WORKDIR/root.ubi" ] ; then
		echo -n "ROOT.UBI MADE  :" >> $LOGFILE
		ls -e1 "$WORKDIR/root.ubi" | sed 's/-r.*   1//' >> $LOGFILE
		UBISIZE=`cat "$WORKDIR/root.ubi" | wc -c`
		if [ "$UBISIZE" -eq 0 ] ; then 
			$SHOW "message39" 2>&1 | tee -a $LOGFILE
			big_fail
		fi
	else 
		log "$WORKDIR/root.ubi NOT FOUND"
		big_fail
	fi
	log $LINE
	echo "Start UBINIZING" >> $LOGFILE
	$UBINIZE -o "$WORKDIR/$ROOTNAME" $UBINIZE_ARGS "$WORKDIR/ubinize.cfg" >/dev/null
	chmod 644 "$WORKDIR/$ROOTNAME"
	if [ -f "$WORKDIR/$ROOTNAME" ] ; then
		echo -n "$ROOTNAME MADE:" >> $LOGFILE
		ls -e1 "$WORKDIR/$ROOTNAME" | sed 's/-r.*   1//' >> $LOGFILE
	else 
		echo "$WORKDIR/$ROOTNAME NOT FOUND"  >> $LOGFILE
		big_fail
	fi
	echo
else 
	$MKFS -cf $WORKDIR/rootfs.tar -C /tmp/bi/root --exclude=/var/nmbd/* .
	$XZBINARY $WORKDIR/rootfs.tar
fi


############################ ASSEMBLING THE IMAGE #############################
make_folders
mv "$WORKDIR/$ROOTNAME" "$MAINDEST/$ROOTNAME" 
mv "$WORKDIR/$KERNELNAME" "$MAINDEST/$KERNELNAME"
if [ $ACTION = "noforce" ] ; then
	echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce"; 
elif [ $ACTION = "reboot" ] ; then
	echo "rename this file to 'force.update' to force an update without confirmation" > "$MAINDEST/reboot.update"
elif [ $ACTION = "force" ] ; then
	echo "rename this file to 'force.update' to be able to flash this backup" > "$MAINDEST/noforce.update"
	echo "Rename the file in the folder /vuplus/$SEARCH/noforce.update to /vuplus/$SEARCH/force.update to flash this image"
fi

image_version > "$MAINDEST/imageversion" 
if  [ $HARDDISK != 1 ]; then
	mkdir -p "$EXTRA"
	echo "Created directory  = $EXTRA" >> $LOGFILE
	cp -r "$MAINDEST" "$EXTRA" 	#copy the made back-up to images
fi
if [ -f "$MAINDEST/$ROOTNAME" -a -f "$MAINDEST/$KERNELNAME" -a -f "$MAINDEST/imageversion" ] ; then
		backup_made
		$SHOW "message14" 			# Instructions on how to restore the image.
		echo $LINE
else
	big_fail
fi

#################### CHECKING FOR AN EXTRA BACKUP STORAGE #####################
if  [ $HARDDISK = 1 ]; then						# looking for a valid usb-stick
	for candidate in `cut -d ' ' -f 2 /proc/mounts | grep '^/media/'`
	do
		if [ -f "${candidate}/"*[Bb][Aa][Cc][Kk][Uu][Pp][Ss][Tt][Ii][Cc][Kk]* ]
		then
		TARGET="${candidate}"
		fi    
	done
	if [ "$TARGET" != "XX" ] ; then
		echo -n $GREEN
		$SHOW "message17" 2>&1 | tee -a $LOGFILE 	# Valid USB-flashdrive detected, making an extra copy
		echo $LINE
		TOTALSIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $2'})"
		FREESIZE="$(df -h "$TARGET" | tail -n 1 | awk {'print $4'})"
		{
		$SHOW "message09" ; echo -n "$TARGET ($TOTALSIZE, " ; $SHOW "message16" ; echo "$FREESIZE)"
		} 2>&1 | tee -a $LOGFILE
		rm -rf "$TARGET$FOLDER"
		mkdir -p "$TARGET$FOLDER"
		cp -r "$MAINDEST/." "$TARGET$FOLDER"
		echo $LINE >> $LOGFILE
		echo "MADE AN EXTRA COPY IN: $TARGET" >> $LOGFILE
		df -h "$TARGET"  >> $LOGFILE
		$SHOW "message19" 2>&1 | tee -a $LOGFILE	# Backup finished and copied to your USB-flashdrive
	else 
		$SHOW "message40" >> $LOGFILE
	fi
sync
fi
######################### END OF EXTRA BACKUP STORAGE #########################

################## CLEANING UP AND REPORTING SOME STATISTICS ##################
clean_up
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
echo -n $YELLOW
{
$SHOW "message24"  ; printf "%d.%02d " $MINUTES $SECONDS ; $SHOW "message25"
} 2>&1 | tee -a $LOGFILE

ROOTSIZE=`ls "$MAINDEST" -e1S | grep root | awk {'print $3'} ` 
KERNELSIZE=`ls "$MAINDEST" -e1S | grep kernel | awk {'print $3'} ` 
TOTALSIZE=$((($ROOTSIZE+$KERNELSIZE)/1024))
SPEED=$(( $TOTALSIZE/$DIFF ))

echo $SPEED > /usr/lib/enigma2/python/Plugins/Extensions/BackupSuite/speed.txt
echo $LINE >> $LOGFILE
# "Back up done with $SPEED KB per second" 
{
$SHOW "message26" ; echo -n "$SPEED" ; $SHOW "message27"
} 2>&1 | tee -a $LOGFILE
#### ADD A LIST OF THE INSTALLED PACKAGES TO THE BackupSuite.LOG ####
echo $LINE >> $LOGFILE
echo $LINE >> $LOGFILE
$SHOW "message41" >> $LOGFILE
echo "--------------------------------------------" >> $LOGFILE
opkg list-installed >> $LOGFILE

######################## COPY LOGFILE TO MAINDESTINATION ######################
echo -n $WHITE
cp $LOGFILE "$MAINDEST"
if  [ $HARDDISK != 1 ]; then
	cp $LOGFILE "$MEDIA$EXTR1"
	mv "$MEDIA$EXTR1$FOLDER"/imageversion "$MEDIA$EXTR1"
else
	mv -f "$MAINDEST"/BackupSuite.log "$MEDIA$EXTR1"
	cp "$MAINDEST"/imageversion "$MEDIA$EXTR1"
fi
if [ "$TARGET" != "XX" ] ; then
	cp $LOGFILE "$TARGET$FOLDER"
fi
############### END OF PROGRAMM ################
}
######################## DM52X,DM7080,DM820 Situation ########################

if [ $SEARCH = "dm520" ] || [ $SEARCH = "dm525" ] || [ $SEARCH = "dm7080" ] || [ $SEARCH = "dm820" ] ; then
	dm52x_dm7080_dm820_situation
fi

########################### Old Dreambox Situation ###########################
old_dreambox_situation()
{
log "Found old dreamboxes, nfi mode"

###### TESTING IF ALL THE BINARIES FOR THE BUILDING PROCESS ARE PRESENT #######
echo $RED
check_dependency_old
checkbinary $MKFSJFFS2
checkbinary $BUILDIMAGE
echo -n $WHITE

# athoik's code, Modified by Persian Prince #

CREATE_ZIP="$2"
IMAGENAME="$3"

cleanup_mounts(){
   if [ ! -z "$TBI" ] ; then
      if [ -d "$TBI/boot" ] ; then
	 if grep -q "$TBI/boot" /proc/mounts ; then 
	    umount "$TBI/boot" 2>/dev/null || log "Cannot umount boot" && exit 6
	 fi
	 rmdir "$TBI/boot" 2>/dev/null
      fi
      if [ -d "$TBI/root" ] ; then
	 if grep -q "$TBI/root" /proc/mounts ; then
	    umount "$TBI/root" 2>/dev/null || log "Cannot umount root" && exit 7
	 fi
	 rmdir "$TBI/root" 2>/dev/null
      fi
   fi
}

#
# Set Backup Location
#
EXTRA="$MEDIA/fullbackup_dreambox/$DATE"
MAINDEST="$MEDIA/$SEARCH"

SBI="$MEDIA/bi"
TBI="/tmp/bi"
#
# Initialize Parameters
#
EXTRA_BUILDCMD=""
EXTRA_IMAGECMD=""

DREAMBOX_ERASE_BLOCK_SIZE=""
DREAMBOX_FLASH_SIZE=""
DREAMBOX_SECTOR_SIZE=""
MKUBIFS_ARGS=""
UBINIZE_ARGS=""

UBINIZE_VOLSIZE="0"
UBINIZE_DATAVOLSIZE="0"
UBI_VOLNAME="rootfs"

DREAMBOX_IMAGE_SIZE=""
DREAMBOX_PART0_SIZE=""
DREAMBOX_PART1_SIZE=""
DREAMBOX_PART2_SIZE=""

#
# Set parameters based on box
# dm7020hdv2 is recognized from /sys/devices/virtual/mtd/mtd0/writesize
# No support for xz images: dm520,dm7080,dm820
case $SEARCH in
   dm800|dm500hd|dm800se)
      EXTRA_BUILDCMD="--brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x4000"
      DREAMBOX_FLASH_SIZE="0x4000000"
      DREAMBOX_SECTOR_SIZE="512"
      MKUBIFS_ARGS="-m 512 -e 15KiB -c 3798 -x favor_lzo -X 1 -F -j 4MiB"
      UBINIZE_ARGS="-m 512 -p 16KiB -s 512"
      DREAMBOX_IMAGE_SIZE="64"
      DREAMBOX_PART0_SIZE="0x40000"
      DREAMBOX_PART1_SIZE="0x3C0000"
      DREAMBOX_PART2_SIZE="0x3C00000"
      ;;
   dm500hdv2|dm800sev2|dm7020hdv2)
      EXTRA_BUILDCMD="--hw-ecc --brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
      DREAMBOX_FLASH_SIZE="0x40000000"
      DREAMBOX_SECTOR_SIZE="2048"
      MKUBIFS_ARGS="-m 2048 -e 124KiB -c 3320 -x favor_lzo -F"
      UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048"
      UBINIZE_VOLSIZE="402MiB"
      UBINIZE_DATAVOLSIZE="569MiB"
      DREAMBOX_IMAGE_SIZE="1024"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0x3F800000"
      ;;
   dm7020hd)
      EXTRA_BUILDCMD="--hw-ecc --brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x40000"
      DREAMBOX_FLASH_SIZE="0x40000000"
      DREAMBOX_SECTOR_SIZE="4096"
      MKUBIFS_ARGS="-m 4096 -e 248KiB -c 1640 -x favor_lzo -F"
      UBINIZE_ARGS="-m 4096 -p 256KiB -s 4096"
      UBINIZE_VOLSIZE="397MiB"
      UBINIZE_DATAVOLSIZE="574MiB"
      DREAMBOX_IMAGE_SIZE="1024"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0x3F800000"

      # dm7020hdv2 when writesize = 2048
      WRITESIZE="4096"
      if [ -f /sys/devices/virtual/mtd/mtd0/writesize ] ; then 
	 WRITESIZE=$(cat /sys/devices/virtual/mtd/mtd0/writesize)
      fi
      if [ $WRITESIZE = "2048" ] ; then
	 log "Found dm7020hdv2"
	 DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
	 DREAMBOX_SECTOR_SIZE="2048"
	 MKUBIFS_ARGS="-m 2048 -e 124KiB -c 3320 -x favor_lzo -F"
	 UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048"
	 UBINIZE_VOLSIZE="402MiB"
	 UBINIZE_DATAVOLSIZE="569MiB"
      fi
      ;;
   dm8000)
      EXTRA_BUILDCMD=""
      DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
      DREAMBOX_FLASH_SIZE="0x10000000"
      DREAMBOX_SECTOR_SIZE="2048"
      MKUBIFS_ARGS="-m 2048 -e 126KiB -c 1961 -x favor_lzo -F"
      UBINIZE_ARGS="-m 2048 -p 128KiB -s 512"
      DREAMBOX_IMAGE_SIZE="256"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0xF800000"
      ;;
   *)
      log "Error: Unknown dreambox?"
      exit 3
      ;;
esac

EXTRA_IMAGECMD="-e $DREAMBOX_ERASE_BLOCK_SIZE -n -l"

#
# Setup temporary files and variables
#
SECSTAGE="$SBI/secondstage.bin"
UBINIZE_CFG="$TBI/ubinize.cfg"
BOOT="$SBI/boot.jffs2"
ROOTFS="$SBI/rootfs.jffs2"

cleanup_mounts

echo $LINE
echo "Starting Full Backup, Please wait ..."
echo $LINE

rm -rf "$SBI" 2>/dev/null
rm -rf "$TBI" 2>/dev/null
mkdir -p "$SBI"
mkdir -p "$TBI"

#
# Export secondstage
#
log "Exporting secondstage"
/usr/sbin/nanddump --noecc --omitoob --bb=skipbad --file="$SECSTAGE" /dev/mtd1
if [ $? -ne 0 ] && [ ! -f "$SECSTAGE" ] ; then
   rm -rf "$SBI" 2>/dev/null
   rm -rf "$TBI" 2>/dev/null
   log "Error: nanddump failed to dump secondstage!"
   exit 8
fi

#
# Trim 0xFFFFFF from secondstage
#
/usr/bin/python -c "
data=open('$SECSTAGE', 'rb').read()
cutoff=data.find('\xff\xff\xff\xff')
if cutoff:
    open('$SECSTAGE', 'wb').write(data[0:cutoff])
"

SIZE="$(du -k "$SECSTAGE" | awk '{ print $1 }')"
if [ $SIZE -gt 200 ] ; then 
   log "Error: Size of secondstage must be less than 200k"
   log "Reinstall secondstage before creating backup"
   log "opkg install --force-reinstall dreambox-secondstage-$SEARCH"
   rm -rf "$SBI" 2>/dev/null
   rm -rf "$TBI" 2>/dev/null
   exit 9
fi

#
# Export boot partition
#
log "Exporting boot partition"
mkdir -p "$TBI/boot"
mount -t jffs2 /dev/mtdblock/2 "$TBI/boot"

/usr/sbin/mkfs.jffs2 \
   --root="$TBI/boot" \
   --compression-mode=none \
   --output="$BOOT" \
   $EXTRA_IMAGECMD

umount "$TBI/boot" 2>/dev/null

#
# Export root partition
#
if grep -q ubi0:rootfs /proc/mounts ; then

   log "Exporting rootfs (UBI)"
   ROOTFS="$SBI/rootfs.ubi"
   ROOTUBIFS="$SBI/rootfs.ubifs"
   mkdir -p "$TBI/root"
   mount --bind / "$TBI/root"

   echo [root] > $UBINIZE_CFG
   echo mode=ubi >> $UBINIZE_CFG
   echo image=$ROOTUBIFS >> $UBINIZE_CFG
   echo vol_id=0 >> $UBINIZE_CFG
   echo vol_name=$UBI_VOLNAME >> $UBINIZE_CFG
   echo vol_type=dynamic >> $UBINIZE_CFG
   if [ "$UBINIZE_VOLSIZE" = "0" ] ; then
      echo vol_flags=autoresize >> $UBINIZE_CFG
   else
      echo vol_size=$UBINIZE_VOLSIZE >> $UBINIZE_CFG
      if [ "$UBINIZE_DATAVOLSIZE" != "0" ] ; then
	 echo [data] >> $UBINIZE_CFG
	 echo mode=ubi >> $UBINIZE_CFG
	 echo vol_id=1 >> $UBINIZE_CFG
	 echo vol_type=dynamic >> $UBINIZE_CFG
	 echo vol_name=data >> $UBINIZE_CFG
	 echo vol_size=$UBINIZE_DATAVOLSIZE >> $UBINIZE_CFG
	 echo vol_flags=autoresize >> $UBINIZE_CFG
      fi
   fi

   /usr/sbin/mkfs.ubifs -r "$TBI/root" -o $ROOTUBIFS $MKUBIFS_ARGS
   log "mkfs.ubifs return value: $?"
   /usr/sbin/ubinize -o $ROOTFS $UBINIZE_ARGS $UBINIZE_CFG
   log "ubinize return value: $?"

   umount "$TBI/root" 2>/dev/null
else
   log "Export rootfs (JFFS2)"
   mkdir -p "$TBI/root"
   mount -t jffs2 /dev/mtdblock/3 "$TBI/root"

   /usr/sbin/mkfs.jffs2 \
      --root="$TBI/root" \
      --disable-compressor=lzo \
      --compression-mode=size \
      --output=$ROOTFS \
      $EXTRA_IMAGECMD
   log "mkfs.jffs2 return value: $?"
   umount "$TBI/root" 2>/dev/null
fi

#
# Build NFI image
#
log "Building NFI image"
/usr/bin/buildimage --arch $SEARCH $EXTRA_BUILDCMD \
   --erase-block-size $DREAMBOX_ERASE_BLOCK_SIZE \
   --flash-size $DREAMBOX_FLASH_SIZE \
   --sector-size $DREAMBOX_SECTOR_SIZE \
   --boot-partition $DREAMBOX_PART0_SIZE:$SECSTAGE \
   --data-partition $DREAMBOX_PART1_SIZE:$BOOT \
   --data-partition $DREAMBOX_PART2_SIZE:$ROOTFS \
   > "$SBI/backup.nfi"

#
# Archive NFI image
#
log "Transfering image to backup folder"
TSTAMP="$(date "+%Y-%m-%d-%Hh%Mm")"
rm -rf "$MAINDEST" 2>/dev/null

mkdir -p "$MAINDEST"
NFI="$MAINDEST/$TSTAMP-$SEARCH.nfi"
mv "$SBI/backup.nfi" "$NFI"
log "Backup image created $NFI"
log "$(du -h $NFI)"

if [ -z "$CREATE_ZIP" ] ; then
   mkdir -p "$EXTRA"
   touch "$NFI/$IMVER"
   cp -r "$NFI" "$EXTRA"
   touch "$MEDIA/fullbackup/.timestamp"
else
   if [ $CREATE_ZIP != "none" ] ; then
      log "Create zip archive..."
      cd $MEDIA && $CREATE_ZIP -r $MEDIA/backup-$IMAGENAME-$SEARCH-$TSTAMP.zip . -i /$SEARCH/*
      cd
   fi
fi

#
# Cleanup
#
log "Remove temporary files..."
cleanup_mounts
rm -rf "$SBI" 2>/dev/null
rm -rf "$TBI" 2>/dev/null

if [ -f "$NFI" ] ; then
	backup_made_nfi
else
	echo $RED
	$SHOW "message15" 2>&1 | tee -a $LOGFILE # Image creation FAILED!
	echo $WHITE
fi
#
# The End
#
log "Completed!"
################## CLEANING UP AND REPORTING SOME STATISTICS ##################
clean_up
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
echo -n $YELLOW
{
$SHOW "message24"  ; printf "%d.%02d " $MINUTES $SECONDS ; $SHOW "message25"
} 2>&1 | tee -a $LOGFILE
#### ADD A LIST OF THE INSTALLED PACKAGES TO THE BackupSuite.LOG ####
echo $LINE >> $LOGFILE
echo $LINE >> $LOGFILE
$SHOW "message41" >> $LOGFILE
echo "--------------------------------------------" >> $LOGFILE
opkg list-installed >> $LOGFILE
}
########################### Old Dreambox Situation ###########################

if [ $SEARCH != "dm900" ] && [ $SEARCH != "dm920" ] && [ $SEARCH != "dm520" ] && [ $SEARCH != "dm525" ] && [ $SEARCH != "dm7080" ] && [ $SEARCH != "dm820" ] ; then
	old_dreambox_situation
fi

exit
