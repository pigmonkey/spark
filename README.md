# Spark

Spark is an [Ansible][1] playbook meant to provision a personal machine running
[Arch Linux][2]. It is intended to run locally on a fresh Arch install (ie,
taking the place of any [post-installation][3]), but due to Ansible's
idempotent nature it may also be run on top of an already configured machine.

Spark assumes it will be run on a laptop and performs some configuration based
on this assumption. This behaviour may be changed by removing the `laptop` role
from the playbook or by skipping the `laptop` tag.

If Spark is run on either a ThinkPad or a MacBook, it will detect this and
execute platform-specific tasks.

**Note:** If you would like to try recreating all the tasks that are currently 
included in the ansible playbook, through a VM, you would need a disk of at least 
**16GB** in size.

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

## MAC Spoofing

By default, the MAC address of all network interfaces is spoofed at boot,
before any network services are brought up. This is done with [macchiato][11],
which uses legitimate OUI prefixes to make the spoofing less recognizable.

MAC spoofing is desirable for greater privacy on public networks, but may be
inconvenient on home or corporate networks where a consistent (if not real) MAC
address is wanted for authentication. To work around this, allow `macchiato` to
randomize the MAC on boot, but tell NetworkManager to clone the real (or a fake
but consistent) MAC address in its profile for the trusted networks. This can
be done in the GUI by populating the "Cloned MAC address" field for the
appropriate profiles, or by setting the `cloned-mac-address` property in the
profile file at `/etc/NetworkManager/system-connections/`.

Spoofing may be disabled entirely by setting the `network.spoof_mac` variable
to `False`.

## Trusted Networks

The trusted network framework provided by [nmtrust][12] is leveraged to start
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


## Mail

### Receiving Mail

Receiving mail is supported by syncing from IMAP servers via both [isync][13]
and [OfflineIMAP][14]. By default isync is enabled, but this can be changed to
OfflineIMAP by setting the value of the `mail.sync_tool` variable to
`offlineimap`.

### Sending Mail

[msmtp][15] is used to send mail. Included as part of msmtp's documentation are
a set of [msmtpq scripts][16] for queuing mail. These scripts are copied to the
user's path for use. When calling `msmtpq` instead of `msmtp`, mail is sent
normally if internet connectivity is available. If the user is offline, the
mail is saved in a queue, to be sent out when internet connectivity is again
available. This helps support a seamless workflow, both offline and online.

### System Mail

If the `email.user` variable is defined, the system will be configured to
forward mail for the user and root to this address. Removing this variable will
cause no mail aliases to be put in place.

The cron implementation is configured to send mail using `msmtp`.

### Syncing and Scheduling Mail

A shell script called `mailsync` is included to sync mail, by first sending any
mail in the msmtp queue and then syncing with the chosen IMAP servers via
either isync or OfflineIMAP. The script will also attempt to sync contacts and
calendars via [vdirsyncer][17]. To disable this behavior, set the
`mail.sync_pim` variable to `False`.

Before syncing, the `mailsync` script checks for internet connectivity using
NetworkMananger. `mailsync` may be called directly by the user, ie by
configuring a hotkey in Mutt.

A [systemd timer][18] is also included to periodically call `mailsync`. The
timer is set to sync every 5 minutes (configurable through the `mail.sync_time`
variable).

The timer is not started or enabled by default. Instead, the timer is added to
`/etc/nmtrust/trusted_units`, causing the NetworkManager trusted unit
dispatcher to activate the timer whenever a connection is established to a
trusted network. The timer is stopped whenever the network goes down or a
connection is established to an untrusted network.

To have the timer activated at boot, change the `mail.sync_on` variable from
`trusted` to `all`.

If the `mail.sync_on` variable is set to anything other than `trusted` or
`all`, the timer will never be activated.


## Tarsnap

[Tarsnap][19] is installed with its default configuration file. However,
setting up Tarsnap is left as an exercise for the user. New Tarsnap users
should [register their machine and generate a key][20]. Existing users should
recover their key(s) and cache directory from their backups (or, alternatively,
recover their key(s) and rebuild the cache directory with `tarsnap --fsck`).

[Tarsnapper][21] is installed to manage backups. A basic configuration file to
backup `/etc` is included. Tarsnapper is configured to look in
`/usr/local/etc/tarsnapper.d` for additional jobs. As with with the Tarsnap key
and cache directory, users should recover their jobs files from backups after
the Tarsnapper install is complete. See the Tarsnapper documentation for more
details.

### Running Tarsnap

A systemd unit file and timer are included for Tarsnapper. Rather than calling
it directly, the systemd unit wraps Tarsnapper with [backitup][22].

The timer is set to execute the unit hourly, but backitup will only call
Tarsnapper once within the period defined in the `tarsnapper.period` variable.
This defaults to `DAILY`. This increases the likelyhood of completing daily
backups by checking each hour if the unit has run succesfully on the current
calendar day.

In addition to the period limitation, backitup defaults to only calling
Tarsnapper when it detects the machine ison AC power. To allow Tarsnapper to
run when on battery, set the `tarsnapper.ac_only` variable to `False`.

As with `mailsync`, the timer is not started or enabled by default. Instead,
the timer is added to `/etc/nmtrust/trusted_units`, causing the NetworkManager
trusted unit dispatcher to activate the timer whenever a connection is
established to a trusted network. The timer is stopped whenever the network
goes down or a connection is established to an untrusted network.

To have the timer activated at boot, change the `tarsnapper.run_on` variable
from `trusted` to `all`.

If the `tarsnapper.run_on` variable is set to anything other than `trusted` or
`all`, the timer will never be activated.


## Tor

[Tor][23] is installed by default. A systemd service unit for Tor is installed,
but not enabled or started. instead, the service is added to
`/etc/nmtrust/trusted_units`, causing the NetworkManager trusted unit
dispatcher to activate the service whenever a connection is established to a
trusted network. The service is stopped whenever the network goes down or a
connection is established to an untrusted network.

To have the service activated at boot, change the `tor.run_on` variable
from `trusted` to `all`.

If you do not wish to use Tor, simply remove the `tor` variable from the
configuration.

### parcimonie.sh

[parcimonie.sh][24] is provided to periodically refresh entries in the user's
GnuPG keyring over the Tor network. The service is added to
`/etc/nmtrust/trusted_units` and respects the `tor.run_on` variable.


## BitlBee

[BitlBee][25] and [WeeChat][26] are used to provide chat services. A systemd
service unit for BitlBee is installed, but not enabled or started by default.
Instead, the service is added to `/etc/nmtrust/trusted_units`, causing the
NetworkManager trusted unit dispatcher to activate the service whenever a
connection is established to a trusted network. The service is stopped whenever
the network goes down or a connection is established to an untrusted network.

To have the service activated at boot, change the `bitlbee.run_on` variable
from `trusted` to `all`.

If the `bitlbee.run_on` variable is set to anything other than `trusted` or
`all`, the service will never be activated.

By default BitlBee will be configured to proxy through Tor. To disable this,
remove the `bitlebee.torify` variable or disable Tor entirely by removing the
`tor` variable.

## git-annex

[git-annex][27] is installed for file syncing. A systemd service unit for the
git-annex assistant is enabled and started by default. To prevent this, remove
the `gitannex` variable from the config.

Additionally, the git-annex unit is added to `/etc/nmtrust/trusted_units`,
causing the NetworkManager trusted unit dispatcher to activate the service
whenever a connection is established to a trusted network. The service is
stopped whenever a connection is established to an untrusted network. Unlike
other units using the trusted network framework, the git-annex unit is also
activated when there are no active network connections. This allows the
git-annex assistant to be used when on trusted networks and when offline, but
not when on untrusted networks.

If the `gitannex.stop_on_untrusted` variable is set to anything other than
`True` or is not defined, the git-annex unit will not be added to the trusted
unit file, resulting in the git-annex assistant not being stopped on untrusted
networks.

## PostgreSQL

[PostgreSQL][28] is installed and enabled by default. If the
`postgresql.enable` variable is set to anything other than `True` or is not
defined, the service will not be started or enabled.

This is intended for local development. PostgreSQL is configured to only listen
on localhost and no additional ports are opened in the default firewall. This
configuration means that PostgreSQL is not a network service. As such, the
PostgreSQL service is not added to `/etc/nmtrust/trusted_units`.

Additional configuration options are set which improve performance but make the
database service inappropriate for production use.

## Himawaripy

[Himawaripy][29] is provided to fetch near-realtime photos of Earth from the
Japanese [Himawari 8][30] weather satellite and set them as the user's desktop
background via feh. This should provide early warning of the presence of any
Vogon constructor fleets appearing over the Eastern Hemisphere.

A systemd service unit and timer is installed, but not enabled or started by
default. Instead, the service is added to `/etc/nmtrust/trusted_units`, causing
the NetworkManager trusted unit dispatcher to activate the service whenever a
connection is established to a trusted network. The service is stopped whenever
the network goes down or a connection is established to an untrusted network.

To have the service activated at boot, change the `himawaripy.run_on` variable
from `trusted` to `all`.

If the `himawaripy.run_on` variable is set to anything other than `trusted` or
`all`, the service will never be activated.

By default the timer is scheduled to fetch a new image at 15 minute intervals.
This can be changed by modifying the `himawaripy.run_time` variable.

By completely removing the `himawaripy` variable, no related tasks will be run.


[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://wiki.archlinux.org/index.php/Secure_Shell#Managing_the_sshd_daemon
[5]: https://thoughtbot.github.io/rcm/
[6]: https://aur.archlinux.org
[7]: https://github.com/pigmonkey/ansible-aur
[8]: https://github.com/Jguer/yay
[9]: https://wiki.archlinux.org/index.php/AUR_helpers
[10]: https://firejail.wordpress.com/
[11]: https://github.com/EtiennePerot/macchiato
[12]: https://github.com/pigmonkey/nmtrust
[13]: http://isync.sourceforge.net/
[14]: http://offlineimap.org/
[15]: http://msmtp.sourceforge.net/
[16]: http://sourceforge.net/p/msmtp/code/ci/master/tree/scripts/msmtpq/README.msmtpq
[17]: https://github.com/pimutils/vdirsyncer
[18]: https://wiki.archlinux.org/index.php/Systemd/Timers
[19]: https://www.tarsnap.com/
[20]: https://www.tarsnap.com/gettingstarted.html
[21]: https://github.com/miracle2k/tarsnapper
[22]: https://github.com/pigmonkey/backitup
[23]: https://www.torproject.org/
[24]: https://github.com/EtiennePerot/parcimonie.sh
[25]: https://www.bitlbee.org/main.php/news.r.html
[26]: https://weechat.org/
[27]: https://git-annex.branchable.com/
[28]: http://www.postgresql.org/
[29]: https://github.com/boramalper/himawaripy
[30]: https://en.wikipedia.org/wiki/Himawari_8
