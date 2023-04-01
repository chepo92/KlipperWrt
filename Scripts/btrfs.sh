#!/bin/sh
# Bind mounts
DEVICE='sda1'
MOUNTPOINT='/etc/klipper'
# Name of the directory to mount under `/usr/lib/`. This may change between python versions, check the wiki if "Not enough space" errors are thrown
PYTHONNAME='python3.10'
GCCNAME='gcc'
KLIPPERNAME='klipper'
# Mountpoint paths
NGINX='/etc/nginx'
PYTHON="/usr/lib/$PYTHONNAME"
GCC="/usr/lib/$GCCNAME"
# Evaluate `block info $DEVICE` to obtain the uuid as a variable
eval "$(block info ${DEVICE} | grep -o -e "UUID=\S*")"

# Create parent directory
mkdir -p "$MOUNTPOINT"
mount "/dev/$DEVICE" "$MOUNTPOINT"

# Create the gcc subvolume, make the bind mount directory
btrfs subvol create "$MOUNTPOINT/$GCCNAME"
mkdir -p "$GCC"


# Create the python3.10 subvolume, make the bind mount directory
btrfs subvol create "$MOUNTPOINT/$PYTHONNAME"
mkdir -p "$PYTHON"


# Create the nginx subvolume, make the bind mount directory
btrfs subvol create "$MOUNTPOINT/$NGINXNAME"
mkdir -p "$NGINX"

# Create the klipper subvolume
btrfs subvol create "$MOUNTPOINT/$KLIPPERNAME"


# fstab.@mount[0]=mount
# fstab.@mount[0].uuid='cf7da29e-73f6-4912-8b8e-0abb01e9a780'
# fstab.@mount[0].target='/etc/klipper'
# fstab.@mount[0].fstype='btrfs'
# fstab.@mount[0].enabled='1'
# fstab.@mount[1]=mount
# fstab.@mount[1].target='/usr/lib/gcc'
# fstab.@mount[1].fstype='btrfs'
# fstab.@mount[1].options='subvol=/gcc'
# fstab.@mount[1].uuid='cf7da29e-73f6-4912-8b8e-0abb01e9a780'
# fstab.@mount[1].enabled='1'
# fstab.@mount[2]=mount
# fstab.@mount[2].target='/usr/lib/python3.10'
# fstab.@mount[2].fstype='btrfs'
# fstab.@mount[2].options='subvol=/python3.10'
# fstab.@mount[2].enabled='1'
# fstab.@mount[2].uuid='cf7da29e-73f6-4912-8b8e-0abb01e9a780'