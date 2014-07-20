# $Id: ~/.zlogin, 2014/07/15 08:40:49 -tclover Exp $
# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] && [[ ${$(tty)#*tty} -le 3 ]] { 
	startx 1>~/.xsession-errors 2>&1 &
}
# start gnome-keyring
if [[ -f /tmp/.private/$USER/keyring/env ]] {
	while read line; do
		export $line
	done </tmp/.private/$USER/keyring/env
	if [[ "$(ps aux | grep $GNOME_KEYRING_PID | head -n1 | awk '{print $1}')" != $USER ]] {
		unset GNOME_KEYRING_PID
	}
}
if [[ -z $GNOME_KEYRING_PID ]] {
	eval $(gnome-keyring-daemon --daemonize --components=pkcs11,secrets,ssh,gpg)
	echo GNOME_KEYRING_PID=$GNOME_KEYRING_PID >/tmp/.private/$USER/keyring/env
	echo GNOME_KEYRING_CONTROL=$GNOME_KEYRING_CONTROL >>/tmp/.private/$USER/keyring/env
	echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK >>/tmp/.private/$USER/keyring/env
	echo GPG_AGENT_INFO=$GPG_AGENT_INFO >>/tmp/.private/$USER/keyring/env
	export GNOME_KEYRING_PID GNOME_KEYRING_CONTROL SSH_AUTH_SOCK GPG_AGENT_INFO
}
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
