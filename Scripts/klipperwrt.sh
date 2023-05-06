#!/bin/sh


# This script relies on a couple of packages. I tried to keep them down to a minimum, so as to reduce bloat.
# They are:
# curl (Used in some services)
# btrfs-progs block-mount e2fsprogs parted (Filesystem support)
# kmod-usb-storage (for USB drive support)
# kmod-usb-storage-uas kmod-usb-ohci kmod-usb-uhci kmod-usb3 (For USB 3 - you can exclude these if your device doesn't have USB 3)
# nginx-ssl (For Fluidd/Mainsail/DWC)
# patch libsodium usbutils (Dependencies for klipper)
# git-http unzip lsblk wipefs (used in the script)
# kmod-usb-serial kmod-usb-serial-cp210x (for communicating with the printer. 
# Make sure to select the appropriate kmod for your UART controller)


#=======================#
#=====  Variables  =====#
#=======================#

# These are variables are used in various places in the script, but not exposed to the user for customization. They can be changed manually, but things might break;
# use caution and know what you are doing beforehand.


# Full path to the python executable. 
PYTHONPATH='/usr/bin/python'
# Full path to the python executable for each service. By default, this will be the same as $PYTHONPATH
# If you need to specify a different python installation for each program (for compatibility reasons), do that here
PYTHONPATH_KLIPPER="$PYTHONPATH"
PYTHONPATH_MOONRAKER="$PYTHONPATH"
# Name of subvolume
PYTHONVOL='python3.10'
GCCVOL='gcc'
KLIPPERVOL='klipper'
NGINXVOL='nginx'
MOONRAKERVOL='moonraker'
PRINTER_DATAVOL='printer_data'
# Mountpoint paths
NGINXDIR="/etc/$NGINXVOL"
PYTHONDIR="/usr/lib/$PYTHONVOL"
GCCDIR="/usr/lib/$GCCVOL"
# Colours to be used for echoerr and info
RED='\033[0;31m'	# Red
CYAN='\033[0;36m'	# Cyan
NC='\033[0m' 		# No Color

# shellcheck disable=SC1091,SC3046
source /lib/functions.sh
config_load klipper

#=========================#
#======  Functions  ======#
#=========================#
# These functions are strictly repeatable code blocks
echoerr(){
	# Just a regular echo, but renamed/colored for readability.
	# Also logs to stderr and adds a prefix. Fancy!
	echo -e "[${RED}ERROR${NC}] $*" 1>&2
}
info(){
	# Just a regular echo, but renamed/colored for readability
	# Also adds a prefix. Fancy!
	echo -e "[${CYAN}INFO${NC}]${CYAN} $*${NC}"
}
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

	# create_uci_bindmount /path/to/targetdir program your-unique-uuid
	# create_uci_bindmount $1				  $2	  $3
	info "Creating bind mount entry for $2"
	uci add klipper mount
	# Add fstab options to the last anonymous (mount) section
	uci set klipper.@mount[-1].target="$1"
	uci set klipper.@mount[-1].program="$2"
	uci set klipper.@mount[-1].options="subvol=SUBVOL_UCI_REPLACE"
	uci set klipper.@mount[-1].enabled='enabled'
	uci set klipper.@mount[-1].uuid="$3"
	# Commit changes
	uci commit klipper
}
verify_block_device(){
	# Verify that the block device $1 exists. Returns 0 if found, 1 if not
	lsblk -npo name -e 31,7,254 | grep "$1"
}
prompt_block_device(){
	_TMP='invalid'
	while [ "$_TMP" = 'invalid' ]; do
		echo -e 'Please enter the full path to your device node.\n'
		echo -e "[WARNING] ${RED}========================================${NC}"
		echo -e "          ${RED}ALL DATA ON THIS DEVICE WILL BE DELETED!${NC}"
		echo -e "          ${RED}========================================${NC}\n"
		echo -e 'If you have valuable data on the device, back it up now. Press ctrl + c to exit the script.\n\n'
		sleep 5
		echo -e 'If you are using USB storage such as a flash drive, it will most likely be /dev/sda\nIf you are using a (micro) SD card, it will most likely be /dev/mmcblk0\n'
		echo -e 'Available devices are:\n\n====================================================='
		lsblk -dpo name,vendor,model,size -e 31,7,254 | sed 's/NAME/NODE/g'
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
					_PARTITION="${_DEVICE}1"
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
			sleep 1
		fi
	done
	unset -v _TMP _ANS _YN
}
# These two, however, are exceptions - they are only used once, but have been placed here for readability.
install_dwc(){
	echoerr 'Not implemented! Please choose another frontend.'
	# PYTHONPATH_DWC="$PYTHONPATH"
	# DWCVOL='dwc'
	# # Create a new subsystem in UCI named 'dwc'
	# uci import dwc < /dev/null
	# # Define the section, `dwc.path`
	# uci set dwc.path='dwc'
	# # Define values in the `dwc.path` section
	# uci set dwc.path.python="$PYTHONPATH_DWC"
	# uci set dwc.path.dwc_py="$MOUNTPOINT/$DWCVOL/dwc.py"
	# # Commit changes
	# uci commit dwc
}
install_fluidd(){
	FLUIDDVOL='fluidd'
	uci set klipper.subvol.fluidd="$FLUIDDVOL"
	uci commit klipper
	btrfs subvolume create "$MOUNTPOINT/$FLUIDDVOL"
	wget -q -O "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip" https://github.com/cadriel/fluidd/releases/latest/download/fluidd.zip && \
	unzip "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip" -d "$MOUNTPOINT/$FLUIDDVOL" && \
	rm "$MOUNTPOINT/$FLUIDDVOL/fluidd.zip"
	mkdir -p "$MOUNTPOINT/$PRINTER_DATAVOL/config"
	wget -q -O "$MOUNTPOINT/$PRINTER_DATAVOL/config/moonraker.conf" https://raw.githubusercontent.com/TheRealGramdalf/KlipperWrt-EX/main/Configs/fluidd_moonraker.conf
	wget -q -O /etc/nginx/conf.d/fluidd.conf https://raw.githubusercontent.com/TheRealGramdalf/KlipperWrt-EX/main/Configs/fluidd.conf
    wget https://github.com/TheRealGramdalf/KlipperWrt-EX/raw/main/Configs/fluidd.cfg -P "$MOUNTPOINT/$PRINTER_DATAVOL/config/"
}



#==========================#
#=====  Installation  =====#
#==========================#

select_frontend(){
	echo 'Which frontend would you like to use?'
	echo -e 'Options are:\n'
	echo '====================================='
	echo '0) Abort'
	echo '1) Fluidd'
	echo '2) Mainsail'
	echo '3) Duet Web Control (Not implemented)'
	echo '====================================='
	_ANS='not_found'
	while [ "$_ANS" = 'not_found' ]; do
		read -rp 'Select your frontend: ' _ANS
		case "$_ANS" in
			0) _ANS='abort' ;;
			1) _FRONTEND='fluidd' ;;
			2) _FRONTEND='mainsail' ;;
			3) _FRONTEND='dwc' ;;
			*) _ANS='not_found' ;;
		esac
		if [ "$_ANS" = 'abort' ]; then
			exit 1
		fi
	done
	unset -v _ANS
}
make_btrfs(){
	prompt_block_device
	info "Installation target is '$_DEVICE'"


	# Create a new subsystem in UCI named 'klipper'
	uci import klipper < /dev/null

	# Define the section, `klipper.subvol`
	uci set klipper.subvol='subvol'
	# Define values
	uci set klipper.subvol.nginx="$NGINXVOL"
	uci set klipper.subvol.python="$PYTHONVOL"
	uci set klipper.subvol.gcc="$GCCVOL"
	uci set klipper.subvol.klipper="$KLIPPERVOL"
	uci set klipper.subvol.moonraker="$MOONRAKERVOL"
	uci set klipper.subvol.printer_data="$PRINTER_DATAVOL"
	uci set klipper.subvol.log="$LOGVOL"

	# Commit changes
	uci commit klipper

	MOUNTPOINT='/etc/klipper'
	info "Root mountpoint is '$MOUNTPOINT'"

	
	# The following if statement is merely future proofing. In the future, I may add the option to migrate an existing installation.
	FORMAT='true'
	if [ "$FORMAT" = 'true' ]; then
		echo "Formatting device '$_DEVICE'. Last chance to abort. (ctrl +c)"
		sleep 5
		echo "Not interrupted, continuing..."
		parted -s "$_DEVICE" -- mktable gpt mkpart KlipperWRT 0% 100%
		wipefs -a "$_PARTITION"
		mkfs.btrfs -f "$_PARTITION"
		# Evaluate `block info $_DEVICE` to obtain the uuid as a variable
		# This works by evaluating any string matching `VAR=value` from stdin, and declaring it a variable
		eval "$(block info "$_PARTITION" | grep -o -e "UUID=\S*")"
		# Create parent directory
		mkdir -p "$MOUNTPOINT"
		# Mount the device correctly
		mount "$_PARTITION" "$MOUNTPOINT"

		# Create the gcc subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$GCCVOL"
		mkdir -p "$GCCDIR"


		# Create the python3.10 subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$PYTHONVOL"
		mkdir -p "$PYTHONDIR"


		# Create the nginx subvolume, make the bind mount directory
		btrfs subvolume create "$MOUNTPOINT/$NGINXVOL"
		mkdir -p "$NGINXDIR"
		# Copy the preexisting files from `/etc/nginx/*` to the btrfs subvolume
		cp -r /etc/nginx/* "$MOUNTPOINT/$NGINXVOL/" 

		# Create the klipper subvolume
		btrfs subvolume create "$MOUNTPOINT/$KLIPPERVOL"

		# Create the moonraker subvolume
		btrfs subvolume create "$MOUNTPOINT/$MOONRAKERVOL"

		# Create printer_data subvolume
		btrfs subvolume create "$MOUNTPOINT/$PRINTER_DATAVOL"
		if [ "$_FRONTEND" = 'dwc' ]; then
			btrfs subvolume create "$MOUNTPOINT/$DWCVOL"
		fi
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
	create_uci_bindmount "$PYTHONDIR" "python" "$UUID"

	# Add a bindmount
	# This is for the gcc installation
	create_uci_bindmount "$GCCDIR" "gcc" "$UUID"

	# Add a bindmount
	# This is for the nginx files
	create_uci_bindmount "$NGINXDIR" "nginx" "$UUID"

	info 'Downloading klippertab to /etc/init.d/...'
	wget -q 'https://raw.githubusercontent.com/TheRealGramdalf/KlipperWrt-EX/main/Services/klippertab' -O /etc/init.d/klippertab
	chmod 775 /etc/init.d/klippertab

	# Unmount the $_DEVICE in case it is in use
	umount "$_PARTITION"
	block umount
	block mount
	/etc/init.d/klippertab boot

	# Test if mountpoints mounted correctly
	BINDMNT='true'
	# Test python
	bindtest "$MOUNTPOINT/$PYTHONVOL" "$PYTHONDIR"
	# Test gcc
	bindtest "$MOUNTPOINT/$GCCVOL" "$GCCDIR"
	# Test nginx
	bindtest "$MOUNTPOINT/$NGINXVOL" "$NGINXDIR"

	# If any of the tests failed, abort
	if [ "$BINDMNT" = "false" ]; then
		echoerr 'One or more tests failed. Aborting.'
		exit 1
	else
		info 'Tests passed, proceeding to next step'
	fi
}
create_uci_defaults(){
	# This function will add the default configuration to a uci section, which will be read by the service files.
	# Service files are in /etc/init.d/

	#=====================#
	#=====  Klipper  =====#
	#=====================#


	# Define the section, `klipper.path`
	uci set klipper.path='path'
	# Define values in the `klipper.path` section
	uci set klipper.path.python="$PYTHONPATH_KLIPPER"
	uci set klipper.path.klipper_py="$MOUNTPOINT/$KLIPPERVOL/klippy/klippy.py"
	uci set klipper.path.printer_cfg="$MOUNTPOINT/$PRINTER_DATAVOL/printer.cfg"
	uci set klipper.path.klipper_log="$MOUNTPOINT/$LOGVOL/klipper.log"

	# Commit changes
	uci commit klipper

	#=======================#
	#=====  Moonraker  =====#
	#=======================#

	# Create a new subsystem in UCI named 'moonraker'
	uci import moonraker < /dev/null

	# Define the section, `moonraker.path`
	uci set moonraker.path='moonraker'
	# Define values in the `moonraker.path` section
	uci set moonraker.path.python="$PYTHONPATH_MOONRAKER"
	uci set moonraker.path.moonraker_py="$MOUNTPOINT/$MOONRAKERVOL/moonraker/moonraker.py"
	uci set moonraker.path.printer_data="$MOUNTPOINT/$PRINTER_DATAVOL"
	# These values are used by `/etc/init.d/moonraker`

	# Commit changes
	uci commit moonraker
}
install_backend(){
	_OPKG_TO_INSTALL='gcc python3 python3-pip python3-cffi python3-dev python3-greenlet python3-jinja2 python3-markupsafe python3-tornado python3-pillow python3-distro python3-curl python3-zeroconf python3-paho-mqtt python3-yaml python3-requests ip-full libsodium python3-pyserial'
	_PIP3_TO_INSTALL='python-can configparser pyserial-asyncio lmdb streaming-form-data inotify-simple libnacl preprocess-cancellation apprise ldap3 dbus-next'
	info 'Installing gcc and python via opkg'
	opkg update
	opkg install "$_OPKG_TO_INSTALL"
	pip install --upgrade pip setuptools
	pip install "$_PIP3_TO_INSTALL"

	info 'Cloning Moonraker...'
	git clone 'https://github.com/Arksine/moonraker.git' "$MOUNTPOINT/$MOONRAKERVOL"

	info 'Downloading moonraker to /etc/init.d/...'
	wget -q 'https://raw.githubusercontent.com/TheRealGramdalf/KlipperWrt-EX/main/Services/moonraker' -O /etc/init.d/moonraker
	chmod 775 /etc/init.d/moonraker

	info 'Cloning klipper...'
	git clone 'https://github.com/KevinOConnor/klipper.git' "$MOUNTPOINT/$KLIPPERVOL"

	info 'Downloading klipper to /etc/init.d/...'
	wget -q 'https://raw.githubusercontent.com/TheRealGramdalf/KlipperWrt-EX/main/Services/klipper' -O /etc/init.d/klipper
	chmod 775 /etc/init.d/klipper
}
install_frontend(){
	info 'Installing frontend...'
	if [ "$_FRONTEND" = 'fluidd' ]; then
		install_fluidd
	elif [ "$_FRONTEND" = 'mainsail' ]; then
		install_mainsail
	elif [ "$_FRONTEND" = 'dwc' ]; then
		install_dwc
	fi
}


select_frontend
make_btrfs
create_uci_defaults
#install_backend
#install_frontend