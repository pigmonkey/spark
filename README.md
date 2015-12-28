# Spark

Spark is an [Ansible][1] playbook meant to provision a personal machine running
[Arch Linux][2]. It is intended to run locally on a fresh Arch install (ie,
taking the place of any [post-installation][3]), but due to Ansible's
idempotent nature it may also be run on top of an already configured machine.

Spark assumes it will be run on a laptop -- specifically, a ThinkPad -- and
performs some configuration based on this assumption. This behaviour may be
changed by removing the `laptop` and/or `thinkpad` role from the playbook, as
appropriate.

## Running

First, sync mirrors and install Ansible.

    $ pacman -Syy python2-passlib ansible

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

## Mail

### Receiving Mail

Receiving mail is supported by syncing from IMAP servers via both [isync][10]
and [OfflineIMAP][11]. By default isync is enabled, but this can be changed to
OfflineIMAP by setting the value of the `mail.sync_tool` variable to
`offlineimap`.

### Sending Mail

[msmtp][12] is used to send mail. Included as part of msmtp's documentation are
a set of [msmtpq scripts][13] for queuing mail. These scripts are copied to the
user's path for use. When calling `msmtpq` instead of `msmtp`, mail is sent
normally if internet connectivity is available. If the user is offline, the
mail is saved in a queue, to be sent out when internet connectivity is again
available. This helps support a seamless workflow, both offline and online.

### System Mail

If the `email.user` variable is defined, the system will be configured to
forward mail for the user and root to this address. Removing this variable will
cause no mail aliases to be put in place.

The cron implementation is configured to send mail using `msmtpq`.

### Syncing and Scheduling Mail

A shell script called `mailsync` is included to sync mail, by first sending any
mail in the msmtp queue and then syncing with the chosen IMAP servers via
either isync or OfflineIMAP. Before syncing, the script checks for internet
connectivity using NetworkMananger. `mailsync` may be called directly by the
user, ie by configuring a hotkey in Mutt.

A [systemd timer][14] is also included to periodically call `mailsync`. By
default, the timer starts 5 minutes after boot (to allow time for network
connectivity to be established, configurable through the `mail.sync_boot_delay`
variable) and syncs every 15 minutes (configurable through the `mail.sync_time`
variable).

If the `mail.sync_time` variable is not defined, neither the synchronization
service nor timer will be installed.

## Known Issues

* [tpfanco][15], normally installed as part of the `thinkpad` role is currently
  [unavailable in the AUR][16]. No ThinkPad fan control software is currently
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
[10]: http://isync.sourceforge.net/
[11]: http://offlineimap.org/
[12]: http://msmtp.sourceforge.net/
[13]: http://sourceforge.net/p/msmtp/code/ci/master/tree/scripts/msmtpq/README.msmtpq
[14]: https://wiki.archlinux.org/index.php/Systemd/Timers
[15]: https://code.google.com/p/tpfanco/
[16]: https://aur.archlinux.org/packages/?O=0&K=tpfanco
