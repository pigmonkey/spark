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

AUR packages will be downloaded via [cower][7] and installed with [makepkg][8].
It is assumed that the user will want to use an [AUR helper][9] after the
system has been provisioned, so whatever package is defined in `aur.helper`
will be installed. This helper will *not* be used during any of the
provisioning.

## Known Issues

* [tpfanco][10], normally installed as part of the `thinkpad` role is currently
  [unavailable in the AUR][11]. No ThinkPad fan control software is currently
  installed.
* [gpxpy][12], normally installed as part of the `mapping` role is currently
  [unavailable in the AUR][13].


[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://wiki.archlinux.org/index.php/Secure_Shell#Managing_the_sshd_daemon
[5]: https://thoughtbot.github.io/rcm/
[6]: https://aur.archlinux.org
[7]: https://github.com/falconindy/cower
[8]: https://wiki.archlinux.org/index.php/Makepkg
[9]: https://wiki.archlinux.org/index.php/AUR_helpers
[10]: https://code.google.com/p/tpfanco/
[11]: https://aur.archlinux.org/packages/?O=0&K=tpfanco
[12]: https://github.com/tkrajina/gpxpy
[13]: https://aur.archlinux.org/packages/?O=0&K=gpxpy
