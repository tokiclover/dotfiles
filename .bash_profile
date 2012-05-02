# $Id: ~/.bash_profile, 2012/05/02 -tclover Exp $
[[ -f ~/.bashrc ]] && source ~/.bashrc
shopt -s cdspell
shopt -s extglob
shopt -s cdable_vars
set -o vi
if [[ ${UID} = 0 ]] || [[ ${USER} = root ]]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"; fi
PATH+=:~/.scripts
export PATH
unset ROOTPATH
export FHP=$(ls -d ~/.mozilla/firefox/*.default)
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
