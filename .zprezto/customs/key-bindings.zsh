#
# key-bindings.zsh
#

if zstyle -t ':prezto:module:editor' key-bindings 'emacs' 'vi'; then
  for keymap in 'emacs' 'viins' 'vicmd'; do
    bindkey -M "$keymap" "\EOw" beginning-of-line
    bindkey -M "$keymap" "\EOq" end-of-line
    bindkey -M "$keymap" "\EOt" backward-char
    bindkey -M "$keymap" "\EOv" forward-char

    bindkey -M "$keymap" "\EOr" down-line-or-history
    bindkey -M "$keymap" "\EOs" end-of-history
    bindkey -M "$keymap" "\EOx" up-line-or-history
    bindkey -M "$keymap" "\EOy" beginning-of-history

    bindkey -M "$keymap" "\EOn" backward-delete-char
    bindkey -M "$keymap" "\EOp" overwrite-mode
    bindkey -M "$keymap" "\EOu" delete-char

    bindkey -M "$keymap" "\EOd" backward-word
    bindkey -M "$keymap" "\EOc" forward-word
  done
fi
unset keymap

#
# vim:fenc=utf-8:tw=80:sw=2:sts=2:ts=2:
#
