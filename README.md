# Spark

Spark is an [Ansible][1] playbook meant to provision a personal machine running
[Arch Linux][2]. It is intended to run locally on a fresh Arch install (ie,
taking the place of any [post-installation][3]), but due to Ansible's
idempotent nature it may also be run on top of an already configured machine.

Spark assumes it will be run on a laptop and performs some configuration based
on this assumption. This behaviour may be changed by removing the `laptop` role
from the playbook or by skipping the `laptop` tag.

If Spark is run on either a ThinkPad or a Framework, it will detect this and
execute platform-specific tasks.

## Running

First, sync mirrors and install Ansible:

    $ pacman -Syy python-passlib ansible

Second, install and update the submodules:

    $ git submodule init && git submodule update

Next, install the required Ansible collections as root.

    # ansible-galaxy collection install -r requirements.yml

Run the playbook as root.

    # ansible-playbook -i localhost playbook.yml

When run, Ansible will prompt for the user password. This only needs to be
provided on the first run when the user is being created. On later runs,
providing any password -- whether the current user password or a new one --
will have no effect.

## SSH

By default, Ansible will attempt to install the private SSH key for the user. The
key should be available at the path specified in the `ssh.user_key` variable.
Removing this variable will cause the key installation task to be skipped.

### SSHD

If `ssh.enable_sshd` is set to `True` the [systemd socket service][4] will be
enabled. By default, sshd is configured but not enabled.

## Dotfiles

Ansible expects that the user wishes to clone dotfiles via the git repository
specified via the `dotfiles.url` variable and install them with [rcm][5]. The
destination to clone the repository to is defined by the `dotfiles.destination`
variable. This is relative the user's home directory.

These tasks will be skipped if the `dotfiles` variable is not defined.

## Tagging

All tasks are tagged with their role, allowing them to be skipped by tag in
addition to modifying `playbook.yml`.

## AUR

All tasks involving the [AUR][6] are tagged `aur`. To provision an AUR-free
system, pass this tag to ansible's `--skip-tag`.

AUR packages are installed via the [ansible-aur][7] module. Note that while
[yay][8], an [AUR helper][9], is installed by default, it will *not* be used
during any of the provisioning.

## Firejail

Many applications are sandboxed with [Firejail][10]. This behavior should be
largely invisible to the user.

Custom security profiles are provided for certain applications. These are
installed to `/usr/local/etc/firejail`. Firejail does not look in this
directory by default. To use the security profiles, they must either be
specified on the command-line or included in an appropriately named profile
located in `~/.config/firejail`.

    # Example 1:
    # Launch Firefox using the custom profile by specifying the full path of the profile.
    $ firejail --profile=/usr/local/etc/firejail/firefox.profile /usr/bin/firefox
    # Example 2:
    # Launch Firefox using the custom profile by specifying its directory.
    $ firejail --profile-path=/usr/local/etc/firejail /usr/bin/firefox
    # Example 3:
    # Include the profile  in ~./config/firejail
    $ mkdir -p ~/.config/firejail
    $ echo 'include /usr/local/etc/firejail/firefox.profile' > ~/.config/firejail/firefox.profile
    $ firejail /usr/bin/firefox

The script `profile-activate` is provided to automatically include the profiles
when appropriate. For every profile located in `/usr/local/etc/firejail`, the
script looks for a profile with the same name in `~/.config/firejail`. If one
is not found, it will create a profile that simply includes the system profile,
as in the third example above. It will not modify any existing user profiles.

### Blacklisting

The `firejail.blacklist` variable is used to populate
`/etc/firejail/globals.local` with a list of blacklisted files and directories.
This file is included by all security profiles, causing the specified locations
to be inaccessible to jailed programs.

## Trusted Networks

The trusted network framework provided by [nmtrust][11] is leveraged to start
certain systemd units when connected to trusted networks, and stop them
elsewhere.

This helps to avoid leaking personal information on untrusted networks by
ensuring that certain network tasks are not running in the background.
Currently, this is used for mail syncing (see the section below on Syncing and
Scheduling Mail), Tarsnap backups (see the section below on Scheduling
Tarsnap), BitlBee (see the section below on BitlBee), and git-annex (see the
section below on git-annex).

Trusted networks are defined using their NetworkManager UUIDs, configured in
the `network.trusted_uuid` list. NetworkManager UUIDs may be discovered using
`nmcli con`.

[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://wiki.archlinux.org/index.php/Secure_Shell#Managing_the_sshd_daemon
[5]: https://thoughtbot.github.io/rcm/
[6]: https://aur.archlinux.org
[7]: https://github.com/kewlfft/ansible-aur
[8]: https://github.com/Jguer/yay
[9]: https://wiki.archlinux.org/index.php/AUR_helpers
[11]: https://github.com/pigmonkey/nmtrust
