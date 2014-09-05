# $Id: ~/.zshrc, 2014/08/31 22:01:25 -tclover Exp $

setopt extended_glob

if [[ -f ~/.dir_colors ]] {
	eval $(dircolors -b ~/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] {
	eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }

if [[ -f ~/.prezto/init.zsh ]] {
	zstyle ':prezto:module:editor' key-bindings 'vi'
	zstyle ':prezto:module:prompt' theme 'clover'
	zstyle ':prezto:load' pmodule 'environment' 'terminal' \
		'editor' 'prompt' 'syntax-highlighting'
	source $ZSH/init.zsh
}

if [[ -f ~/.aliasrc ]] { source ~/.aliasrc }
if [[ -f ~/scr/functions.zsh ]] { source ~/scr/functions.zsh }

for scr (~/scr/*.zsh)
	if [[ -x $scr ]] { alias ${${scr:t}%.zsh}='~/scr/'${scr:t} }

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
