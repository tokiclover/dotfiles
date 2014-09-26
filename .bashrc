# $Id: ~/.bashrc, 2014/09/26 22:52:41 -tclover Exp $

shopt -qs extglob
shopt -qs nullglob

if [[ -f ~/.aliasrc ]]; then
	source ~/.aliasrc
fi
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

if [[ -f ~/scr/functions.bash ]]; then
	source ~/scr/functions.bash
fi

for scr in ~/scr/*.bash; do
	if [[ -x $scr ]]; then
		alias $(basename ${scr%.bash})='~/scr/'${scr##*/}
	fi
done

[[ -n "$PROMPT_COMMAND" ]] && $PROMPT_COMMAND

# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
