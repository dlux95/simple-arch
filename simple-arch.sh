#!/bin/bash
echo "Welcome to the Simple Arch Installer!"
echo "We now ask a few questions about the system. At the end you need to type in a new root password."

read -e -p "default keymap: " -i "de" SIMPLE_KEYMAP
read -e -p "root disk: " -i "/dev/sda" SIMPLE_DISK
read -e -p "default installation target: " -i "base" SIMPLE_TARGET
read -e -p "hostname: " -i "archlinux-$RANDOM" SIMPLE_HOSTNAME
read -e -p "timezone: " -i "Europe/Berlin" SIMPLE_TZ


loadkeys $SIMPLE_KEYMAP
timedatectl set-ntp true

dd if=/dev/zero of=$SIMPLE_DISK bs=1M count=64
parted $SIMPLE_DISK mklabel msdos mkpart primary ext4 1MiB 100%
mkfs.ext4 "$SIMPLE_DISK"1

mount "$SIMPLE_DISK"1 /mnt

echo "Server = https://mirror.orbit-os.com/archlinux/$repo/os/$arch" > /etc/pacman.d/mirrorlist
pacstrap /mnt $SIMPLE_TARGET
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/$SIMPLE_TZ /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
arch-chroot /mnt /bin/bash -c "locale-gen"

arch-chroot /mnt /bin/bash -c "echo \"KEYMAP=$SIMPLE_KEYMAP\" >> /etc/vconsole.conf"
arch-chroot /mnt /bin/bash -c "echo \"$SIMPLE_HOSTNAME\" >> /etc/hostname"
arch-chroot /mnt /bin/bash -c "echo \"127.0.0.1        localhost\"  > /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"::1              localhost\" >> /etc/hosts"
arch-chroot /mnt /bin/bash -c "echo \"127.0.1.1        $SIMPLE_HOSTNAME\" >> /etc/hosts"

arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Sy grub"
arch-chroot /mnt /bin/bash -c "grub-install $SIMPLE_DISK"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd"

echo "Now chaning root password"
arch-chroot /mnt /bin/bash -c "passwd"

umount /mnt
eject /dev/sr0

echo "Rebooting"
reboot
