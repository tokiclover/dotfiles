#
# $Header: ${HOME}/.xinitrc, 2015/06/20 15:32:37            Exp $
#

#
# Set up ssh/gpg-agent
#
if [ -r "${TMPDIR}"/env ]; then
	while read line; do
		export "${line}"
	done < "${TMPDIR}"/env
else
	eval export $(gpg-agent --daemon --sh)
	eval export $(ssh-agent -s)
	printf "GPG_AGENT_INFO=$GPG_AGENT_INFO\nSSH_AUTH_SOCK=$SSH_AUTH_SOCK\nSSH_AGENT_PID=$SSH_AGENT_PID\n" >$TMPDIR/env
fi

#
# Set up basic X server settings
#
xset s off
for dir in /usr/share/fonts/* ~/.fonts/*; do
	[ -d "$dir" ] && xset fp+ "$dir"
done
unset dir
xset fp rehash

[ -s ~/.Xresources ] && xrdb -load ~/.Xresources
#setxkbmap -model pc105 -layout fr -variant ,oss,latin9,oss_latin9 \
#	-option grp:shift_caps_toggle,keypad:future,terminate:ctrl_alt_bksp
#[ -s ~/.Xdefaults ] && xrdb -merge ~/.Xdefaults
[ -s ~/.Xmodmap ] && xmodmap ~/.Xmodmap
#[ -s ~/.color/x/sj-bright ] && xrdb -merge ~/.color/x/sj-bright
[ -s ~/.xbindkeysrc ] && xbindkeys -f ~/.xbindkeysrc

#xautolock -time 30 -locker slock
xbacklight -set 15
if [ -f ~/.color/icc/default.ic* ]; then
	oyranos-monitor ~/.color/icc/default.ic*
	oyranos-monitor-daemon &
fi
unclutter -idle 8 -noevents &

#
# Launch a few apps/daemons if available
#
dhcpcd-gtk >/dev/null 2>&1 &
ladi-system-tray > ~/.log/ladi.log 2>&1 &
urxvtd -q -o -f &

#
# Start a WM depending on TTY login;
# Or else, start a seesion passed as @arg-1
#
case "${1:-$(tty)}" in
	(enligh*|*tty1) exec enlightenment_start;;
	(icewm|*tty2)   exec icewm-session      ;;
	(openbox|*tty3) exec openbox-session    ;;
esac

## Set up a default/fallback session
#
if type -p enlightenment_start >/dev/null 2>&1; then
	exec enlightenment_start
elif type -p openbox-session >/dev/null 2>&1; then
	exec openbox-session
elif type -p icewm-session >/dev/null 2>&1; then
	exec icewm-session
else
	xterm -geometry 80x24-0-0
fi

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
