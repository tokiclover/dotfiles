# $Id: $HOME/.xinitrc,v 1.1 2011/10/17 -tclover Exp $
xmodmap $HOME/.Xmodmap
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp rehash
xrdb -merge $HOME/.Xresources
#/usr/bin/urvxtd &>/dev/null
$HOME/scr/ffp-pack 2>/dev/null
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec /usr/bin/enlightenment_start.sh
