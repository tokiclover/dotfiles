# $Id: ~/.zprofile, 2013/06/26 08:04:40 -tclover Exp $

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

export CDPATH='.:~:/var/src/git-src:/var/src/egit-src:/var/src/svn-src:/usr/src:/mnt'
export ECORE_IMF_MODULE="xim"
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export XMODIFIERS="@im=none"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="/tmp/.private/$USER"

for sh (/etc/profile.d/*.sh) if [[ -r ${sh} ]] { source ${sh} }
unset sh

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
