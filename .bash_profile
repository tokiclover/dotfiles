# $Id: ~/.bash_profile, 2013/06/26 08:03:53 -tclover Exp $

[[ -f ~/.bashrc ]] && source ~/.bashrc
shopt -s cdspell
shopt -s extglob
shopt -s cdable_vars
set -o vi

if [[ ${UID} = 0 ]] || [[ ${USER} = root ]]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"; fi
export PATH
unset ROOTPATH

export CDPATH='.:~:/var/src/git-src:/var/src/egit-src:/var/src/svn-src:/usr/src:/mnt'
export ECORE_IMF_MODULE="xim"
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export XMODIFIERS="@im=none"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="/tmp/.private/$USER"

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
