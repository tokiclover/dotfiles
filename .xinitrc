#
# $Header: ${HOME}/.xinitrc, 2015/06/06 15:32:37            Exp $
#

if [ -r "${TMPDIR}"/env ]; then
	while read line; do
		export "${line}"
	done < "${TMPDIR}"/env
else
	eval export $(gpg-agent --daemon --sh)
	eval export $(ssh-agent -s)
	{
		echo GPG_AGENT_INFO="${GPG_AGENT_INFO}"
		echo SSH_AUTH_SOCK="${SSH_AUTH_SOCK}"
		echo SSH_AGENT_PID="${SSH_AGENT_PID}"
	} > "${TMPDIR}"/env
fi

xset s off
xset fp+ /usr/share/fonts/artwiz-latin1
xset fp+ /usr/share/fonts/terminus
xset fp rehash

[ -s ~/.Xresources ] && xrdb -load ~/.Xresources
#setxkbmap -model pc105 -layout fr -variant ,oss,latin9,oss_latin9 \
#	-option grp:shift_caps_toggle,keypad:future,terminate:ctrl_alt_bksp
#[ -s ~/.Xdefaults ] && xrdb -merge ~/.Xdefaults
[ -s ~/.Xmodmap ] && xmodmap ~/.Xmodmap
#[ -s ~/.color/x/sj-bright ] && xrdb -merge ~/.color/x/sj-bright

#xautolock -time 30 -locker slock
xbacklight -set 15
if [ -f "${HOME}"/.color/icc/default.ic* ]; then
	oyranos-monitor "${HOME}"/.color/icc/default.ic*
	oyranos-monitor-daemon &
fi

unclutter -idle 8 -noevents &
dhcpcd-gtk >/dev/null 2>&1 &
ladi-system-tray > ~/.log/ladi/ladi.log 2>&1 &
urxvtd -q -o -f &

case "$(tty | cut -b9-)" in
	(1) exec enlightenment_start;;
	(2) exec icewm-session      ;;
	(3) exec openbox-session    ;;
esac

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
