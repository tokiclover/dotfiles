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
	if [[ -e ~/.zprezto/modules/prompt/functions/prompt_clover_setup ]] {
		source ~/.zprezto/modules/prompt/functions/prompt_clover_setup
	}
} else {
	if [[ -f ~/key-bindings.zsh ]] {
		source ~/key-bindings.zsh
	}
	if [[ -e ~/prompt_clover_setup ]] {
		autoload -Uz promptinit
		promptinit
		source ~/prompt_clover_setup
	}
}

if [[ -f ~/.aliasrc ]] { source ~/.aliasrc }

if [[ -d ~/.zprezto/customs/helpers ]] {
	fpath=(~/.zprezto/customs/helpers $fpath)
#	autoload -Uz precompile && precompile
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
