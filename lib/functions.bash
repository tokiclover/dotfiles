#
# $Header: functions.bash, 2014/09/28 12:59:26 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
#

# @FUNCTION: error
# @DESCRIPTION: hlper function, print error message to stdout
# @USAGE: <string>
function error {
	echo -e "\e[1;31m* \e[0m${0##*/}: $@" >&2

	[[ "$LOGGER" ]] && [[ "$facility" ]] && logger -p $facility "${0##*/}: $@"
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die {
	local ret=$?
	error "$@"
	return $ret
}

# @FUNCTION: into
# @DESCRIPTION: hlper function, print info message to stdout
# @USAGE: <string>
function info {
	echo -e "\e[1;32m \e[0m${0##*/}: $@"

	[[ "$LOGGER" ]] && [[ "$facility" ]] && logger -p $facility "${0##*/}: $@"
}

# @FUNCTION: mktmp
# @DESCRIPTION: make tmp dir or file in ${TMPDIR:-/tmp}
# @ARG: [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
function mktmp {
	function usage {
	cat <<-EOH
usage: mktmp [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
  -d, --dir           create a directory
  -f, --file          create a file
  -o, --owner <name>  owner naame
  -g, --group <name>  group name
  -m, --mode <1700>   octal mode
  -h, --help          help/exit
EOH
return
}
	
	(( $# == 0 )) && usage
	test $# -ge 1 -a -n "$1"
	if (( $? )); then
		die "invalid/null TEMPLATE"
		return
	fi
	
	local type mode owner group tmp tmpdir=${TMPDIR:-/tmp}
	while [[ $# -gt 1 ]]; do
		case $1 in
			(-d|--dir)
				type=dir
				shift;;
			(-f|--file)
				type=file
				shift;;
			(-h|--help)
				usage;;
			(-m|--mode)
				mode=$2
				shift 2;;
			(-o|--owner)
				owner="$2"
				shift 2;;
			(-g|-group)
				group="$2"
				shift 2;;
		 	(*)
		 		die
		 		shift;;
		esac
	done

	local temp=-XXXXXX
	test -n "$1" -a "${1%$temp}" != "$1"
	if (( $? )); then
		die "invalid/null TEMPLATE"
		return
	fi
	local cmd=$(type -p uuidgen)
	[[ -n "$cmd" ]] && temp=$($cmd --random)
	tmp=$tmpdir/${1%$temp}-$(echo "$temp" | cut -c-6)

	if [[ "$type" == "dir" ]]; then
		mkdir -p ${mode:+-m$mode} "$tmp"
		if (( $? )); then
			die "mktmp: failed to make $tmp"
		fi
	else
		mkdir -p "${tmp%/*}" && touch "$tmp"
		if (( $? )); then
			die "mktmp: failed to make $tmp"
			return
		fi
		[[ "$mode" ]] && chmod $mode "$tmp"
	fi
	[[ "$owner" ]] && chown "$owner" "$tmp"
	[[ "$group" ]] && chgrp "$group" "$tmp"
	echo "$tmp"
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
function bash_prompt {
	# Initialize colors arrays
	declare -A BG FG FB
	local B C E="\e[" F
	if (( $(tput colors) >= 256 )); then
		B="${E}48;5;"
		F="${E}1;38;5;"
		C="57 77 69 124"
	else
		B="${E}4"
		F="${E}1;3"
		C="4 6 5 2"
	fi

	(( $# >= 4 )) && C="$@"
	for (( c=1; c<5; c++ )); do
		BG[$c]="${B}${i}m"
		FG[$c]="${F}${i}m"
	done
	for (( i=0; i<8; i++ )); do
		FB[${SGR07[$i]}]="\e[${i}m"
	done

	# Check PWD length
	local PROMPT LENGTH TTY=$(tty | cut -b6-)
	PROMPT="---($USER$(uname -n):${TTY}---()---"
	if (( ${COLUMNS:-0} <= (${#PROMPT}+${#NPWD}+13) )); then
		PROMPT_DIRTRIM=$((${COLUMNS}-${#PROMPT}-16))
	fi

	# And the prompt
	case $TERM in
	(*xterm*|*rxvt*|linux|*term*)
		PS1="${FB[bold]}${FG[2]}-${FG[1]}(${FG[4]}\$·${FG[1]}${FG[4]}\h:$TTY${FG[1]}·\D{%m/%d}·${FG[4]}\t${FG[4]})${FG[1]}\
		(${FG[4]}\w${FG[1]})${FB[bold]}${FG[1]}${FG[2]}${FB[bold]}${FG[1]}${FG[3]}${FB[reset]}-» "

		PS2="${FG[1]}-» ${FB[reset]}"
		TITLEBAR="\$:\w"
	;;
	(*)
		PS1="${FG[1]}(${FG[4]}\$·${FG[1]}\D{%m/%d}${FG[4]}\h:$TTY:\w${FG[1]}${FG[4]}${FG[1]})${FB[reset]} "
	
		PS2="${FG[1]}-» ${FB[reset]}"
	;;
	esac
}
# @ENV_VARIABLE: PROMPT_COMMAND
# @DESCRIPTION: bash prompt command
PROMPT_COMMAND=bash_prompt

# @FUNCTION: kmod-pa
# @DESCRIPTION: little helpter to retrieve Kernel Module Parameters
function kmod-pa {
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


# @FUNCTION: kmod-pc
# @DESCRIPTION: colorful helper to retrieve Kernel Module Parameters
function kmod-pc {
	local green yellow cyan reset
	if [[ "$(tput colors)" -ge 8 ]]
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

# @FUNCTION: genpwd
# @DESCRIPTION: generate a random password using openssl to stdout
function genpwd {
	openssl rand -base64 48
}

# @FUNCTION: xev-key-code
# @DESCRIPTION: simple xev key code
function xev-key-code {
	xev | grep -A2 --line-buffered '^KeyRelease' | \
	sed -nre '/keycode /s/^.*keycode ([0-9]*).* (.*, (.*)).*$/\1 \2/p'
}

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
