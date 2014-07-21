# $Id: ~/.zshenv, 2014/07/15 09:52:36 -tclover Exp $
export ZDOTDIR=$HOME
export ZLS_COLORS=${LS_COLORS}
export ZSH=$HOME/.oh-my-zsh
export ECORE_IMF_MODULE="xim"
FHP=$(print $HOME/.mozilla/firefox/*.default(/))
[[ -n $FHP ]] && export FHP
export CDPATH='.:~:/var/src/git-src:/var/src/egit-src:/var/src/svn-src:/usr/src:/mnt'
export GTK2_RC_FILES=$HOME/.gtkrc-2.0
export XDG_CONFIG_HOME=$HOME/.config
export XMODIFIERS="@im=none"
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
