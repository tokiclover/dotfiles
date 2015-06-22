#
# $Header: ${HOME}/.xsession, 2015/06/20 15:32:37           Exp $
#

mkdir -p ~/.log
exec sh ~/.xinitrc > ~/.log/xsession-errors 2>&1

#
# vim:fenc=utf-8:ft=sh:tw=80:sw=2:sts=2:ts=2:
#
