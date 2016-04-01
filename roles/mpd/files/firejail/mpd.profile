include /etc/firejail/disable-mgmt.inc
include /etc/firejail/disable-common.inc
protocol unix,inet,inet6,netlink
seccomp

whitelist ~/.config/mpd
whitelist ~/audio
