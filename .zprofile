# $Id: ~/.zprofile, 2012/12/13 09:52:33 -tclover Exp $
export EDITOR=${EDITOR:-/bin/nano}
export PAGER=${PAGER:-/usr/bin/less}
# 077 would be more secure, but 022 is generally quite realistic
umask 022
# set path
if [[ ${EUID} = 0 ]] || [[ ${USER} = root ]] {
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}
} else { PATH=/usr/local/bin:/usr/bin:/bin:${PATH} }
export PATH
unset ROOTPATH
for sh (/etc/profile.d/*.sh) if [[ -r ${sh} ]] { source ${sh} }
unset sh
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
