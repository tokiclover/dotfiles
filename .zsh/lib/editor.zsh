#
# $Header: ${HOME}/.zsh/lib/editor.zsh                  Exp $
#
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $Author: (c) prior-to-2012 Robby Russel and others    Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2015/05/15 21:09:26                         Exp $
#

zmodload zsh/terminfo

function copy-to-clipboard {
	[[ -n "${LBUFFER}${RBUFFER}" ]] && echo ${LBUFFER}${RBUFFER} | xclip -i
}
function paste-from-clipboard {
	CLIPOUT=$(xclip -o)
	BUFFER=${LBUFFER}${CLIPOUT}${RBUFFER}
}
zle -N paste-from-clipboard
zle -N copy-to-clipboard

bindkey "\C-P" paste-from-clipboard
bindkey "\C-Y" copy-to-clipboard 
bindkey "\E[Z" reverse-menu-complete

bindkey "${terminfo[kbs]}"   backward-delete-char
bindkey "${terminfo[khome]}" beginning-of-line
bindkey "${terminfo[kend]}"  end-of-line
bindkey "${terminfo[kpp]}"   up-line-or-history
bindkey "${terminfo[knp]}"   down-line-or-history
bindkey "${terminfo[kdch1]}" delete-char

bindkey "\C-L"  clear-screen
bindkey "\C-Xl" screenclearx

bindkey -M vicmd "ga" what-cursor-position
bindkey -M viins "\E\C-R" redisplay
bindkey -M vicmd "\C-R" redisplay2
bindkey -M vicmd "c" vi-change
bindkey -M vicmd "C" vi-change-eol
bindkey -M vicmd "S" vi-change-whole-line
bindkey -M vicmd "s" vi-substitute
bindkey -M vicmd "g~" vi-oper-swap-case

if [[ ${EDITOR} =~ vi ]]; then
	bindkey -v
else
	bindkey -e
fi

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
