include /usr/local/etc/firejail/generic.profile

private-etc group,hosts,nsswitch.conf,resolv.conf,asound.conf,pulse,ssl,ca-certificates
private-tmp
shell none
whitelist ~/.config/pianobar
