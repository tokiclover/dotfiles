# $Id: ~/.zshrc, 2014/08/31 22:01:25 -tclover Exp $

setopt extended_glob

if [[ -f ~/.dir_colors ]] {
	eval $(dircolors -b ~/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] {
	eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }

if [[ -e $ZSH/oh-my-zsh.sh ]] {
	plugins=(vi-mode zsh-syntax-highlighting)
	ZSH=$HOME/.oh-my-zsh
	ZSH_THEME=clover
	source $ZSH/oh-my-zsh.sh
}

if [[ -f ~/.aliasrc ]] { source ~/.aliasrc }
if [[ -f ~/scr/functions.zsh ]] { source ~/scr/functions.zsh }

for scr (~/scr/*.zsh)
	if [[ -x $scr ]] { alias ${${scr:t}%.zsh}='~/scr/'${scr:t} }

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
