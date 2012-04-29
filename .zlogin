# $Id: ~/.zlogin, 2012/04/29 -tclover Exp $
# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] { startx &> ~/.xsession-errors & }
# start gnome-keyring
if [[ -n $DISPLAY ]] && [[ -z $GNOME_KEYRING_PID ]] {
	eval $(gnome-keyring-daemon)
	export GNOME_KEYRING_PID
	export GNOME_KEYRING_SOCKET
	export SSH_AUTH_SOCK
	export GPG_AGENT_INFO
}
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
