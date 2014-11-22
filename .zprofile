#
# $Heder: ~/.zprofile, 2014/11/18 08:04:40 -tclover Exp $
#

export EDITOR=${EDITOR:-/bin/nano}
export PAGER=${PAGER:-/usr/bin/less}

# Append path
export PATH="$PATH:$HOME/bin"

if [[ -f ~/.Xprofile ]] { source ~/.Xprofile }

for sh (/etc/profile.d/*.sh) if [[ -r ${sh} ]] { source ${sh} }
unset sh

#
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
#
