# $Id: ~/.bashrc, 2014/07/22 22:52:41 -tclover Exp $

[[ $- != *i* ]] && return
if [[ -f ~/.aliasrc ]]; then
	source ~/.aliasrc
fi
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

if [[ -f ~/scripts/functions.bash ]]; then
	source ~/scripts/functions.bash
fi

for scr in $(ls ~/scripts/*.bash); do
	if [[ -x $scr ]]; then
		alias $(basename ${scr%.bash})='~/scripts/'${scr##*/}
	fi
done

[[ -n "$PROMPT_COMMAND" ]] && $PROMPT_COMMAND

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
