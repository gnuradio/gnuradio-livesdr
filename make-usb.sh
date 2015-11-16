#!/bin/sh

. config/config-vars

# Format destination as FAT32
if [ -z $1 ] ; then
    echo Device must be specified.
    exit 1
fi

if ! [ -b $1 ] ; then
    echo Filespec $1 is not a device file.
    exit 1
fi

echo Using device node $1

if mount | grep -q $1 ; then
    echo Device node is mounted, unmounting
    sudo umount $1
fi

echo Formatting device as VFAT...
sudo mkfs.vfat -I -n GNURADIO $1 || {
    echo Format failed!
    exit 1
}

echo Mounting destination device...
sudo mount $1 mnt/usb || {
    echo Mount failed!
}

echo Invoking Unetbootin...
sudo unetbootin rootcheck=no \
    method=diskimage \
    installtype=usb \
    isofile=iso/$REMASTER_NAME \
    targetdrive=$1 \
    persistentspace=4096 || {
    echo Unetbootin failed!
    exit 1
}

echo Copying custom boot files...
sudo cp custom/grub/grub.cfg mnt/usb/boot/grub/ &&
sudo cp custom/grub/syslinux.cfg mnt/usb/ || {
    echo Copying failed!
    exit 1
}

echo Unmounting target...
sync
sudo umount mnt/usb || {
    echo Unmounting failed!
    exit 1
}
