# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !


# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
	# Shell is non-interactive.  Be done now!
	return
fi

# FUN stuff

[ -f $HOME/.aliasrc ] && . $HOME/.aliasrc

bash_prompt() {
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
	
	## Check PWD length
	PROMPT="┌──(\u::\h:$(tty|cut -b6-|tr '/' ':')::\t)───()───"
	if [[ $COLUMNS -lt $((${#PROMPT}+${#PWD}+8)) ]]; then
		LENGTH=$((${#COLUMNS}-${#PROMPT}+${#PWD}+8))
		NPWD=...${PWD:((${#COLUMNS}-$LENGTH)):$LENGTH}
	else NPWD=$PWD; fi

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
   		PS1="$HC$FCYN┌$FCYN─$HC$FBLE─(\u$FMAG@$FBLE\h:$FMAG$(\
			tty|cut -b6-|tr '/' ':'))$FMAG────$FBLE(\w)$HC$FCYN─$HC$FBLE─$FBLK─\
			\n$FCYN└$FCYN─$HC$FBLE─\$$RS "
   		PS2="$FRED> $FMAG"
		;;
	*)
	 	PS1="\u@\h:\t:$(tty|cut -b6-):\w\$ "
		;;
    esac
}

PROMPT_COMMAND=bash_prompt
bash_prompt

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
	. /etc/bash_completion; fi
