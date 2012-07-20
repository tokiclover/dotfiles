# $Id: ~/.zlogin, 2012/07/20 13:22:07 -tclover Exp $
# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] && [[ ${$(tty)#*tty} -le 3 ]] { 
	startx 1>~/.xsession-errors 2>&1 &
}
# start gnome-keyring
if [[ -n $DISPLAY ]] && [[ -z $GNOME_KEYRING_PID ]] {
	eval $(gnome-keyring-daemon)
	export GNOME_KEYRING_PID
	export GNOME_KEYRING_SOCKET
	export SSH_AUTH_SOCK
	export GPG_AGENT_INFO
}
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
