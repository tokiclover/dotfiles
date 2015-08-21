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
#   Bart Schafer
#     (Ref: http://www.zsh.org/mla/users/2015/msg00801.html
#           Bracketed paste for zsh 4.3.x up to 5.0.8)
# $Version: 2.0 2015/08/20 21:09:26                     Exp $
#

ZV=(${(pws:.:)ZSH_VERSION})
if ! ( (( ${ZV[1]} >= 5 )) && ( (( ${ZV[2]} > 0 )) || (( ${ZV[3]} > 8 )) ) ) {

function paste-end {
  :;
}
zle -N paste-end
function paste-begin {
  local bp_PASTED
  while zle .read-command; do
    case "$REPLY" in
      (paste-end) break;;
      (*) bp_PASTED="$bp_PASTED$KEYS";;
    esac
  done
  # This may not be necessary everywhere (fix newlines)
  eval bp_PASTED=\$\{bp_PASTED:gs/$'\r'/$'\n'\}
  if (( ARGC )); then
     builtin typeset -g "$1"="$bp_PASTED"
  else
    if (( REGION_ACTIVE )); then
       zle .kill-region
    fi
    LBUFFER="$LBUFFER$bp_PASTED"
  fi
}
zle -N paste-begin
# Haven't really tested with vicmd,
# but should work with "bindkey -a"
bindkey '\e[200~' paste-begin
bindkey '\e[201~' paste-end
# Still need this too in older shells
PROMPT+=$'%{\e[?2004h%}'
POSTEDIT=$'\e[?2004l'"$POSTEDIT"

}
unset ZV

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:expandtab
#
