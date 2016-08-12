The following is a brief installation tutorial for [Arch Linux][1]. It assumes
familiarity with the Arch [Beginner's Guide][2] and [Installation Guide][3].

It will provide a system with full-disk encryption using [LVM on LUKS][4].
There is no separate `/boot` partition. The entire installation is encrypted
and booted via [Grub's crypto hooks][5].

On newer systems, disable UEFI / enable BIOS ("legacy") mode.

On some newer systems (e.g. Dell XPS 15), set SATA operation mode to AHCI.

Boot into the Arch installer.

If your console font is tiny ([HiDPI][6] systems), set a new font.

    $ setfont sun12x22

Connect to the Internet.

Verify that the [system clock is up to date][7].

    $ timedatectl set-ntp true
    
Create a single partition for LUKS.

    $ parted -s /dev/sda mklabel msdos
    $ parted -s /dev/sda mkpart primary 2048s 100%

Create and mount the encrypted filesystem.

    $ cryptsetup luksFormat /dev/sda1
    $ cryptsetup luksOpen /dev/sda1 lvm
    $ pvcreate /dev/mapper/lvm
    $ vgcreate arch /dev/mapper/lvm
    $ lvcreate -L 8G arch -n swap
    $ lvcreate -L 30G arch -n root
    $ lvcreate -l +100%FREE arch -n home
    $ lvdisplay
    $ mkswap -L swap /dev/mapper/arch-swap
    $ mkfs.ext4 /dev/mapper/arch-root
    $ mkfs.ext4 /dev/mapper/arch-home
    $ mount /dev/mapper/arch-root /mnt
    $ mkdir /mnt/home
    $ mount /dev/mapper/arch-home /mnt/home
    $ swapon /dev/mapper/arch-swap

Optionally [edit the mirror list][8].

    $ vi /etc/pacman.d/mirrorlist

Install the [base system][9].

    $ pacstrap -i /mnt base base-devel net-tools wireless_tools dialog wpa_supplicant git

Generate and verify [fstab][10].

    $ genfstab -U -p /mnt >> /mnt/etc/fstab
    $ less /mnt/etc/fstab

Change root into the base install and perform [base configuration tasks][11].

    $ arch-chroot /mnt /bin/bash
    $ echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
    $ locale-gen
    $ echo LANG=en_US.UTF-8 > /etc/locale.conf
    $ export LANG=en_US.UTF-8
    $ ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
    $ hwclock --systohc --utc
    $ echo mymachine > /etc/hostname
    $ systemctl enable dhcpcd.service
    $ passwd

Add a key file to decrypt the volume and properly set the hooks.

    $ dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
    $ cryptsetup luksAddKey /dev/sda1 /crypto_keyfile.bin
    $ chmod 000 /crypto_keyfile.bin
    $ sed -i 's/^FILES=.*/FILES="\/crypto_keyfile.bin"/' /etc/mkinitcpio.conf
    $ sed -i 's/^HOOKS=.*/HOOKS="base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck"/' /etc/mkinitcpio.conf
    $ mkinitcpio -p linux

Install GRUB.

    $ pacman -S grub
    $ echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub
    $ sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda1:lvm:allow-discards resume=\/dev\/mapper\/arch-swap"/' /etc/default/grub
    $ grub-mkconfig -o /boot/grub/grub.cfg
    $ grub-install /dev/sda
    $ chmod -R g-rwx,o-rwx /boot

Cleanup and reboot!

    $ exit
    $ umount -R /mnt
    $ reboot

Run ansible!


[1]: https://www.archlinux.org/
[2]: https://wiki.archlinux.org/index.php/Beginners'_guide
[3]: https://wiki.archlinux.org/index.php/Installation_guide
[4]: https://wiki.archlinux.org/index.php/Encrypted_LVM#LVM_on_LUKS
[5]: http://www.pavelkogan.com/2014/05/23/luks-full-disk-encryption/
[6]: https://wiki.archlinux.org/index.php/HiDPI
[7]: https://wiki.archlinux.org/index.php/Beginners'_guide#Update_the_system_clock
[8]: https://wiki.archlinux.org/index.php/Beginners'_Guide#Select_a_mirror
[9]: https://wiki.archlinux.org/index.php/Beginners'_Guide#Install_the_base_system
[10]: https://wiki.archlinux.org/index.php/Beginners'_guide#Generate_an_fstab
[11]: https://wiki.archlinux.org/index.php/Beginners'_guide#Configure_the_base_system
