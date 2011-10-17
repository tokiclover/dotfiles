# $Id: $HOME/.bashrc,v 1.1 2011/10/17 -tclover Exp $

# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return; fi

# FUN stuff

[[ -f $HOME/.aliasrc ]] && . $HOME/.aliasrc

bash_prompt() {
	## ANSI color codes
	local RS="\e[0m" # reset
	local HC="\e[1m" # hicolor
	local UL="\e[4m" # underline
	local BL="\e[5m" # blink
	local INV="\e[7m" # inverse background and foreground
	local FBLK="\e[30m" # foreground black
	local FRED="\e[31m" # foreground red
	local FGRN="\e[32m" # foreground green
	local FYEL="\e[33m" # foreground yellow
	local FBLE="\e[34m" # foreground blue
	local FMAG="\e[35m" # foreground magenta
	local FCYN="\e[36m" # foreground cyan
	local FWHT="\e[37m" # foreground white
	local BBLK="\e[40m" # background black
	local BRED="\e[41m" # background red
	local BGRN="\e[42m" # background green
	local BYEL="\e[43m" # background yellow
	local BBLE="\e[44m" # background blue
	local BMAG="\e[45m" # background magenta
	local BCYN="\e[46m" # background cyan
	local BWHT="\e[47m" # background white
	
	## Check PWD length
	local PROMPT="┌──(\u::\h:$(tty|cut -b6-|tr '/' ':')::\t)───()───"
	if [[ $COLUMNS -lt $((${#PROMPT}+${#PWD}+8)) ]]; then
		local LENGTH=$((${#COLUMNS}-${#PROMPT}+${#PWD}+8))
		local NPWD=...${PWD:((${#COLUMNS}-$LENGTH)):$LENGTH}
	else NPWD=$PWD; fi
	[[ -n "${NPWD%%HOME*}" ]] && NPWD=${NPWD/$HOME/\~}

	## And the prompt
	case "$TERM" in
	xterm*|rxvt*)
    		PS1="$FCYN┌$HC$FBLE─$FBLE─($FMAG\u$FBLE::$FMAG\h:$FMAG$(tty|cut -b6-|tr '/' ':'\
			)$FBLE::$FMAG\t$FBLE)─$HC$FBLE─$FBLE─($FMAG$NPWD$FBLE)─$HC$FBLE─$FBLK─\
			\n$FCYN└$HC$FBLE─$FBLE─\$$RS "
   		PS2="$FRED> $FMAG"
         	TITLEBAR='\e]0;\u:${NPWD}\007'
		;;
	linux*)
    		PS1="$FCYN┌$HC$FBLE─$FBLE─($FMAG\u$FBLE::$FMAG\h:$FMAG$(tty|cut -b6-|tr '/' ':'\
			)$FBLE::$FMAG\t$FBLE)─$HC$FBLE─$FBLE─($FMAG$NPWD$FBLE)─$HC$FBLE─$FBLK─\
			\n$FCYN└$HC$FBLE─$FBLE─\$$RS "
   		PS2="$FRED> $FMAG"
		;;
	*)
		PS1="$FBLE[$FMAG\u$FBLE::$FMAG\h:$(tty|cut -b6-)$FBLE::$FMAG\W$FBLE]─\$$RS "
		;;
    esac
}

PROMPT_COMMAND=bash_prompt
bash_prompt

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
	. /etc/bash_completion; fi
