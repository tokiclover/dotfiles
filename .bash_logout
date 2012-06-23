# $Id: ~/.bash_logout, 2011/11/15 -tclover Exp $
[[ -n $GNOME_KEYRING_PID ]] && kill -TERM $GNOME_KEYRING_PID
[[ -n $DISPLAY ]] && [[ $UID != 0 ]] && fhp &>/dev/null
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
