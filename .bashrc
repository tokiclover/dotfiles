# $Id: ~/.bashrc, 2014/07/31 22:52:41 -tclover Exp $

[[ $- != *i* ]] && return
if [[ -f ~/.aliasrc ]]; then
	source ~/.aliasrc
fi
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

if [[ -f ~/scr/functions.bash ]]; then
	source ~/scr/functions.bash
fi

for scr in $(ls ~/scr/*.bash); do
	if [[ -x $scr ]]; then
		alias $(basename ${scr%.bash})='~/scr/'${scr##*/}
	fi
done

[[ -n "$PROMPT_COMMAND" ]] && $PROMPT_COMMAND

# vim:fenc=utf-8:ft=bash:ci:pi:sts=0:sw=2:ts=2:
