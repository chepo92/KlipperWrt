#!/bin/sh
# No, the following isn't a global shellcheck directive
true
# shellcheck disable=SC1091
. /lib/functions.sh

# Error, log, and info functions. Colours defined once here:
RED='\033[0;31m'	# Red
NC='\033[0m' 		# No Color
echoerr(){
	# Echo, but fancy!
	# Log to stderr
	echo -e "[${RED}ERROR${NC}]"" $*" 1>&2
}
info(){
	# Just a regular echo, but renamed for readability
	# Also adds a prefix. Fancy!
	echo '[INFO]'" $*"
}

config_load klipper

#=======================#
#====== Functions ======#
#=======================#
# These functions are used within the different sections as repeatable code blocks

bindtest(){
	# Test whether a bind mount completed successfully
	# Arg one is the source directory, arg two is the folder it is bind mounted to
 
	# bindtest /path/to/sourcedir /path/to/destdir
	# bindtest $1				  $2
	touch "$1/test.gramdalf"
	if [ -f "$2/test.gramdalf" ]; then
		info "$1"" mounted correctly."
	else
		echoerr "$1"" did not mount correctly."
		BINDMNT='false'
	fi
	rm "$1/test.gramdalf"
}
create_uci_bindmount(){
	# Create an entry that will be automounted on boot by /etc/init.d/klippertab
	# Add an anonymous section, mount, suppressing automatic output of the cfgid

	# create_uci_bindmount /path/to/targetdir subvolume your-unique-uuid
	# create_uci_bindmount $1				  $2		$3
	info "Creating bind mount entry for $2"
	# If klipper.subvolmount does not exist, create it. Redirect stdout/err from uci show to /dev/null
	if ! uci show klipper.subvolmount > /dev/null 2>&1; then
		info 'klipper.subvolmount does not exist, creating'
		uci set klipper.subvolmount='subvolmount'
	else
		info 'klipper.subvolmount exists, skip creation'
	fi
	uci set klipper.subvolmount.
	uci add klipper mount
	# Add fstab options to the last anonymous (mount) section
	uci set klipper.@mount[-1].target="$1"
	uci set klipper.@mount[-1].subvol="$2"
	uci set klipper.@mount[-1].options="subvol=SUBVOL_UCI_REPLACE"
	uci set klipper.@mount[-1].enabled='1'
	uci set klipper.@mount[-1].uuid="$3"
	# Commit changes
	uci commit klipper
}
verify_block_device(){
	lsblk -npo name -e 31,7,254 | grep "$1"
}
prompt_block_device(){
	_TMP='invalid'
	while [ "$_TMP" = 'invalid' ]; do
		echo -e 'Please enter the full path to your device node.\nIf you are using USB storage such as a flash drive, it will most likely be /dev/sda\nIf you are using a (micro) SD card, it will most likely be /dev/mmcblk0\n'
		echo -e 'Available devices are:\n\n====================================================='
		lsblk -po name,vendor,model,size -e 31,7,254 | sed 's/NAME/NODE/g'
		echo -e '=====================================================\n'
		read -rp 'Device Node: ' _DEVICE
		if verify_block_device "$_DEVICE" > /dev/null 2>&1; then
			info 'Valid device'
			sleep 2
			echo 'Is this the correct device?'
			echo -e '\n====================================================='
			parted -s "$_DEVICE" print
			echo -e '=====================================================\n'
			_ANS='not_found'
			while [ "$_ANS" = 'not_found' ]; do
				read -rp 'Is this correct? [Y/N]: ' _YN
				case "$_YN" in
					Y|y|Yes|yes) _ANS='yes';;
					N|n|No|no) _ANS='no';;
					*) _ANS='not_found';;
				esac
				if [ "$_ANS" = 'yes' ]; then
					info "Device is '$_DEVICE'"
					_TMP='valid'
				elif [ "$_ANS" = 'no' ]; then
					echo -e 'Please select another device\n\n'
					sleep 1
					_TMP='invalid'
				fi
			done
		else
			echo -e '\n'
			echo 'Invalid entry.'
			sleep 2
		fi
	done
unset -v _TMP _ANS _YN
}





#======================================================#
#===== Filesystem and Mountpoints =====#
#======================================================#

btrfs(){
	prompt_block_device
	info "Installation target is '$DEVICE'"
	MOUNTPOINT='/etc/klipper'
	info "Root mountpoint is '$DEVICE'"
	# Mountpoint paths
	NGINXDIR="/etc/$NGINXNAME"
	PYTHONDIR="/usr/lib/$PYTHONNAME"
	GCCDIR="/usr/lib/$GCCNAME"
	FORMAT='false'

	if [ "$FORMAT" = 'true' ]; then
		mkfs.btrfs "/dev/$DEVICE" --label "KlipperWRT" -f
		# Evaluate `block info $DEVICE` to obtain the uuid as a variable
		# This works by evaluating any string matching `VAR=value` from stdin, and declaring it a variable
		eval "$(block info ${DEVICE} | grep -o -e "UUID=\S*")"

		# Create parent directory
		mkdir -p "$MOUNTPOINT"
		# Mount the device correctly
		mount "/dev/$DEVICE" "$MOUNTPOINT"

		# Create the gcc subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$GCCNAME"
		mkdir -p "$GCCDIR"


		# Create the python3.10 subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$PYTHONNAME"
		mkdir -p "$PYTHONDIR"


		# Create the nginx subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$NGINXNAME"
		mkdir -p "$NGINXDIR"
		# Copy the preexisting files from `/etc/nginx/*` to the btrfs subvolume
		cp -r /etc/nginx/* "$MOUNTPOINT/$NGINXNAME/" 

		# Create the klipper subvolume
		btrfs subvolume create "$MOUNTPOINT/$KLIPPERNAME"
	else
		info 'Not formatting drive'
	fi
	# Add an anonymous section, mount
	# This section is for the root volume
	uci add fstab mount
	# Add fstab options to the last anonymous section
	uci set fstab.@mount[-1].target="$MOUNTPOINT"
	uci set fstab.@mount[-1].fstype='btrfs'
	uci set fstab.@mount[-1].enabled='1'
	uci set fstab.@mount[-1].uuid="$UUID"

	uci commit fstab

	# Add a bindmount
	# This section is for the python installation
	create_uci_bindmount "$PYTHONDIR" "$PYTHONNAME" "$UUID"

	# Add a bindmount
	# This is for the gcc installation
	create_uci_bindmount "$GCCDIR" "$GCCNAME" "$UUID"

	# Add a bindmount
	# This is for the nginx files
	create_uci_bindmount "$NGINXDIR" "$NGINXNAME" "$UUID"


	# Unmount the $DEVICE in case it is in use
	#umount -q "$DEVICE"
	#block umount
	#block mount
	#/etc/init.d/klippertab boot

	# Test if mountpoints mounted correctly
	BINDMNT='true'
	# Test python
	bindtest "$MOUNTPOINT/$PYTHONNAME" "$PYTHONDIR"
	# Test gcc
	bindtest "$MOUNTPOINT/$GCCNAME" "$GCCDIR"
	# Test nginx
	bindtest "$MOUNTPOINT/$NGINXNAME" "$NGINXDIR"

	# If any of the tests failed, abort
	if [ "$BINDMNT" = "false" ]; then
		echoerr 'One or more tests failed. Aborting.'
	else
		info 'Tests passed, proceeding to next step'
	fi
}

create_uci_defaults(){
	# This script will add the default configuration to a uci section, which will be read by the service files.
	# Service files are in `/etc/init.d/`

	# Full path to the python executable. 
	PYTHONPATH='/usr/bin/python'
	# Full path to the python executable for each service. By default, this will be the same as $PYTHONPATH
	# If you need to specify a different python installation for each program, do that here
	PYTHONPATH_KLIPPER="$PYTHONPATH"
	PYTHONPATH_MOONRAKER="$PYTHONPATH"
	PYTHONPATH_DWC="$PYTHONPATH"
	# Name of subvolume
	PYTHONNAME='python3.10'
	GCCNAME='gcc'
	KLIPPERNAME='klipper'
	NGINXNAME='nginx'
	# Name of the directory to bind mount
	# This may change between python versions, check the wiki if "Not enough space" errors are thrown

	#===================#
	#====  Klipper  ====#
	#===================#

	# Create a new subsystem in UCI named 'klipper'
	uci import klipper < /dev/null

	# Define the section, `klipper.path`
	uci set klipper.path='path'
	# Define values in the `klipper.path` section
	uci set klipper.path.python="$PYTHONPATH_KLIPPER"
	uci set klipper.path.klipper_py='/path/to/klipper.py'
	uci set klipper.path.printer_cfg='/path/to/printer.cfg'
	uci set klipper.path.klipper_log='/path/to/klipper.log'
	
	# Define the section, `klipper.subvol`
	uci set klipper.subvol='subvol'
	# Define values
	uci set klipper.subvol.nginx="$NGINXNAME"
	uci set klipper.subvol.python="$PYTHONNAME"
	uci set klipper.subvol.gcc="$GCCNAME"
	uci set klipper.subvol.klipper="$KLIPPERNAME"
	
	# Commit changes
	uci commit klipper


	#################
	##  Moonraker  ##
	#################

	# Create a new subsystem in UCI named 'moonraker'
	uci import moonraker < /dev/null

	# Define the section, `moonraker.path`
	uci set moonraker.path='moonraker'
	# Define values in the `moonraker.path` section
	uci set moonraker.path.python="$PYTHONPATH_MOONRAKER"
	uci set moonraker.path.moonraker_py='/path/to/moonraker.py'
	uci set moonraker.path.printer_data='/path/to/printer.cfg'
	# These values are used by `/etc/init.d/moonraker`

	# Commit changes
	uci commit moonraker


	########################
	##  Duet Web Control  ##
	########################

	# Create a new subsystem in UCI named 'dwc'
	uci import dwc < /dev/null

	# Define the section, `dwc.path`
	uci set dwc.path='dwc'
	# Define values in the `dwc.path` section
	uci set dwc.path.python="$PYTHONPATH_DWC"
	uci set dwc.path.dwc_py='/path/to/dwc.py'
	# Commit changes
	uci commit dwc
}