# $Id: $HOME/.xinitrc,v 1.1 2011/10/19 -tclover Exp $
xmodmap $HOME/.Xmodmap
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp rehash
xrdb -merge $HOME/.Xdefaults
##xrdb -merge $HOME/.xcolors/sj-bright
/usr/bin/urxvtd &>/dev/null &
/usr/bin/mpd &>/dev/null &
/usr/bin/conky -d &>/dev/nul &
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec /usr/bin/enlightenment_start.sh
