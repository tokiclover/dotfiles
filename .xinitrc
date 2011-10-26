# $Id: $HOME/.xinitrc,v 1.1 2011/10/19 -tclover Exp $

/usr/libexec/polkit-gnome-authentication-agent-1 &
xmodmap $HOME/.Xmodmap
unclutter -idle 8 -noevents &
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/artwiz-aleczapka-en
xset fp+ /usr/share/fonts/terminus
xset fp+ $HOME/.fonts
xset fp rehash
#xrdb -merge $HOME/.Xdefaults
xrdb -merge $HOME/.Xresources 
#xrdb -merge $HOME/.xcolors/sj-bright
/usr/bin/urxvtd -q -o -f &
#/usr/bin/conky -d -d &
#/usr/bin/tint2 &>/dev/null &
/usr/bin/mpd &>/dev/null &
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start
exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start.sh

# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
