# $Id: ~/.zlogout$
if [[ -n $GNOME_KEYRING_PID ]] { kill -TERM $GNOME_KEYRING_PID }
if [[ -n $DISPLAY ]] && [[ $EUID != 0 ]] { fhp 1>/dev/null 2>&1 }
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
