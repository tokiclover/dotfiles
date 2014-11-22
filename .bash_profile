#
# $Header: ~/.bash_profile, 2014/11/18 08:03:53 -tclover Exp $
#

shopt -s cdspell
shopt -s extglob
shopt -s cdable_vars
set -o vi

# Append path
export PATH="$PATH:$HOME/bin"

[[ -f ~/.Xprofile ]] && source ~/.Xprofile

#
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
#
