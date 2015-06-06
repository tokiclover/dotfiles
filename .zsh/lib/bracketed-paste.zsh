#
# $Header: ${HOME}/.zsh/lib/bracketed-paste.zsh         Exp $
#
# Bracketed paste handle quoting, newline when handling
# contents with special characters, e.g URL.
#
# $Dependencies: XTerm, URxvt or other terminals        Exp $
#   Ref: http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
#
# $Authors: 
#   Mikael Magnusson 
#     (Ref: http://www.zsh.org/mla/users/2011/msg00367.html)
#   tokiclover <tokiclover@gamil.com> (Cleanup/Restore-keymap)
# $Version: 2015/05/15 21:09:26                         Exp $
#

# Create a new keymap to use while pasting
bindkey -N paste
# Make everything in this keymap call our custom widget
# with bracketed code sequences in paste mode
bindkey -R -M paste "^@"-"\M-^?" paste-insert
# First one need both -M viins and -M vicmd in vi mode
for keymap (emacs viins vicmd)
  bindkey -M $keymap '^[[200~' start-paste
unset keymap
bindkey -M paste '^[[201~' end-paste
# Replace carriage returns by newlines when pasting newlines
bindkey -M paste -s '^M' '^J'

zle -N start-paste
zle -N end-paste
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
zle -N paste-insert

# Switch the active keymap to paste mode
function start-paste {
  bindkey -A paste main
}

# Restore keymap, and insert all the pasted text in the command line which
# has the effect of making the whole paste be single undo/redo event.
function end-paste {
  case $_keymap {
    (viins) bindkey -v;;
    (vicmd) bindkey -a;;
    (emacs) bindkey -e;;
  }
  LBUFFER+=$_paste_content
  unset _keymap _paste_content
}

function paste-insert {
  _paste_content+=$KEYS
}

function zle-keymap-select {
  # Save the old keymap
  _keymap=$1
}

function zle-line-init {
  # Send escape codes around pastes
  case $TERM {
	  (rxvt*|xterm*|screen*) printf '\e[?2004h';;
  }
}

function zle-line-finish {
  # Stop send escape codes around pastes
  case $TERM {
	  (rxvt*|xterm*|screen*) printf '\e[?2004l';;
	}
}

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:expandtab
#
