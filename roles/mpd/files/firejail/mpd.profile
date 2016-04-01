protocol unix,inet,inet6,netlink
include /usr/local/etc/firejail/generic.profile

whitelist ~/.config/mpd
whitelist ~/audio
