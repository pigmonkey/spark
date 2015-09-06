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

Ansible will attempt to install the private SSH key for the user. The key
should be available at the path specified in the `ssh.user_key` variable.

Run the playbook as root.

    $ ansible-playbook -i localhost playbook.yml

When run, Ansible will prompt for the user password. This only needs to be
provided on the first run when the user is being created. On later runs,
providing any password -- whether the current user password or a new one --
will have no effect.

## AUR

All tasks involving the [AUR][4] are tagged `aur`. To provision an AUR-free
system, pass this tag to ansible's `--skip-tag`.

AUR packages will be downloaded via [cower][5] and installed with [makepkg][6].
It is assumed that the user will want to use an [AUR helper][7] after the
system has been provisioned, so whatever package is defined in `aur.helper`
will be installed. This helper will *not* be used during any of the
provisioning.

## Known Issues

* [tpfanco][8], normally installed as part of the `thinkpad` role is currently
  [unavailable in the AUR][9]. No ThinkPad fan control software is currently
  installed.
* [gpxpy][10], normally installed as part of the `mapping` role is currently
  [unavailable in the AUR][11].


[1]: http://www.ansible.com
[2]: https://www.archlinux.org
[3]: https://wiki.archlinux.org/index.php/Installation_guide#Post-installation
[4]: https://aur.archlinux.org
[5]: https://github.com/falconindy/cower
[6]: https://wiki.archlinux.org/index.php/Makepkg
[7]: https://wiki.archlinux.org/index.php/AUR_helpers
[8]: https://code.google.com/p/tpfanco/
[9]: https://aur.archlinux.org/packages/?O=0&K=tpfanco
[10]: https://github.com/tkrajina/gpxpy
[11]: https://aur.archlinux.org/packages/?O=0&K=gpxpy
