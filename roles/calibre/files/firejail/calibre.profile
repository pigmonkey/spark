include /etc/firejail/default.profile
include /etc/firejail/disable-devel.inc

private-dev
private-etc firejail,passwd,group,hostname,hosts,nsswitch.conf,resolv.conf,gtk-2.0,gtk-3.0,fonts,mime.types,ssl,ca-certificates
private-tmp
