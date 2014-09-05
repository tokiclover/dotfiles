# $Id: ~/.bash_profile, 2014/08/31 08:03:53 -tclover Exp $

shopt -s cdspell
shopt -s extglob
shopt -s cdable_vars
set -o vi

if [[ ${UID} = 0 ]] || [[ ${USER} = root ]]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"; fi
export PATH
unset ROOTPATH

[[ -f ~/.Xprofile ]] && source ~/.Xprofile

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
