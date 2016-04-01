include /etc/firejail/disable-mgmt.inc
include /etc/firejail/disable-secret.inc
include /etc/firejail/disable-common.inc
include /etc/firejail/disable-devel.inc

caps.drop all
seccomp
protocol unix,inet,inet6
netfilter
noroot
nogroups
shell none
private-etc group,hosts,nsswitch.conf,resolv.conf,asound.conf,pulse,ssl,ca-certificates
whitelist ~/.config/pianobar
