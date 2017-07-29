include /etc/firejail/default.profile
include /etc/firejail/disable-devel.inc

private-etc firejail,group,hosts,nsswitch.conf,resolv.conf,asound.conf,pulse,ssl,ca-certificates
private-tmp
shell none
whitelist ~/.config/pianobar
