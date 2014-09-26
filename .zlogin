# $Id: ~/.zlogin, 2014/09/26 08:40:49 -tclover Exp $

# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] {
	[[ ${TTY/tty} != $TTY ]] && (( ${TTY:8:1} <= 3 )) &&
		startx 1>~/.log/xsession-errors 2>&1 &
}

# start gnome-keyring
if [[ -f $TMPDIR/keyring/env ]] {
	while read line; do
		export $line
	done <$TMPDIR/keyring/env
} else {
	eval $(gnome-keyring-daemon --daemonize --components=pkcs11,secrets,ssh,gpg)
	echo -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK\
	    "\n"GPG_AGENT_INFO=$GPG_AGENT_INFO >$TMPDIR/keyring/env
	export SSH_AUTH_SOCK GPG_AGENT_INFO
}

# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
