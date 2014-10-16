#!/bin/bash

IMAGE="minimal_pi.img"
BR="/home/nico/buildroot"
SHARE="/media/sf_VMShare"

# Some sanity checks
if [ ! -f "$BR/output/images/rootfs.tar" ]
then
	echo "Could not find root file system"
	exit
fi

if [ ! -f "$BR/output/images/zImage" ]
then
        echo "Could not find linux kernel image"
	exit
fi

if [ ! -d "$BR/output/images/rpi-firmware" ]
then
        echo "Could not find rpi-firmware"
	exit
fi

if [ ! -d "$BR/output/images/rpi-firmware" ]
then
        echo "Could not find shared dir $SHARE"
	exit
fi


echo "Starting with creation of sd card image for pi"

# Create image file
cd ~
dd if=/dev/zero of="$IMAGE" bs=1M count=50

# Create partitions
echo "n
p
1

+10M
t
4
n
p
2


w
"|fdisk "$IMAGE";

sync

# Map image
sudo kpartx -a "$IMAGE"

sleep 2

# Create filesystems
sudo mkfs.vfat -F 16 -n boot /dev/mapper/loop0p1
sudo mkfs.ext4 -L rootfs /dev/mapper/loop0p2

sync

# Mount partitions
sudo mkdir -p /mnt/boot
sudo mkdir -p /mnt/rootfs

sudo mount -o rw,sync /dev/mapper/loop0p1 /mnt/boot
sudo mount -o rw,sync /dev/mapper/loop0p2 /mnt/rootfs

# Copy files to partitions
sudo cp "$BR/output/images/zImage" /mnt/boot
sudo cp "$BR"/output/images/rpi-firmware/* /mnt/boot
sudo tar -xpsf "$BR/output/images/rootfs.tar" -C /mnt/rootfs

# Add some params to boot options
echo "dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait" | sudo tee /mnt/boot/cmdline.txt

sleep 2
sync

# Unmount
sudo umount /mnt/boot
sudo umount /mnt/rootfs

sync

# Unmap image2
sudo kpartx -d "$IMAGE"

# Copy file to share
cp "$IMAGE" "$SHARE"

echo "Done"

