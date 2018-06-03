#
# $Id: ~/.zshrc                               Exp $
#

setopt EXTENDED_GLOB
setopt INC_APPEND_HISTORY

if [[ -f ~/.dir_colors ]] {
	eval $(dircolors -b ~/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] {
	eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }

if [[ -d ~/.zsh/functions ]] {
	fpath=(~/.zsh/functions $fpath)
}

if [[ -f ~/.zprezto/init.zsh ]] {
	source ~/.zprezto/init.zsh
} else {
	if [[ -f ~/.zsh/lib/editor.zsh ]] {
		source ~/.zsh/lib/editor.zsh
	}
	if [[ -e ~/.zsh/functions/prompt_clover_setup ]] {
		autoload -Uz promptinit
		promptinit
		prompt clover
	}
	autoload -Uz precompile && precompile
}

for file (~/.zsh/lib/^(editor.zsh)*(.N)
	~/.zsh/functions/prompt_clover_setup ~/lib/{aliasrc,helpers})
	source $file
file=

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
#
