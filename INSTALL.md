The following is a brief installation tutorial for [Arch Linux][1]. It assumes
familiarity with the Arch [Beginner's Guide][2] and [Installation Guide][3].

It will provide a system with full-disk encryption using [LVM on LUKS][4].
Two methods are presented here, the more traditional "BIOS mode", where
there is no separate `/boot` partition. The entire installation is encrypted
and booted via [Grub's crypto hooks][5].  The second method is "UEFI mode" which
will use a GPT and show you how to make [separately-encrypted boot and root partitions][6],
while only /boot/efi is left unecrypted.

Use your system's setup interface to choose UEFI or legacy/BIOS mode as appropriate.

On some newer systems (e.g. Dell XPS 15), set SATA operation mode to AHCI.

Boot into the Arch installer.

If your console font is tiny ([HiDPI][7] systems), set a new font.

    $ setfont sun12x22

Connect to the Internet.

Verify that the [system clock is up to date][8].

    $ timedatectl set-ntp true
    
(BIOS mode) Create a single partition for LUKS.

    $ parted -s /dev/sda mklabel msdos
    $ parted -s /dev/sda mkpart primary 2048s 100%

(UEFI mode) Create partitions for EFI, boot, and root.

    $ parted -s /dev/sda mklabel gpt
    $ parted -s /dev/sda mkpart primary fat32 1MiB 513MiB
    $ parted -s /dev/sda set 1 boot on
    $ parted -s /dev/sda set 1 esp on
    $ parted -s /dev/sda mkpart primary 513MiB 1024MiB
    $ parted -s /dev/sda mkpart primary 1024MiB 100%
    $ mkfs.vfat -F32 /dev/nvme0n1p1

Create and mount the encrypted root filesystem. Note that for UEFI systems
this will be partition 3.

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

(UEFI mode) Encrypt the boot partition using a separate passphrase from
the root partition, then mount the boot and EFI partitions.

    $ cryptsetup luksFormat /dev/sda2
    $ cryptsetup luksOpen /dev/sda2 cryptboot
    $ mkfs.ext4 /dev/mapper/cryptboot
    $ mkdir /mnt/boot
    $ mount /dev/mapper/cryptboot /mnt/boot
    $ mkdir /mnt/boot/efi
    $ mount /dev/sda1 /mnt/boot/efi

Optionally [edit the mirror list][9].

    $ vi /etc/pacman.d/mirrorlist

Install the [base system][10].

    $ pacstrap -i /mnt base base-devel net-tools wireless_tools dialog wpa_supplicant git grub ansible
    (UEFI mode) $ pacstrap /mnt efibootmgr

Generate and verify [fstab][11].

    $ genfstab -U -p /mnt >> /mnt/etc/fstab
    $ less /mnt/etc/fstab

Change root into the base install and perform [base configuration tasks][12].

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

Set your mkinitcpio encrypt/lvm2 hooks and rebuild.

    $ sed -i 's/^HOOKS=.*/HOOKS="base udev autodetect modconf block keyboard encrypt lvm2 resume filesystems fsck"/' /etc/mkinitcpio.conf
    $ mkinitcpio -p linux

(BIOS mode) Add a keyfile to decrypt the root volume and properly set the hooks.

    $ dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
    $ cryptsetup luksAddKey /dev/sda1 /crypto_keyfile.bin
    $ chmod 000 /crypto_keyfile.bin
    $ sed -i 's/^FILES=.*/FILES="\/crypto_keyfile.bin"/' /etc/mkinitcpio.conf
    $ mkinitcpio -p linux

(UEFI mode) Add a keyfile to decrypt and mount the boot volume during startup.

    $ dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
    $ cryptsetup luksAddKey /dev/sda2 /crypto_keyfile.bin
    $ chmod 000 /crypto_keyfile.bin
    $ echo "cryptboot /dev/sda2 /crypto_keyfile.bin luks" >> /etc/crypttab

Configure GRUB.

    $ echo GRUB_ENABLE_CRYPTODISK=y >> /etc/default/grub

    # BIOS mode
    $ sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda1:lvm:allow-discards resume=\/dev\/mapper\/arch-swap"/' /etc/default/grub
    $ grub-install /dev/sda
    $ chmod -R g-rwx,o-rwx /boot

    # UEFI mode - set the UUID of the encrpyted root device
    # e.g. blkid /dev/sda3 | awk '{print $3}'
    $ sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="cryptdevice=UUID=<your-rootdevice-UID>:lvm:allow-discards root=\/dev\/mapper\/arch-root resume=\/dev\/mapper\/arch-swap"/' /etc/default/grub
    $ grub-mkconfig -o /boot/grub/grub.cfg
    $ grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --recheck
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
[6]: https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Encrypted_boot_partition_.28GRUB.29
[7]: https://wiki.archlinux.org/index.php/HiDPI
[8]: https://wiki.archlinux.org/index.php/Beginners'_guide#Update_the_system_clock
[9]: https://wiki.archlinux.org/index.php/Beginners'_Guide#Select_a_mirror
[10]: https://wiki.archlinux.org/index.php/Beginners'_Guide#Install_the_base_system
[11]: https://wiki.archlinux.org/index.php/Beginners'_guide#Generate_an_fstab
[12]: https://wiki.archlinux.org/index.php/Beginners'_guide#Configure_the_base_system
