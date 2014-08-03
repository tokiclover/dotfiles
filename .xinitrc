# $Id: ~/.xinitrc, 2015/08/01 15:32:37 -tclover Exp $

launch="dbus-launch --sh-syntax --exit-with-session"
$launch nm-applet --sm-disable &
$launch gcm-session &
eval $(gnome-keyring-daemon --daemonize --components=pkcs11,secrets,ssh,gpg)
echo GNOME_KEYRING_PID=$GNOME_KEYRING_PID >/tmp/.private/$USER/keyring/env
echo GNOME_KEYRING_CONTROL=$GNOME_KEYRING_CONTROL >>/tmp/.private/$USER/keyring/env
echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK >>/tmp/.private/$USER/keyring/env
echo GPG_AGENT_INFO=$GPG_AGENT_INFO >>/tmp/.private/$USER/keyring/env
export GNOME_KEYRING_PID GNOME_KEYRING_CONTROL SSH_AUTH_SOCK GPG_AGENT_INFO
/usr/libexec/polkit-gnome-authentication-agent-1 &

xset s off
xset fp+ /usr/share/fonts/TTF-FD/
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/artwiz-aleczapka-en
xset fp+ /usr/share/fonts/terminus
xset fp rehash
xrdb -load ~/.Xresources
setbacklight -set 20
#setxkbmap -model pc102 -layout fr -variant ,oss,latin9,oss_latin9 \
#	-option grp:shift_caps_toggle,keypad:future,terminate:ctrl_alt_bksp
#xrdb -merge ~/.Xdefaults
[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap
#xrdb -merge ~/.color/x/sj-bright
#xcalib -gc 1.0 -b 0.0 -co 100.0 ~/.color/icc/sRGB_v4_ICC_preference_displayclass.icc
unclutter -idle 8 -noevents &
ladi-system-tray > ~/.log/ladi/ladi.log 2>&1 &
urxvtd -q -o -f &

launch="ck-launch-session $launch"
case $(tty | cut -b9-) in
	1) exec $launch enlightenment_start;;
	2) exec $launch lxsession          ;;
	3) exec $launch openbox-session    ;;
esac

# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
