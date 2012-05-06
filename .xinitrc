# $Id: ~/.xinitrc, 2012/05/05 -tclover Exp $
eval $(gnome-keyring-daemon --components=pkcs11,secrets,ssh,gpg)
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET
export SSH_AUTH_SOCK
export GPG_AGENT_INFO
dbus-launch nm-applet --sm-disable &
dbus-launch gcm-session &
/usr/libexec/polkit-gnome-authentication-agent-1 &
#xcalib -gc 1.0 -b 0.0 -co 100.0 .icc/sRGB_v4_ICC_preference.icc
laditray &> /dev/null &
unclutter -idle 8 -noevents &
[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/artwiz-aleczapka-en
xset fp+ /usr/share/fonts/terminus
xset fp rehash
xrdb -load ~/.Xresources
#xrdb -merge ~/.Xdefaults
#[[ -f ~/.xcolors/sj-bright ]] && xrdb -merge ~/.xcolors/sj-bright
/usr/bin/urxvtd -q -o -f &
case $(tty | cut -b6-) in
	tty1) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start.sh;;
	tty2) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session lxsession             ;;
	tty3) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session       ;;
esac
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
