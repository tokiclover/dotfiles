#
# $Header:  ${HOME}/lib//functions.zsh                   Exp $
# $Author: (c) 2015-6 -tclover <tokiclover@gmail.com>    Exp $
# $License: 2-clause/new/simplified BSD                  Exp $
# $Version: 1.3 2016/03/08 21:09:26                      Exp $
#

#
# Setup a few environment variables for pr-*() helper family
#
typeset -A print_info
print_info[cols]="${COLUMNS:=$(tput cols)}"
# the following should be set before calling pr-end()
#print_info[len]=${print_info[len]}
# and this keep updating print_info[cols]
trap 'print_info[cols]=${COLUMNS:=$(tput cols)}' WINCH

#
# @FUNCTION: Print error message to stderr
#
pr-error()
{
	local PFX=${name:+%F{magenta}${name}:}
	print -P${print_info[eol]:+n} "${print_info[eol]}%B%F{red}ERROR:${PFX}%b%f ${@}" >&2
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
	local PFX=${name:+%F{yellow}${name}:}
	print -P${print_info[eol]:+n} "${print_info[eol]}%B%F{blue}INFO:${PFX}%b%f ${@}"
}

#
# @FUNCTION: Print warn message to stdout
#
pr-warn()
{
	local PFX=${name:+%F{red}${name}:}
	print -P${print_info[eol]:+n} "${print_info[eol]}%B%F{yellow}WARN:${CLR_RST}${PFX}%f%b ${@}"
}

#
# @FUNCTION: Print begin message to stdout
#
pr-begin()
{
	print -Pn "${print_info[eol]}"
	print_info[eol]="\n"
	print_info[len]=$((${#name}+${#*}))
	local PFX=${name:+%B%F{magenta}[%f%F{blue}${name}%f%F{magenta}]%f%b}
	print -Pn "${PFX} ${@}"
}

#
# @FUNCTION: Print end message to stdout
#
pr-end()
{
	local SFX
	case ${1:-0} {
		(0) SFX="%F{blue}[%f%F{green}Ok%f%F{blue}]%f";;
		(*) SFX="%F{yellow}[%f%F{red}No%f%F{yellow}]%f";;
	}
	shift
	print_info[len]=$((${print_info[cols]}-${print_info[len]}))
	printf "%*b" ${print_info[len]} $(print -P "${@} %B${SFX}%b")
	print
	print_info[eol]= print_info[len]=0
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
if [ -t 1 ] && yesno ${PRINT_COLOR:-Yes}; then
	autoload colors zsh/terminfo
	if (( ${terminfo[colors]} >= 8 )) { colors }
fi


#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
