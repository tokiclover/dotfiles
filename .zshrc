# $Id: ~/.zshrc, 2014/08/31 22:01:25 -tclover Exp $

if [[ -f ~/.dir_colors ]] {
	eval $(dircolors -b ~/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] {
	eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }

autoload -Uz vcs_info
zstyle ':vcs_info:*' disable bzr cdv darcs mtn svk tla
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:*' actionformats '%a'
zstyle ':vcs_info:*' formats       '·%s·%b%u'
zstyle ':vcs_info:(git|svn):*' branchformat '%b'

setopt EXTENDED_GLOB
plugins=(vi-mode zsh-syntax-highlighting)

ZSH=$HOME/.oh-my-zsh
ZSH_THEME=clover

if [[ -e $ZSH/oh-my-zsh.sh ]] { source $ZSH/oh-my-zsh.sh }

if [[ -f ~/.aliasrc ]] { source ~/.aliasrc }
for scr (~/scr/*.zsh)
	if [[ -x $scr ]] { alias ${${scr:t}%.zsh}='~/scr/'${scr:t} }

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
