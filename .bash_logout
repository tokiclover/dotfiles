# $Id: ~/.bash_logout, 2012/07/20 13:28:32 -tclover Exp $
[[ -n $GNOME_KEYRING_PID ]] && kill -TERM $GNOME_KEYRING_PID
[[ -n $DISPLAY ]] && [[ $UID != 0 ]] && fhp 1>/dev/null 2>&1
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
