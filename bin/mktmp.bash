#
# $Header: $HOME/bin/mktmp.bash                         Exp $
# $Aythor: (c) 2012-015 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 0.7 2015/05/15 21:09:26                     Exp $
#

if [[ -f "${0%bin/*}"lib/functions.bash ]]; then
	source "${0%bin/*}"lib/functions.zsh
else
	function pr-error {
		echo -e " \e[1;31m* \e[0m${0##*/}: $@" >&2
	}
fi

function mktmp {
	function usage {
	cat <<-EOH
usage: mktmp [-p] [-d|-f] [-m mode] [-o owner[:group]] TEMPLATE-XXXXXX
  -d, --dir           (Create a) directory
  -f, --file          (Create a) file
  -o, --owner <name>  Use owner name
  -g, --group <name>  Use group name
  -m, --mode <1700>   Use octal mode
  -p, --tmpdir[=DIR]  Use temp-dir
  -h, --help          Help/Exit
EOH
return
}
	(( $# == 0 )) && { usage; return 1; }

	local args group mode owner temp=-XXXXXX tmp type
	args=($(getopt \
		-o cdfg:hm:o:p: \
		-l dir,file,group:,tmpdir:,help,mode:owner: \
		-s sh -n mktmp -- "${@}"))
	(( ${?} == 0 )) || { usage; return 2; }
	eval set -- "${args[@]}"
	args=

	while true; do
		case "${1}" in
			(-p|--tmpd*) tmpdir="${2:-${TMPDIR:-/tmp}}"; shift;;
			(-d|--dir) args=-d type=dir;;
			(-f|--file)  type=file    ;;
			(-h|--help) usage; return;;
			(-m|--mode)  mode="$2" ; shift;;
			(-o|--owner) owner="$2"; shift;;
			(-g|-group)  group="$2"; shift;;
			(*) shift; break      ;;
		esac
		shift
	done

	if ! ([[ ${#} == 1 ]] && [[ -n "${1}" ]]); then
		pr-error "Invalid argument(s)"
		return 3
	fi
	case "${1}" in
		(*${temp}) ;;
		(*) pr-error "Invalid TEMPLATE"; return 4;;
	esac

	if type -p mktemp >/dev/null 2>&1; then
		tmp="$(mktemp ${tmpdir:+-p} "${tmpdir}" ${args} "${1}")"
	else
		type -p uuidgen >/dev/null 2>&1 && temp=$(uuidgen --random)
		tmp="${tmpdir}/${1%-*}-${temp:0:5}"
	fi

	case "${type}" in
		(dir)
		[[ -d "${tmp}" ]] || mkdir -p "${tmp}"
		;;
		(*)
		[[ -e "${tmp}" ]] || { mkdir -p "${tmp%/*}"; touch  "${tmp}"; }
		fi
		;;
	esac
	((  $? == 0 )) || { pr-error "Failed to create ${tmp}"; return 5; }

	[[ -h "${tmp}" ]] && return
	[[ "${owner}" ]] && chown "${owner}" "${tmp}"
	[[ "${group}" ]] && chgrp "${group}" "${tmp}"
	[[ "${mode}"  ]] && chmod "${mode}"  "${tmp}"
	echo "${tmp}"
}

case "${0##*/}" in
	(mktmp*) mktmp "${@}";;
esac

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
