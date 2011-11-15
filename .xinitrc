# $Id: $HOME/.xinitrc,v 1.1 2011/11/15 -tclover Exp $

eval "$(gnome-keyring-daemon)"
export GNOME_KEYRING_PID
export GNOME_KEYRING_SOCKET
export SSH_AUTH_SOCK
export GPG_AGENT_INFO
dbus-launch nm-applet --sm-disable &
/usr/libexec/polkit-gnome-authentication-agent-1 &

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

/usr/bin/urxvtd -q -o -f &

#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session openbox-session
#exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start
exec ck-launch-session dbus-launch --sh-syntax --exit-with-session enlightenment_start.sh
#exec ck-launch-session lxsession
#exec ck-launch-session startxfce4 
#exec ck-launch-session pekwm

#case ${1} in
#	enlightenment) exec enlightenement_start   ;;
#	fluxbox)       exec startfluxbox           ;;
#	fvwm*)         exec fvwm                   ;;
#	openbox)       exec openbox-session        ;;
#	lxde)          exec lxsession              ;;
#	xfce)          exec startxfce4             ;;
#	scrotwm)       exec scrotwm                ;;
#	ecomorph|*)    exec enlightenement_start.sh;;
#esac

# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
