# $Id: $HOME/.bash_profile,v 1.1 2011/11/16 -tclover Exp $
#
[[ -f $HOME/.bashrc ]] && source $HOME/.bashrc
shopt -s cdspell
shopt -s extglob
shopt -s cdable_vars
set -o vi
if [[ $UID = 0 ]] || [[ $USER = root ]]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"
	function adt() { source $HOME/.scripts/addt.sh; }
	function ffp() { source $HOME/.scripts/ffp-pack; }; fi
export PATH
unset ROOTPATH
#
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
