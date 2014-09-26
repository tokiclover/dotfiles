if zstyle -t ':prezto:module:editor' key-bindings 'emacs' 'vi'; then
  for keymap in 'emacs' 'viins'; do
    bindkey -M "$keymap" "\EOw" beginning-of-line
    bindkey -M "$keymap" "\EOq" end-of-line
    bindkey -M "$keymap" "\EOt" backward-char
    bindkey -M "$keymap" "\EOv" forward-char
    bindkey -M "$keymap" "\EOy" up-line-or-history
    bindkey -M "$keymap" "\EOs" down-line-or-history

    bindkey -M "$keymap" "\EOd" backward-word
    bindkey -M "$keymap" "\EOc" forward-word
    bindkey -M "$keymap" "\EOa" up-line-or-history
    bindkey -M "$keymap" "\EOb" down-line-or-history
  done
fi
unset keymap
