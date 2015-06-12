#
# $Header: ${HOME}/.zprofile                            Exp $
# $Version: 2015/05/15                                  Exp $
#

if [[ -f ~/.Xprofile ]] { source ~/.Xprofile }

for sh (/etc/profile.d/*.sh) if [[ -r ${sh} ]] { source ${sh} }
unset sh

#
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
#
