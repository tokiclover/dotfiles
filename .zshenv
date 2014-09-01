# $Id: ~/.zshenv, 2014/08/31 09:52:36 -tclover Exp $

export ZDOTDIR=$HOME
export ZLS_COLORS=${LS_COLORS}
export FHPDIR=$(print $HOME/.mozilla/firefox/*.default(/) 2>/dev/null)

if [[ -f ~/.Xprofile ]] { source ~/.Xprofile }

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
