# $Id: $HOME/.zlogout,v 1.1 2011/11/15 -tclover Exp $
#
# terminate gnome-keyring
[[ -n $GNOME_KEYRING_PID ]] && kill -TERM $GNOME_KEYRING_PID
[[ -n $DISPLAY ]] && [[ $UID != 0 ]] && ffp &>/dev/null
#
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
