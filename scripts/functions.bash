# $Id: $HOME/scripts/functions.bash,v 2014/07/07 11:59:26 -tclover Exp $

# @FUNCTION: die
# @DESCRIPTION: hlper function, print error message to stdout
# @USAGE: <string>
error() { 
	echo -ne "${0##*/}: \e[1;31m \e[0m$@\n"
	$LOG && logger -p $facility.err "${0##*/}: $@"
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die() {
	local ret=$?
	error "$@"
	exit $ret
}

# @FUNCTION: into
# @DESCRIPTION: hlper function, print info message to stdout
# @USAGE: <string>
function info() { 
	echo -ne "${0##*/}: \e[1;32m \e[0m$@\n"
	$LOG && logger -p $facility.info "${0##*/}: $@"
}

# ANSI color codes for bash_prompt function
declare -A bg fg bfg
bfg=([reset]="\e[0m" [hicolor]="\e[1m" [underline]="\e[4m" [blink]="\e[5m" [inverse]="\e[7m")
fg=([black]="\e[30m" [red]="\e[31m" [green]="\e[32m" [yellow]="\e[33m" [blue]="\e[34m" \
	[magenta]="\e[35m" [cyan]="\e[36m" [white]="\e[37m")
bg=([black]="\e[40m" [red]="\e[41m" [green]="\e[42m" [yellow]="\e[43m" [blue]="\e[44m" \
	[magenta]="\e[45m" [cyan]="\e[46m" [white]="\e[47m")

# @FUNCTION: bash_prompt
# @DESCRIPTION: bash prompt function
function bash_prompt() {
	# Check PWD length
	local PROMPT COLUMNS LENGTH NPWD
	PROMPT="---($USER·$(uname -n):$(tty | cut -b6-)·---()---"
	if [[ $COLUMNS -lt $((${#PROMPT}+${#PWD}+13)) ]]; then
		LENGTH=$((${COLUMNS}-${#PROMPT}-16))
		NPWD=...${PWD:COLUMNS-LENGTH:LENGTH}
	else
		NPWD="$PWD"
	fi
	[[ -n "${NPWD%%HOME*}" ]] && NPWD=${NPWD/~/\~}
	# And the prompt
	case "$TERM" in
	xterm*|rxvt*)
		PS1="${fg[cyan]}┌${fbg[hicolor]}${fg[blue]}──(${fg[magenta]}\$${fg[blue]}·${fg[magenta]}\h:$(\
		tty | cut -b6-)${fg[blue]}·\D{%m/%d}${fg[magenta]}·\t${fg[blue]})─${fbg[hicolor]}${fg[blue]}──\
		(${fg[magenta]}$NPWD${fg[blue]})─${fbg[hiclor]}${fg[blue]}─${fg[black]}─\
		\n${fg[cyan]}└${fbg[hicolor]}${fg[blue]}──${fg[green]}»${fbg[reset]} "
   		PS2="${fg[blue]}─${fg[green]}» ${fbg[reset]}"
        TITLEBAR="\$·${NPWD}"
		;;
	linux*)
		PS1="${fg[cyan]}┌${bfg[hicolor]}${fg[blue]}──(${fg[magenta]\$${fg[blue]}·\D{%m/%d}·${fg[magenta]}\h:$(\
		tty | cut -b6-)$[fg[blue]}·${fg[magenta]}\t${fg[blue]})─${fbg[hicolor]}${fg[blue]}──(${fg[magenta]$NPWD${fg[blue]})\
		─${fbg[hicolor]}${fg[blue]}─${fg[black]}─\n${fg[cyan]}└${fbg[hicolor]}${fg[blue]}──»${fbg[reset]} "
		PS2="${fg[blue]}─${fg[green]}» ${fbg[reset]}"
		;;
	*) PS1="${fg[blue]}(${fg[magenta]}\$${fg[blue]}·\D{%m/%d}·${fg[magenta]}\h:$(\
	tty | cut -b6-)${fg[blue]}·${fg[magenta]}\W${fg[blue]})─»${fbg[reset]} "
		;;
	esac
}
# @ENV_VARIABLE: PROMPT_COMMAND
# @DESCRIPTION: bash prompt command
PROMPT_COMMAND=bash_prompt

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
