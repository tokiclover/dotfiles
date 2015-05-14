#
# $Header:  ${HOME}/lib//functions.zsh                   Exp $
# $Author: (c) 2015 -tclover <tokiclover@gmail.com>      Exp $
# $License: 2-clause/new/simplified BSD                  Exp $
# $Version: 1.2 2015/05/14 21:09:26                      Exp $
#

#
# @FUNCTION: Print error message to stderr
#
pr-error()
{
	local PFX=${name:+" %F{magenta}${name}:"}
	print -P${PR_EOL:+n} "${PR_EOL:+\n} %B%F{red}*${PFX}%b%f ${@}" >&2
}

#
# @FUNCTION: Print info message to stdout
#
pr-info()
{
	local PFX=${name:+" %F{yellow}${name}:"}
	print -P${PR_EOL:+n} "${PR_EOL:+\n} %B%F{blue}*${PFX}%b%f ${@}"
}

#
# @FUNCTION: Print warn message to stdout
#
pr-warn()
{
	local PFX=${name:+" %F{red}${name}:"}
	print -P${PR_EOL:+n} "${PR_EOL:+\n} %B%F{yellow}*${CLR_RST}${PFX}%f%b ${@}"
}

#
# @FUNCTION: Print begin message to stdout
#
pr-begin()
{
	case ${PR_EOL} {
		(0) echo;;
	}
:	${PR_EOL=0}
	local PFX=${name:+"%B%F{magenta}[%f %F{blue}${name}%f: %F{magenta}]%f%b"}
	print -P " ${PFX} ${@}"
}

#
# @FUNCTION: Print end message to stdout
#
pr-end()
{
	local SFX
	case ${1:-0} {
		(0) SFX="%F{blue}[%f %F{green}Ok%f %F{blue}]%f";;
		(*) SFX="%F{yellow}[%f %F{red}No%f %F{yellow}]%f";;
	}
	shift
	print -P " ${@} %B${SFX}%b"
	PR_EOL=
}

#
# @FUNCTION: YES or NO helper
#
yesno()
{
	case ${1:-NO} in
	(0|[Dd][Ii][Ss][Aa][Bb][Ll][Ee]|[Oo][Ff][Ff]|[Ff][Aa][Ll][Ss][Ee]|[Nn][Oo])
		return 1;;
	(1|[Ee][Nn][Aa][Bb][Ll][Ee]|[Oo][Nn]|[Tt][Rr][Uu][Ee]|[Yy][Ee][Ss])
		return 0;;
	(*)
		return 2;;
	esac
}

#
# Set up (terminal) colors
#
if [ -t 1 ] && yesno ${COLOR:-Yes}; then
	autoload colors zsh/terminfo
	if (( ${terminfo[colors]} >= 8 )) { colors }
fi


#
# @FUNCTION: source wrapper
# @ARG: [OPT] FILE
#
SOURCE()
{
	local arg msg opt ret
	msg='Failed to source ${arg}'
	while (( ${#} >= 1 )) {
		case ${1} {
			(-[ed]) opt=${1};;
			(*) break;;
		}
		shift
	}

	for arg; do
	[[ -e ${1} ]] && source ${1}
	case ${?} {
		(0)
			;;
		(*)
			ret=$((${ret} + ${?}))
			case ${opt} {
				(-e) eval pr_error ${msg};;
				(-d) eval    die   ${msg};;
			}
			;;
	}
	shift
	done
	return ${ret}
}

#
# @FUNCTION: Mount/fstab info helper
# @ARG: [-f] DIR
#
mount-info()
{
	local DIR DST SRC args d opts ret

	SRC=/proc/mounts
	args=($(getopt -o F:f -l fstab,fsys: -n mount_info -s sh -- "${@}"))
	eval set -- "${args[@]}"

	while true; do
	case ${1} {
		(-f|--fstab) SRC=/etc/fstab;;
		(-F|--fsys*) FS=${2}; shift;;
		(*) shift; break;;
	}
	shift
	done
	DIR=${1}
	DST=($(sed -nre "s|(^[^#].*${1}[[:space:]].*${FS})[[:space:]].*$|\1|p" ${SRC}))

	for d (${DST})
		case ${DIR} {
			(${d}) ret=0; break;;
		}
	return ${ret:-1}
}

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
