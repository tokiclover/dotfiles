# $Id: $HOME/.zprofile,v 1.1 2011/11/16 -tclover Exp $
#
if [[ -e /etc/profile.env ]] { source /etc/profile.env }
export EDITOR=${EDITOR:-/bin/nano}
export PAGER=${PAGER:-/usr/bin/less}
# 077 would be more secure, but 022 is generally quite realistic
umask 022
# set path
if [[ $EUID = 0 || $USER = root ]] {
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}
} else { PATH=/usr/local/bin:/usr/bin:/bin:${PATH} }
export PATH
unset ROOTPATH

for sh (/etc/profile.d/*.sh) [[ -r $sh ]] && source $sh
unset sh
#
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
