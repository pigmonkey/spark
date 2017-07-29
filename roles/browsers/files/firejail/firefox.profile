include /etc/firejail/firefox.profile

# Note that localtime should be added to private-etc if you wish Firefox to be
# able to determine you timezone.
private-etc firejail,passwd,group,hostname,hosts,nsswitch.conf,resolv.conf,gtk-2.0,gtk-3.0,fonts,mime.types,asound.conf,pulse,localtime
