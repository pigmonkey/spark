include /usr/local/etc/firejail/disable-more.inc
include /etc/firejail/rtorrent.profile

private-dev
private-etc firejail,passwd,group,hostname,hosts,nsswitch.conf,resolv.conf
private-tmp
