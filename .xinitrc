# $Id: $HOME/.xinitrc,v 1.1 2011/10/19 -tclover Exp $
xmodmap $HOME/.Xmodmap
unclutter -idle 8 -noevents &
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ $HOME/.fonts
xset fp rehash
xrdb -merge $HOME/.Xdefaults
##xrdb -merge $HOME/.xcolors/sj-bright
/usr/bin/urxvtd -q -o -f &>/dev/null &
/usr/bin/mpd &>/dev/null &
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec /usr/bin/enlightenment_start.sh
