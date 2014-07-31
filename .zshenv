# $Id: ~/.zshenv, 2014/07/31 09:52:36 -tclover Exp $

export ZDOTDIR=$HOME
export ZLS_COLORS=${LS_COLORS}
export ZSH=$HOME/.oh-my-zsh
export ECORE_IMF_MODULE="xim"
export FHPDIR=$(print $HOME/.mozilla/firefox/*.default(/) 2>/dev/null)
export GTK2_RC_FILES=$HOME/.gtkrc-2.0
export XDG_CONFIG_HOME=$HOME/.config
export XDG_RUNTIME_DIR="/tmp/.private/$USER"
export XMODIFIERS="@im=none"
export G_SLICE=always-malloc

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
