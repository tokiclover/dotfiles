#
# $Header: ~/.bashrc, 2014/09/28 22:52:41 -tclover Exp $
#

shopt -qs extglob
shopt -qs nullglob

if [[ -f ~/lib/aliasrc ]]; then
	source ~/lib/aliasrc
fi
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

if [[ -f ~/lib/functions.bash ]]; then
	source ~/lib/functions.bash
fi

for script in ~/bin/*.bash; do
	if [[ -x "$script" ]]; then
		alias $(basename ${script%.bash})='~/bin/'${script##*/}
	fi
done

[[ "$PROMPT_COMMAND" ]] && $PROMPT_COMMAND

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
