# $Id: ~/.zshrc, 2014/09/09 22:01:25 -tclover Exp $

setopt extended_glob

if [[ -f ~/.dir_colors ]] {
	eval $(dircolors -b ~/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] {
	eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }

if [[ -f ~/.zprezto/init.zsh ]] {
	source ~/.zprezto/init.zsh
	if [[ -e ~/.zprezto/customs/key-bindings.zsh ]] {
		source ~/.zprezto/customs/key-bindings.zsh
	}
} elif [[ -f ~/key-bindings.zsh ]] {
	source ~/key-bindings.zsh
}

autoload -Uz promptinit
promptinit
if [[ -e ~/.zprezto/modules/prompt/functions/prompt_clover_setup ]] {
	source ~/.zprezto/modules/prompt/functions/prompt_clover_setup
}


if [[ -f ~/.aliasrc ]] { source ~/.aliasrc }
if [[ -f ~/scr/functions.zsh ]] { source ~/scr/functions.zsh }

for scr (~/scr/*.zsh)
	if [[ -x $scr ]] { alias ${${scr:t}%.zsh}='~/scr/'${scr:t} }

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
