#
# $Header: ${HOME}/.bashrc                              Exp $
# $Version: 2015/05/15                                  Exp $
#

shopt -qs extglob
shopt -qs nullglob

if [[ -f ~/lib/aliasrc ]]; then
	source ~/lib/aliasrc
fi
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion
fi

pushd "${HOME}"/lib >/dev/null 2>&1
for file in *.bash; do
	source ${file}
done
popd >/dev/null 2>&1
pushd "${HOME}"/bin >/dev/null 2>&1
for file in *.bash; do
	alias ${file%.bash}='~/bin/'${file}
done
popd >/dev/null 2>&1

[[ "${PROMPT_COMMAND}" ]] && ${PROMPT_COMMAND}

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
