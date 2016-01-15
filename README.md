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

## Running

First, sync mirrors and install Ansible:

    $ pacman -Syy python2-passlib ansible

Second, install and update the submodules:

    $ git submodule init && git submodule update
    
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
specified via the `dotfiles.url` variable and install them with [rcm][5]. If
this is not the case, removing the `dotfiles` variable will cause the relevant
tasks to be skipped.

## Tagging

All tasks are tagged with their role, allowing them to be skipped by tag in
addition to modifying `playbook.yml`. For instance, a system could be built
excluding the entire `media` role and the `slim` section of the `x`
role.

    # ansible-playbook -i localhost playbook.yml --skip-tags "media,slim"

## AUR

All tasks involving the [AUR][6] are tagged `aur`. To provision an AUR-free
system, pass this tag to ansible's `--skip-tag`.

AUR packages are installed via the [ansible-aur][7] module. Note that while
[aura][8], an [AUR helper][9], is installed by default, it will *not* be used
during any of the provisioning.

## MAC Spoofing

By default, the MAC address of all network interfaces is spoofed at boot,
before any network services are brought up. This is done with [macchiato][10],
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

Trusted networks are defined using their NetworkManager UUIDs, configured in
the `network.trusted_uuid` list. NetworkManager UUIDs may be discovered using
`nmcli con`.

The list of trusted networks is made available at
`/usr/local/etc/trusted_networks`. Currently this list is only used to start
and stop mail syncing (see the section below on Syncing and Scheduling Mail)
and Tarsnap backups (see the section below on Scheduling Tarsnap), however
maintaining the list may be useful for starting or stopping other services,
loading different iptables rules, etc.

## Mail

### Receiving Mail

Receiving mail is supported by syncing from IMAP servers via both [isync][11]
and [OfflineIMAP][12]. By default isync is enabled, but this can be changed to
OfflineIMAP by setting the value of the `mail.sync_tool` variable to
`offlineimap`.

### Sending Mail

[msmtp][13] is used to send mail. Included as part of msmtp's documentation are
a set of [msmtpq scripts][14] for queuing mail. These scripts are copied to the
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
either isync or OfflineIMAP. Before syncing, the script checks for internet
connectivity using NetworkMananger. `mailsync` may be called directly by the
user, ie by configuring a hotkey in Mutt.

A [systemd timer][15] is also included to periodically call `mailsync`. The
timer is set to sync every 10 minutes (configurable through the
`mail.sync_time` variable).

The timer is not started or enabled by default. Instead, a NetworkManager
dispatcher is installed, which activates the timer whenever a connection is
established to a trusted network. The timer is stopped when the network goes
down. This helps to avoid having network tasks that may leak personally
identifiable information running in the background when connected to untrusted
networks.

To have the timer activated at boot, change the `mail.sync_on` variable from
`trusted` to `all`.

If the `mail.sync_on` variable is set to anything other than `trusted` or
`all`, the timer will never be activated.


## Tarsnap

[Tarsnap][16] is installed with its default configuration file. However,
setting up Tarsnap is left as an exercise for the user. New Tarsnap users
should [register their machine and generate a key][17]. Existing users should
recover their key(s) and cache directory from their backups (or, alternatively,
recover their key(s) and rebuild the cache directory with `tarsnap --fsck`).

[Tarsnapper][18] is installed to manage backups. A basic configuration file to
backup `/etc` is included. Tarsnapper is configured to look in
`/usr/local/etc/tarsnapper.d` for additional jobs. As with with the Tarsnap key
and cache directory, users should recover their jobs files from backups after
the Tarsnapper install is complete. See the Tarsnapper documentation for more
details.

### Scheduling Tarsnap

A systemd unit file and timer are included for Tarsnapper. The timer is set to
execute Tarsnapper every hour (configurable through the
`tarsnapper.timer.frequency` variable). However, as with `mailsync` this timer
is not started or enabled by default. Instead, a NetworkManager dispatcher is
installed, which activates the timer whenever a connection is established to a
trusted network. The timer is stopped when the network goes down. This prevents
Tarsnap backups from executing when connected to untrusted networks.

To have the timer activated at boot, change the `tarsnapper.timer.run_on`
variable from `trusted` to `all`.

If the `tarsnapper.tarsnap.run_on` variable is set to anything other than
`trusted` or `all`, the timer will never be activated.

## Known Issues

* [tpfanco][19], normally installed as part of the `thinkpad` role is currently
  [unavailable in the AUR][20]. No ThinkPad fan control software is currently
  installed.


[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://wiki.archlinux.org/index.php/Secure_Shell#Managing_the_sshd_daemon
[5]: https://thoughtbot.github.io/rcm/
[6]: https://aur.archlinux.org
[7]: https://github.com/pigmonkey/ansible-aur
[8]: https://github.com/aurapm/aura
[9]: https://wiki.archlinux.org/index.php/AUR_helpers
[10]: https://github.com/EtiennePerot/macchiato
[11]: http://isync.sourceforge.net/
[12]: http://offlineimap.org/
[13]: http://msmtp.sourceforge.net/
[14]: http://sourceforge.net/p/msmtp/code/ci/master/tree/scripts/msmtpq/README.msmtpq
[15]: https://wiki.archlinux.org/index.php/Systemd/Timers
[16]: https://www.tarsnap.com/
[17]: https://www.tarsnap.com/gettingstarted.html
[18]: https://github.com/miracle2k/tarsnapper
[19]: https://code.google.com/p/tpfanco/
[20]: https://aur.archlinux.org/packages/?O=0&K=tpfanco
