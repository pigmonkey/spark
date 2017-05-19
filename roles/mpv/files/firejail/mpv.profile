include /etc/firejail/mpv.profile
include /usr/local/etc/firejail/disable-more.inc

private-etc firejail,group,hosts,resolv.conf,mime.types,asound.conf,pulse,fonts,ssl,ca-certificates
private-bin mpv,youtube-dl,python,python2.7,python3.6
