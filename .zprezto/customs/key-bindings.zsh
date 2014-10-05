#
# This is an extended numeric pad keys mapping when <num_lock> is unset.
# The last are combination of <Right_S>|<Right_C>+<Left>|<Up>|<Right>|<Down>
#
# key-bindings.zsh
#

bindkey -s '\EOa' '\C-[A'
bindkey -s '\EOb' '\C-[B'
bindkey -s '\EOc' '\C-[C'
bindkey -s '\EOd' '\C-[D'

autoload -Uz copy-earlier-word
zle -N copy-earlier-word

for keymap in 'emacs' 'viins'; do
	bindkey -M "$keymap" "\EOw" beginning-of-line
	bindkey -M "$keymap" "\EOq" end-of-line
	bindkey -M "$keymap" "\EOt" backward-char
	bindkey -M "$keymap" "\EOv" forward-char

	bindkey -M "$keymap" "\EOr" down-line-or-history
	bindkey -M "$keymap" "\EOs" end-of-history
	bindkey -M "$keymap" "\EOx" up-line-or-history
	bindkey -M "$keymap" "\EOy" beginning-of-history

	bindkey -M "$keymap" "\EOn" backward-delete-char
	bindkey -M "$keymap" "\EOp" vi-cmd-mode
	bindkey -M "$keymap" "\EOu" delete-char
	bindkey -M "$keymap" "\EOM" accept-line

	bindkey -M "$keymap" "\E[a" copy-earlier-word
	bindkey -M "$keymap" "\E[b" backward-kill-line
	bindkey -M "$keymap" "\E[c" backward-kill-word
	bindkey -M "$keymap" "\E[d" kill-word
	bindkey -M "$keymap" "\C[A" undo
	bindkey -M "$keymap" "\C[B" redo
	bindkey -M "$keymap" "\C[C" forward-word
	bindkey -M "$keymap" "\C[D" backward-word
done
unset keymap

#
# vim:fenc=utf-8:tw=80:sw=2:sts=2:ts=2:
#
