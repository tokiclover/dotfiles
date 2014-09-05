# $Id: functions.bash, 2014/08/31 12:59:26 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)    Exp $

[[ -f ~/scr/functions ]] && source ~/scr/functions

# @FUNCTION: die
# @DESCRIPTION: hlper function, print error message to stdout
# @USAGE: <string>
function eerror()
{ 
	echo -ne "${0##*/}: \e[1;31m \e[0m$@\n" >&2
	[[ -n "$LOG" ]] && [[ -n "$facility" ]] &&
	logger -p $facility "${0##*/}: $@"
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die()
{
	local ret=$?
	error "$@"
	return $ret
}

# @FUNCTION: into
# @DESCRIPTION: hlper function, print info message to stdout
# @USAGE: <string>
function einfo()
{ 
	echo -ne "${0##*/}: \e[1;32m \e[0m$@\n"
	[[ -n "$LOG" ]] && [[ -n "$facility" ]] &&
	logger -p $facility "${0##*/}: $@"
}

# @FUNCTION: mktmp
# @DESCRIPTION: make tmp dir or file in ${TMPDIR:-/tmp}
# @ARG: [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
function mktmp()
{
	usage='cat <<-EOF
usage: mktmp [options] TEMPLATE
  -d, --dir           create a directory
  -f, --file          create a file
  -o, --owner <name>  owner naame
  -g, --group <name>  group name
  -m, --mode <1700>   octal mode
  -h, --help          help/exit
EOF
exit'
	
	[[ $# == 0 ]] && $usage
	
	local type mode owner group tmp TMP=${TMPDIR:-/tmp}
	while [[ $# -ge 1 ]]; do
		case $1 in
			-d|--dir) type=dir; shift;;
			-f|--file) type=file; shift;;
			-h|--help) $usage;;
			-m|--mode) mode=$2; shift 2;;
			-o|--owner) owner="$2"; shitf 2;;
			-g|--group) group="$2"; shift 2;;
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
declare -a COLORS CHARS
COLOR=(black red green yellow blue magenta cyan white)
SGR07=(reset bold faint italic underline sblink rblink inverse)

# @FUNCTION: bash_prompt
# @DESCRIPTION: bash prompt function
# @USAGE: bash_prompt [4-color]
# if 256 colors is suported, color can be in [0-255] range check out
# ref: http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
function bash_prompt()
{
	# Initialize colors arrays
	declare -A BG FG FB
	local B C CLR=$(tput colors) E="\e[" F
	if [[ "$CLR" -ge 256 ]]; then
		B="${E}48;5;"
		F="${E}1;38;5;"
		C="57 77 69 124"

	else
		B="${E}4"
		F="${E}1;3"
		C="4 6 5 2"
	fi

	[[ $# -eq 4 ]] && C="$@"
	for (( c=1; c<5; c++ )); do
		BG[$c]="${B}${i}m"
		FG[$c]="${F}${i}m"
	done
	for (( i=0; i<8; i++ )); do
		FB[${SGR07[$i]}]="\e[${i}m"
	done

	# Check PWD length
	local PROMPT LENGTH NPWD=${PWD/HOME/\~} TTY=$(tty | cut -b6-)
	PROMPT="---($USER$(uname -n):${TTY}---()---"
	if [[ $COLUMNS -lt $((${#PROMPT}+${#NPWD}+13)) ]]; then
		LENGTH=$((${COLUMNS}-${#PROMPT}-16))
		NPWD=...${NPWD:COLUMNS-LENGTH:LENGTH}
	fi

	# And the prompt
	case $TERM in
	*xterm*|*rxvt*)
		PS1="${FG[2]}┌${FB[bold]}$FG[1]}(${FG[4]}\$${FG[1]}${FG[4]}\h:$TTY\
		${FG[1]}⋅\D{%m/%d}⋅${FG[4]}\t${FG[4]})${FB[bold]}${FG[1]}\
		(${FG[4]}$NPWD${FG[1]})${FB[bold]}${FG[1]}
		\n${FG[2]}${FB[bold]}${FG[1]}${FG[3]}${FB[reset]}-» "
		PS2="${FG[1]}-» ${FB[reset]}"
		TITLEBAR="\$:${NPWD}"
	;;
	*)
		PS1="${FG[1]}(${FG[4]}\$${FG[1]}\D{%m/%d}${FG[4]}\h:$TTY:$NPWD\
		${FG[1]}${FG[4]}${FG[1]})${FB[reset]} "
		PS2="${FG[1]}-» ${FB[reset]}"
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
		echo -en "$o$m$c ${d:+:$d}"
		echo
		pushd $md >$n 2>&1
		for mc in *
		do
			de=$(modinfo -p $m 2>$n | grep ^$mc 2>$n | sed "s/^$mc=//" 2>$n)
			echo -en "\t$mc=$(cat $mc 2>$n) ${de:+ -$de}"
			echo
		done
		popd >$n 2>&1
	done
}


# @FUNCTION: kmp-cc
# @DESCRIPTION: colorful helper to retrieve Kernel Module Parameters
function kmp-cc ()
{
	local green yellow cyan reset
	if tty -s <&1
	then
		green="\e[1;32m"
		yellow="\e[1;33m"
		cyan="\e[1;36m"
		reset="\e[0m"
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
			printf "\t$cyan%s$reset = $yellow%s$reset\n%s\n" \
			${pnames[i]} \
			"${pvals[i]}" \
			"${pdescs[i]}"
		done
		echo
	done
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
