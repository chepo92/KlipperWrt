#!/bin/sh
DEVICE='sda1'
MOUNTPOINT='/etc/klipper'
# Name of the directory to mount under `/usr/lib/`. This may change between python versions, check the wiki if "Not enough space" errors are thrown
PYTHONNAME='python3.10'
GCCNAME='gcc'
KLIPPERNAME='klipper'
# Mountpoint paths
NGINXDIR='/etc/nginx'
PYTHONDIR="/usr/lib/$PYTHONNAME"
GCCDIR="/usr/lib/$GCCNAME"

mkfs.btrfs "$DEVICE" --label "KlipperWRT"
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
cp -r '/etc/nginx' "$MOUNTPOINT/$NGINXNAME/*" 

# Create the klipper subvolume
btrfs subvolume create "$MOUNTPOINT/$KLIPPERNAME"

# Add an anonymous section, mount
# This section is for the root volume
uci add fstab mount
# Add fstab options to the last anonymous section
uci set fstab.@mount[-1].target="$MOUNTPOINT"
uci set fstab.@mount[-1].fstype='btrfs'
uci set fstab.@mount[-1].enabled='1'
uci set fstab.@mount[-1].uuid="$UUID"

# Add an anonymous section, mount
# This section is for the python installation
uci add fstab mount
# Add fstab options to the last anonymous section
uci set fstab.@mount[-1].target="$PYTHONDIR"
uci set fstab.@mount[-1].fstype='btrfs'
uci set fstab.@mount[-1].options="subvol=$PYTHONNAME"
uci set fstab.@mount[-1].enabled='1'
uci set fstab.@mount[-1].uuid="$UUID"

# Add an anonymous section, mount
# This is for the gcc installation
uci add fstab mount
# Add fstab options to the last anonymous section
uci set fstab.@mount[-1].target="$GCCDIR"
uci set fstab.@mount[-1].fstype='btrfs'
uci set fstab.@mount[-1].options="subvol=$GCCNAME"
uci set fstab.@mount[-1].enabled='1'
uci set fstab.@mount[-1].uuid="$UUID"

# Add an anonymous section, mount
# This is for the nginx files
uci add fstab mount
# Add fstab options to the last anonymous section
uci set fstab.@mount[-1].target="$NGINXDIR"
uci set fstab.@mount[-1].fstype='btrfs'
uci set fstab.@mount[-1].options="subvol=$NGINXNAME"
uci set fstab.@mount[-1].enabled='1'
uci set fstab.@mount[-1].uuid="$UUID"

uci commit fstab

# Unmount the $DEVICE in case it is in use
umount -q "$DEVICE"
block umount
block mount

# TODO: Add a test that checks whether or not the bind mounts worked correctly, by creating a file in $MOUNTPOINT/$NGINXNAME checking that it exists in $NGINXDIR
