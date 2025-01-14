The following is a brief installation tutorial for [Arch Linux][1]. It assumes
familiarity with the Arch [Installation Guide][2].

It will provide a system with full-disk encryption using [LVM on LUKS][3],
including an [encrypted `/boot`][4]. The system will be bootable via both UEFI and
legacy BIOS.

On some newer systems (e.g. Dell XPS 15), set SATA operation mode to AHCI.

Boot into the Arch installer.

If your console font is tiny ([HiDPI][5] systems), set a new font.

    $ setfont sun12x22

Connect to the Internet.

Verify that the system clock is up to date.

    $ timedatectl set-ntp true

Store your desination disk in an environment variable.

    $ export DISK=/dev/nvme0n1

Create partitions for legacy boot, EFI, and root.

    $ parted -s $DISK mklabel gpt
    $ parted -s $DISK mkpart primary 2048s 2MiB
    $ parted -s $DISK set 1 bios_grub on
    $ parted -s $DISK mkpart primary fat32 2MiB 515MiB
    $ parted -s $DISK set 2 boot on
    $ parted -s $DISK set 2 esp on
    $ parted -s $DISK mkpart primary 540MiB 100%

Store your EFI and crypt devices in environment variables.

    # If you're using a NVME disk:
    $ export DEVEFI="$DISK"p2
    $ export DEVCRYPT="$DISK"p3
    # If you're using a SATA disk:
    $ export DEVEFI="$DISK"2
    $ export DEVCRYPT="$DISK"3

Create and mount the encrypted root filesystem.

    $ cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 $DEVCRYPT
    $ cryptsetup luksOpen $DEVCRYPT lvm
    $ pvcreate /dev/mapper/lvm
    $ vgcreate arch /dev/mapper/lvm
    $ lvcreate -L 8G arch -n swap
    $ lvcreate -l +100%FREE arch -n root
    $ lvreduce -L -256M arch/root
    $ lvdisplay
    $ mkswap -L swap /dev/mapper/arch-swap
    $ mkfs.ext4 /dev/mapper/arch-root
    $ mount /dev/mapper/arch-root /mnt
    $ swapon /dev/mapper/arch-swap

Format and mount the EFI partition.

    $ mkdir /mnt/efi
    $ mkfs.fat -F32 $DEVEFI
    $ mount $DEVEFI /mnt/efi

Optionally edit the mirror list.

    $ vim /etc/pacman.d/mirrorlist

Install the base system.

    $ pacstrap -i /mnt base base-devel linux linux-firmware lvm2 dhcpcd net-tools wireless_tools dialog wpa_supplicant efibootmgr vi git grub ansible

Generate and verify fstab.

    $ genfstab -U -p /mnt >> /mnt/etc/fstab
    $ less /mnt/etc/fstab

Change root into the base install and perform base configuration tasks.

    $ arch-chroot /mnt /bin/bash
    $ ln -s /usr/share/i18n/locales/en_DK /usr/share/i18n/locales/en_SE
    $ export LANG=en_US.UTF-8
    $ export TIME=en_SE.UTF-8
    $ echo $LANG UTF-8 >> /etc/locale.gen
    $ echo $TIME UTF-8 >> /etc/locale.gen
    $ locale-gen
    $ echo LANG=$LANG > /etc/locale.conf
    $ echo LC_TIME=$TIME >> /etc/locale.conf
    $ ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
    $ hwclock --systohc --utc
    $ echo mymachine > /etc/hostname
    $ systemctl enable dhcpcd.service
    $ passwd

Set your mkinitcpio encrypt/lvm2 hooks.

    $ sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 resume filesystems fsck)/' /etc/mkinitcpio.conf

Add a keyfile to decrypt the root volume and properly set the hooks.

    $ dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
    $ cryptsetup luksAddKey $DEVCRYPT /crypto_keyfile.bin
    $ chmod 000 /crypto_keyfile.bin
    $ sed -i 's/^FILES=.*/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
    $ mkinitcpio -p linux

Configure GRUB.

    $ echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub
    $ ROOTUUID=$(blkid $DEVCRYPT | awk '{print $2}' | cut -d '"' -f2)
    $ sed -i "s/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID="$ROOTUUID":lvm:allow-discards root=\/dev\/mapper\/arch-root resume=\/dev\/mapper\/arch-swap\"/" /etc/default/grub
    $ grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck --removable
    $ grub-install --target=i386-pc --recheck $DISK
    $ grub-mkconfig -o /boot/grub/grub.cfg
    $ chmod -R g-rwx,o-rwx /boot

Cleanup and reboot!

    $ exit
    $ umount -R /mnt
    $ reboot

Run ansible!


[1]: https://www.archlinux.org/
[2]: https://wiki.archlinux.org/index.php/Installation_guide
[3]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS
[4]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_(GRUB)
[5]: https://wiki.archlinux.org/index.php/HiDPI
