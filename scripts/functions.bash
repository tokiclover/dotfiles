# $Id: $HOME/scripts/functions.bash, 2014/07/31 12:59:26 -tclover Exp $

[[ -f ~/scripts/functions ]] && source ~/scripts/functions

# @FUNCTION: die
# @DESCRIPTION: hlper function, print error message to stdout
# @USAGE: <string>
function eerror() { 
	echo -ne "${0##*/}: \e[1;31m \e[0m$@\n"
	[[ -n "$LOG" ]] && [[ -n "$facility" ]] &&
	logger -p $facility "${0##*/}: $@"
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
function einfo() { 
	echo -ne "${0##*/}: \e[1;32m \e[0m$@\n"
	[[ -n "$LOG" ]] && [[ -n "$facility" ]] &&
	logger -p $facility "${0##*/}: $@"
}

# @FUNCTION: mktmp
# @DESCRIPTION: make tmp dir or file in ${TMPDIR:-/tmp}
# @ARG: [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
function mktmp() {
	[[  $# == 0 ]] &&
	echo "usage: mktmp [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE" &&
	exit 1
	local type mode owner group tmp TMP=${TMPDIR:-/tmp}
	while [[ $# -ge 1 ]]; do
		case $1 in
			-d) type="dir"; shift;;
			-f) type="file"; shift;;
			-m) mode="$2"; shift 2;;
			-o) owner="$2"; shitf 2;;
			-g) group="$2"; shift 2;;
		 	*) tmp="$1"; shift;;
		esac
	done
	[[ -n "$tmp" ]] && TMP+=/"$tmp"-XXXXXX ||
	die "mktmp: no $tmp TEMPLATE provided"
	if [[ "$type" == "dir" ]]; then
		mkdir -p ${mode:+-m$mode} "$TMP" ||
		die "mktmp: failed to make $TMP"
	else
		mkdir -p ${TMP%/*} &&
		touch "$TMP" || die "mktmp: failed to make $TMP"
		[[ -n "$mode" ]] && chmod $mode "$TMP"
	fi
	[[ -n "$owner" ]] && chown "$owner" "$TMP"
	[[ -n "$group" ]] && chgrp "$group" "$TMP"
	echo "$TMP"
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
	PROMPT="---($USER$(uname -n):$(tty | cut -b6-)---()---"
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
		PS1="${fg[cyan]}┌${fbg[hicolor]}${fg[blue]}(${fg[magenta]}\$${fg[blue]}${fg[magenta]}\h:$(\
		tty | cut -b6-)${fg[blue]}⋅\D{%m/%d}⋅${fg[magenta]}\t${fg[blue]})${fbg[hicolor]}${fg[blue]}\
		(${fg[magenta]}$NPWD${fg[blue]})${fbg[hiclor]}${fg[blue]}${fg[black]}
		\n${fg[cyan]}${fbg[hicolor]}${fg[blue]}${fg[green]}${fbg[reset]}-» "
	 		PS2="${fg[blue]}${fg[green]} ${fbg[reset]}"
		TITLEBAR="\$${NPWD}"
		;;
	linux*)
		PS1="${fg[cyan]}┌${bfg[hicolor]}${fg[blue]}(${fg[magenta]}\$⋅${fg[magenta]}\h:$(\
		tty | cut -b6-)${fg[blue]}⋅\D{%m/%d}⋅${fg[magenta]}\t${fg[blue]})${fbg[hicolor]}${fg[blue]}(${fg[magenta]}\
		${NPWD}${fg[blue]})${fbg[hicolor]}${fg[blue]}${fg[black]}\n${fg[cyan]}${fbg[hicolor]}${fg[blue]}${fbg[reset]} "
		PS2="${fg[blue]}${fg[green]}${fbg[reset]}-»"
		;;
	*) PS1="${fg[blue]}(${fg[magenta]}\$${fg[blue]}\D{%m/%d}${fg[magenta]}\h:$(\
	tty | cut -b6-)${fg[blue]}${fg[magenta]}${fg[blue]})${fbg[reset]} "
		;;
	esac
}
# @ENV_VARIABLE: PROMPT_COMMAND
# @DESCRIPTION: bash prompt command
PROMPT_COMMAND=bash_prompt

# @FUNCTION: kmp-aa
# @DESCRIPTION: little helpter to retrieve Kernel Module Parameters
function kmp-aa () 
{ 
	local c d line m mc mod md de n=/dev/null o
	c=$(tput op) o=$(echo -en "\n$(tput setaf 2)-*- $(tput op)")
	if [[ -n "$*" ]]
	then
	  mod=($*)
	else
	  while read line
	  do
	      mod+=( ${line%% *})
	  done </proc/modules
	fi
	for m in ${mod[@]}
	do
	  md=/sys/module/$m/parameters
		[[ ! -d $md ]] && continue
		d=$(modinfo -d $m 2>$n | tr '\n' '\t')
		echo -en "$o$m$c"
		[[ ${#d} -gt 0 ]] && echo -n " - $d"
		echo
		pushd $md >$n 2>&1
		for mc in *
		do
			de=$(modinfo -p $m 2>$n | grep ^$mc 2>$n | sed "s/^$mc=//" 2>$n)
			echo -en "\t$mc=$(cat $mc 2>$n)"
			[[ ${#de} -gt 1 ]] && echo -en " - $de"
			echo
		done
		popd >$n 2>&1
	done
}


# @FUNCTION: kmp-color
# @DESCRIPTION: colorful helper to retrieve Kernel Module Parameters
function kmp-color ()
{
	local green yellow cyan reset
	if tty -s <&1
	then
	  green="${fg[green]}"
	  yellow="${fg[yellow]}"
	  cyan="${fg[cyan]}"
	  reset="${bfg[reset]}"
	fi
	newline='
'

	local d line m mc md mod n=/dev/null
	if [[ -n "$*" ]]
	then
	  mod=($*)
	else
	  while read line
	  do
	      mod+=( ${line%% *})
	  done </proc/modules
	fi
	for m in ${mod[@]}
	do
	  md=/sys/module/$m/parameters
	  [[ ! -d $md ]] && continue
	  d="$(modinfo -d $m 2>$n | tr '\n' '\t')"
	  echo -en "$green$m$reset"
	  [[ ${#d} -gt 0 ]] && echo -n " - $d"
	  echo
	  declare pnames=() pdescs=() pvals=()
	  local add_desc=false p pdesc pname
	  while IFS="$newline" read p
	  do
	    if [[ $p =~ ^[[:space:]] ]]
	    then
		    pdesc+="$newline	$p"
	    else
		    $add_desc && pdescs+=("$pdesc")
		    pname="${p%%:*}"
		    pnames+=("$pname")
		    pdesc=("	${p#*:}")
		    pvals+=("$(cat $md/$pname 2>$n)")
	    fi
	    add_desc=true
	  done < <(modinfo -p $m 2>$n)
	  $add_desc && pdescs+=("$pdesc")
	  for ((i=0; i<${#pnames[@]}; i++))
	  do
	    [[ -z ${pnames[i]} ]] && continue
	    printf "  $cyan%s$reset = $yellow%s$reset\n%s\n" \
		  ${pnames[i]} \
		  "${pvals[i]}" \
		  "${pdescs[i]}"
	  done
	  echo
	done
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=4:sw=4:ts=4:
