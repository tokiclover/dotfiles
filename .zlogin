#
# $Header: ~/.zlogin, 2014/10/10 08:40:49 -tclover Exp $
#

# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] {
	[[ ${TTY/tty} != $TTY ]] && (( ${TTY:8:1} <= 3 )) &&
		startx 1>~/.log/xsession-errors 2>&1 &
}

# start gnome-keyring
if [[ -r $TMPDIR/keyring/env ]] {
	while read line; do
		export $line
	done <$TMPDIR/keyring/env
} else {
	mkdir -m 700 -p $TMPDIR/keyring
	eval export $(gnome-keyring-daemon -d -c pkcs11,secrets,ssh,gpg)
	echo -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK\
			"\n"GNOME_KEYRING_CONTROL=$GNOME_KEYRING_CONTROL\
	    "\n"GPG_AGENT_INFO=$GPG_AGENT_INFO >$TMPDIR/keyring/env
}

#
# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
#
