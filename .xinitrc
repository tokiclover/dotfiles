# $Id: ~/.xinitrc, 2012/11/12 14:02:11 -tclover Exp $
eval $(gnome-keyring-daemon --components=pkcs11,secrets,ssh,gpg)
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET
export SSH_AUTH_SOCK
export GPG_AGENT_INFO
dbus-launch --sh-syntax --exit-with-session nm-applet --sm-disable &
dbus-launch --sh-syntax --exit-with-session gcm-session &
#xcalib -gc 1.0 -b 0.0 -co 100.0 ~/.icc/sRGB_v4_ICC_preference.icc
/usr/libexec/polkit-gnome-authentication-agent-1 &
ladi-system-tray 1>/dev/null 2>&1 &
unclutter -idle 8 -noevents &
[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap
xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/artwiz-aleczapka-en
xset fp+ /usr/share/fonts/terminus
xset fp rehash
xrdb -load ~/.Xresources
setxkbmap fr 
#xrdb -merge ~/.Xdefaults
#[[ -f ~/.xcolors/sj-bright ]] && xrdb -merge ~/.xcolors/sj-bright
urxvtd -q -o -f &
case $(tty | cut -b9-) in
	1) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start;;
	2) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session lxsession          ;;
	3) exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session    ;;
esac
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
