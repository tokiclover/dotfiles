# $Id: ~/.bashrc, 2012/04/29 -tclover Exp $
[[ $- != *i* ]] && return
[[ -f ~/.aliasrc ]] && source ~/.aliasrc
export FHP=$(ls -d ~/.mozilla/firefox/*.default)

## ANSI color codes
RS="\e[0m" # reset
HC="\e[1m" # hicolor
UL="\e[4m" # underline
BL="\e[5m" # blink
INV="\e[7m" # inverse background and foreground
FBLK="\e[30m" # foreground black
FRED="\e[31m" # foreground red
FGRN="\e[32m" # foreground green
FYEL="\e[33m" # foreground yellow
FBLE="\e[34m" # foreground blue
FMAG="\e[35m" # foreground magenta
FCYN="\e[36m" # foreground cyan
FWHT="\e[37m" # foreground white
BBLK="\e[40m" # background black
BRED="\e[41m" # background red
BGRN="\e[42m" # background green
BYEL="\e[43m" # background yellow
BBLE="\e[44m" # background blue
BMAG="\e[45m" # background magenta
BCYN="\e[46m" # background cyan
BWHT="\e[47m" # background white

bash_prompt() {
	## Check PWD length
	local PROMPT="---($USER::$(uname -n):$(tty|cut -b6-|tr '/' ':')::)---()---"
	if [[ $COLUMNS -lt $((${#PROMPT}+${#PWD}+13)) ]]; then
		local LENGTH=$((${COLUMNS}-${#PROMPT}-16))
		local NPWD=...${PWD:(($COLUMNS-$LENTH)):$LENGTH}
	else NPWD=$PWD; fi
	[[ -n "${NPWD%%HOME*}" ]] && NPWD=${NPWD/~/\~}
	## And the prompt
	case "$TERM" in
	xterm*|rxvt*)
    		PS1="$FCYN┌$HC$FBLE─$FBLE─($FMAG\u$FBLE::$FMAG\h:$FMAG$(tty|cut -b6-|tr '/' ':'\
			)$FBLE::$FMAG\t$FBLE)─$HC$FBLE─$FBLE─($FMAG$NPWD$FBLE)─$HC$FBLE─$FBLK─\n$FCYN└$HC$FBLE─$FBLE─\$$RS "
   		PS2="$FRED> $FMAG"
         	TITLEBAR="\u::${NPWD}"
		;;
	linux*)
    		PS1="$FCYN┌$HC$FBLE─$FBLE─($FMAG\u$FBLE::$FMAG\h:$FMAG$(tty|cut -b6-|tr '/' ':'\
			)$FBLE::$FMAG\t$FBLE)─$HC$FBLE─$FBLE─($FMAG$NPWD$FBLE)─$HC$FBLE─$FBLK─\
			\n$FCYN└$HC$FBLE─$FBLE─\$$RS "
   		PS2="$FRED> $FMAG"
		;;
	*) PS1="$FBLE($FMAG\u$FBLE::$FMAG\h:$(tty|cut -b6-)$FBLE::$FMAG\W$FBLE)─\$$RS ";;
    esac
}

PROMPT_COMMAND=bash_prompt
bash_prompt

if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	source /etc/bash_completion; fi
#
# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
