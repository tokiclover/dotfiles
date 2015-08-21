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
#   Bart Schafer
#     (Ref: http://www.zsh.org/mla/users/2015/msg00801.html
#           Bracketed paste for zsh 4.3.x up to 5.0.8)
# $Version: 1.0 2015/08/20 21:09:26                     Exp $
#

#
# FIXME: This versin works pretty but if and only if nothing goes wrong
#
ZV=(${(pws:.:)ZSH_VERSION})
if ! (( ${ZV[1]} >= 5 )) && ( (( ${ZV[2]} > 0 )) || (( ${ZV[3]} > 8 )) ) {

typeset -g main_keymap=emacs # or viins as you prefer
# Create keymap where all key strokes are self-insert-unmeta
bindkey -N paste
bindkey -R -M paste "^@"-"\M-^?" .self-insert-unmeta
# Swap keymaps during paste
function paste-begin {
  bindkey -A paste main
}
zle -N paste-begin
function paste-end {
  bindkey -A ${main_keymap} main
}
zle -N paste-end
bindkey -M paste '\e[201~' paste-end
bindkey '\e[200~' paste-begin
bindkey -a '\e[200~' paste-begin
# Turn on paste mode of terminal while editing
PROMPT+=$'%{\e[?2004h%}'
POSTEDIT=$'\e[?2004l'"$POSTEDIT"

}
unset ZV

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:expandtab
#
