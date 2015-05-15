#
# $Header:  ${HOME}/lib/functions.bash                   Exp $
# $Author: (c) 2015 -tclover <tokiclover@gmail.com>      Exp $
# $License: 2-clause/new/simplified BSD                  Exp $
# $Version: 1.2 2015/05/14 21:09:26                      Exp $
#

#
# @FUNCTION: Print error message to stderr
#
pr-error()
{
	local PFX=${name:+" ${fg[5]}${name}:${color[none]}"}
	echo -e${PR_EOL+n} "${PR_EOL+\n} ${color[bold]}${fg[1]}*${color[none]}${PFX} ${@}" >&2
}

#
# @FUNCTION: Print error message to stderr & exit
#
die()
{
	local ret=${?}; pr-error "${@}"; return ${ret}
}

#
# @FUNCTION: Print info message to stdout
#
pr-info()
{
	local PFX=${name:+" ${fg[3]}${name}:${color[none]}"}
	echo -e${PR_EOL+n} "${PR_EOL+\n} ${color[bold]}${fg[4]}*${color[none]}${PFX} ${@}"
}

#
# @FUNCTION: Print warn message to stdout
#
pr-warn()
{
	local PFX=${name:+" ${fg[1]}${name}:${color[none]}"}
	echo -e${PR_EOL+n} "${PR_EOL+\n} ${color[bold]}${fg[3]}*${color[none]}${PFX} ${@}"
}

#
# @FUNCTION: Print begin message to stdout
#
pr-begin()
{
	[[ "${PR_EOL}" ]] && echo
:	${PR_EOL=0}
	local PFX=${name:+"${fg[5]}[${color[none]} ${fg[4]}${name}${color[none]}: ${fg[5]}]${color[none]}"}
	echo -en " ${color[bold]}${PFX} ${@}"
}

#
# @FUNCTION: Print end message to stdout
#
pr-end()
{
	local SFX
	case "${1:-0}" in
		(0) SFX="${fg[4]}[${color[none]} ${fg[2]}Ok${color[none]} ${fg[4]}]${color[none]}";;
		(*) SFX="${fg[3]}[${color[none]} ${fg[1]}No${color[none]} ${fg[3]}]${color[none]}";;
	esac
	shift
	echo -en " ${@} ${color[bold]}${SFX}\n"
	PR_EOL=
}

#
# @FUNCTION: YES or NO helper
#
yesno()
{
	case "${1:-NO}" in
	(0|[Dd][Ii][Ss][Aa][Bb][Ll][Ee]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee]|[Nn][Oo])
		return 1;;
	(1|[Ee][Nn][Aa][Bb][Ll][Ee]|[Oo][Nn]|[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss])
		return 0;;
	(*)
		return 2;;
	esac
}

#
# @FUNCTION: Colors handler
#
eval_colors()
{
	local -a C=(black red green yellow blue magenta cyan white)

	local B E='\e[' F N c
	if (( $(tput colors) >= 256 )); then
		B='48;5;' F='38;5;' N=256
	else
		B=4 F=3 C=8
	fi
	for (( c=0; c<${N}; c++ )); do
		bg[${c}]="${E}${B}${c}m"
		fg[${c}]="${E}${F}${c}m"
	done
	for (( c=0; c<=${#C[@]}; c++ )); do
		color[bg-${C[${c}]}]="${E}${B}${c}m"
		color[fg-${C[${c}]}]="${E}${F}${c}m"
	done
	for c in 0:none 1:bold 2:faint 3:italic 4:underline 5:blink \
		6:rapid-blink 7:inverse 8:conceal 23:no-italic 24:no-underline \
		25:no-blink 28:reveal 39;49:default; do
		color[${c#*:}]="${E}${c%:*}m"
	done
}

if [ -t 1 ] && yesno "${COLOR:-Yes}"; then
	typeset -a bg fg; typeset -A color
	eval_colors
fi

#
# @FUNCTION: Mount/fstab info helper
# @ARG: [-f] DIR
#
mount_info()
{
	local DIR DST SRC args d opts ret

	SRC=/proc/mounts
	args=($(getopt -o F:f -l fstab,fsys: -n mount_info -s sh -- "${@}"))
	eval set -- "${args[@]}"

	while true; do
	case "${1}" in
		(-f|--fstab) SRC=/etc/fstab;;
		(-F|--fsys*) FS=${2}; shift;;
		(*) shift; break;;
	esac
	shift
	done
	DIR="${1}"
	DST=($(sed -nre "s|(^[^#].*${1}[[:space:]].*${FS})[[:space:]].*$|\1|p" ${SRC}))

	for d in "${DST[@]}"; do
		case "${DIR}" in
			("${d}") ret=0; break;;
		esac
	done
	return "${ret:-1}"
}

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
