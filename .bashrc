# $Id: ~/.bashrc, 2014/07/07 22:52:41 -tclover Exp $

[[ $- != *i* ]] && return
[[ -f ~/.aliasrc ]] && source ~/.aliasrc

if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

if [[ -f ~/scripts/functions.bash ]]; then
	source ~/scripts/functions.bash
fi

for scr in $(ls ~/scripts/*.bash); do
	alias $(basename ${src/.bash/})='~/scripts/'${scr##*/}
done

[[ -n "$PROMPT_COMMAND" ]] && $PROMPT_COMMAND

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
