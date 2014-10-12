#
# $Header: ~/.xinitrc, 2014/10/10 15:32:37 -tclover Exp $
#

launch="dbus-launch --sh-syntax --exit-with-session"
$launch gcm-session &
eval $(gnome-keyring-daemon --daemonize --components=pkcs11,secrets,ssh,gpg)
echo -e \
	"\nSSH_AUTH_SOCK=$SSH_AUTH_SOCK" \
	"\nGPG_AGENT_INFO=$GPG_AGENT_INFO" >"$TMPDIR"/keyring/env
export SSH_AUTH_SOCK GPG_AGENT_INFO
/usr/libexec/polkit-gnome-authentication-agent-1 &

xset s off
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/terminus
xset fp rehash

[ -s ~/.Xresources ] && xrdb -load ~/.Xresources
xbacklight -set 20
#setxkbmap -model pc105 -layout fr -variant ,oss,latin9,oss_latin9 \
#	-option grp:shift_caps_toggle,keypad:future,terminate:ctrl_alt_bksp
#[ -s ~/.Xdefaults ] && xrdb -merge ~/.Xdefaults
[ -s ~/.Xmodmap ] && xmodmap ~/.Xmodmap
#[ -s ~/.color/x/sj-bright ] && xrdb -merge ~/.color/x/sj-bright
#[ -s ~/.color/icc/sRGB_v4_ICC_preference_displayclass.icc ] &&
#xcalib -gc 1.0 -b 0.0 -co 100.0 ~/.color/icc/sRGB_v4_ICC_preference_displayclass.icc

unclutter -idle 8 -noevents &
dhcpcd-gtk >/dev/null 2>&1 &
ladi-system-tray > ~/.log/ladi/ladi.log 2>&1 &
urxvtd -q -o -f &

launch="ck-launch-session $launch"
case $(tty | cut -b9-) in
	(1) exec $launch enlightenment_start;;
	(2) exec $launch lxsession          ;;
	(3) exec $launch openbox-session    ;;
esac
unset launch

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
