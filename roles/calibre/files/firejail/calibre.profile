noblacklist ${HOME}/.config/calibre
include /etc/firejail/disable-mgmt.inc
include /etc/firejail/disable-secret.inc
include /etc/firejail/disable-common.inc
include /etc/firejail/disable-devel.inc

caps.drop all
seccomp
protocol unix,inet,inet6
netfilter
noroot

private-tmp
private-dev
private-etc passwd,group,hostname,hosts,nsswitch.conf,resolv.conf,gtk-2.0,gtk-3.0,fonts,mime.types
