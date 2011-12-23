# $Id: $HOME/.xinitrc,v 1.1 2011/11/17 -tclover Exp $
#
# start gnome-keyring and nm-applet
eval $(gnome-keyring-daemon)
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET
export SSH_AUTH_SOCK
export GPG_AGENT_INFO
dbus-launch nm-applet --sm-disable &
# start gnome-color-manager
dbus-launch gcm-session &
# or xcalib for the matter
#xcalib -gc 1.0 -b 0.0 -co 100.0 .icm/sRGB_v4_ICC_preference.icc
/usr/libexec/polkit-gnome-authentication-agent-1 &
# initialize X server settings
unclutter -idle 8 -noevents &
[[ -e $HOME/.Xmodmap ]] && xmodmap $HOME/.Xmodmap
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/artwiz-aleczapka-en
xset fp+ /usr/share/fonts/terminus
xset fp rehash
#xrdb -merge $HOME/.Xdefaults
#xrdb -merge $HOME/.xcolors/sj-bright
xrdb -load $HOME/.Xresources
# start a [D]E and urxvtc
/usr/bin/urxvtd -q -o -f &
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start
exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start.sh
#exec ck-launch-session lxsession
#exec ck-launch-session startxfce4 
#exec ck-launch-session pekwm
#
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
