#!/bin/bash
#
# $Header: $HOME/bin/browser-home-profile.bash          Exp $
# $Author: (c) 2012-16 -tclover <tokiclover@gmail.com>  Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 1.3 2016/03/30                              Exp $
#
# @DESCRIPTION: Set up and maintain browser home profile directory
#   and cache directory in a tmpfs (or zram backed filesystem.)
#   See https://github.com/tokiclover/browser-home-profile
#   for a POSIX sh variant; or else, my prezto module of it.
#
# And maybe something like: */30 * * * * $USER $HOME/bin/bhp.bash in
# cron job to keep track of changes is necessary; or else, use atd.
#
# @ENVIRONMENT: TMPDIR:=/tmp/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram backed filesystem
#   WARN: Use something like the following in fstab(5) to set up a tmpfs
#			tmp /tmp tmpfs nodev,exec,mode=1777,size=256M 0 0
#		Or else, use -t|--tmpdir command line switch to specify a specific
#		temprary directory.
#
# @ENVIRONMENT: BROWSER=firefox
# @DESCRIPTION: Set up a default web-browser to pick up when used without
#   an argument (with/out -b|--browser switch.)
#
# @REQUIREMENTS: sed, tar and a compressor (default to lz4.)
#

shopt -qs extglob
shopt -qs nullglob
typeset -A bhp
NULL=/dev/null
case "${0##*/}" in
	(bhp*|browser-home-profile*) bhp[zero]="${0##*/}";;
	(*) bhp[zero]=bhp;;
esac

if [[ -f "${0%/*}"/../lib/functions.bash ]]; then
	source "${0%/*}"/../lib/functions.bash
else
	function pr-error {
		echo -e " \e[1;31m* \e[0m${0##*/}: $@" >&2
	}
fi

#
# Use a private initializer function
#
function bhp-init {
	function bhp-help {
	cat <<-EOH
usage: bhp [OPTIONS] [Browser-Home-Profile]
  -b, --browser=Web-Browser   Select a browser to set up
  -c, --compressor='lzop -1'  Use lzop compressor, default to lz4
  -t, --tmpdir=DIR            Set up a particular TMPDIR
  -p, --profile=PROFILE       Select a particular profile
  -s, --set                   Set up tarball archives
  -h, --help                  Print help message and exit
EOH
	}

	local ARGS DIR PROFILE browser char dir ext name="${bhp[zero]}" profile tmpdir
	local set_tarball=false

	ARGS=($(getopt \
		-o b:c:hp:st: -l browser:,compressor:,help,profile:,set,tmpdir: \
		-n ${bhp[zero]} -s sh -- "${@}"))
	if (( ${?} != 0 )); then
		return 111
	fi
	eval set -- "${ARGS[@]}"

	while true; do
		case "${1}" in
			(-b|--browser) browser="${2}"     ;;
			(-c|--compressor) compressor="${2}"; shift;;
			(-p|--profile) bhp[profile]="${2}" ; shift;;
			(-t|--tmpdir) tmpdir="${2}"        ; shift;;
			(-s|--set)  set_tarball=true      ;;
			(-h|--help) bhp-help; return 128  ;;
			(*) shift; breaki                 ;;
		esac
		shift
	done

	#
	# Set up web-browser if any
	#
	function bhp-browser {
		local browser group
		local -A BROWSERS
		BROWSERS[mozilla]='aurora firefox icecat seamonkey'
		BROWSERS[config]='conkeror chrome chromium epiphany midory opera otter netsurf qupzilla vivaldi'

	if [[ "${1}" ]]; then
		if [[ "${BROWSERS[mozilla]}" == *${1}* ]]; then
				BROWSER="${1}" PROFILE="mozilla/${1}"; return;
		elif [[ "${BROWSERS[config]}" == *${1}* ]]; then
				BROWSER="${1}" PROFILE="config/${1}" ; return;
		fi
	fi

		for key in "${!BROWSERS[@]}"; do
			for browser in ${BROWSERS[${key}]}; do
				if [[ -d "${HOME}/.${key}/${browser}" ]]; then
					BROWSER="${browser}" PROFILE="${key}/${browser}"
					return
				fi
			done
		done
		return 111
	}
	bhp-browser "${browser:-${BROWSER:-$1}}"

	if (( ${?} != 0 )); then
		pr-error "No web-browser found."
		return 112
	fi

	#
	# Handle (Mozilla) specific profiles
	#
	case "${PROFILE}" in
		(mozilla*)
		function bhp-profile {
			if [[ -n "${1}" ]] && [[ -d "${HOME}/.${PROFILE}/${1}" ]]; then
				PROFILE="${PROFILE}/${1}"
				return
			fi
			PROFILE="${PROFILE}/$(sed -nre "s|^[Pp]ath=(.*$)|\1|p" \
				"${HOME}"/.${PROFILE}/profiles.ini)"
			[[ -n "${PROFILE}" ]] && [[ -d "${HOME}/.${PROFILE}" ]]
		}
		bhp-profile "${bhp[profile]}"

		if (( ${?} != 0 )); then
			pr-error "No firefox profile directory found"
			return 113
		fi
		;;
	esac

:	${compressor:=lz4 -1}
:	${profile:=${PROFILE##*/}}
:	${bhp[compressor]:=${compressor}}
:	${bhp[profile]:=${profile}}
:	${bhp[PROFILE]:=${PROFILE}}
:	${tmpdir:=${TMPDIR:-/tmp/$USER}}
:	${ext:=.tar.${compressor%% *}}

	[[ -d "${tmpdir}" ]] || mkdir -p -m 1700 "${tmpdir}" ||
		{ pr-error "No suitable directory found"; return 114; }

	for dir in "${HOME}"/.${PROFILE} "${HOME}"/.cache/${PROFILE#config/}; do
		[[ -d "${dir}" ]] || continue
		if grep -qw "${dir}" /proc/mounts; then
			${set_tarball} && bhp "${dir}"
			continue
		fi
		pr-begin "Setting up directory..."

		pushd "${dir%/*}" >${NULL} 2>&1 || continue
		if [[ ! -f ${profile}${ext} ]] || [[ ! -f ${profile}.old${ext} ]]; then
			tar -cpf ${profile}${ext}  -I "${compressor}" ${profile} ||
				{ pr-end 1 "Tarball"; continue; }
		fi

		case "${dir}" in
			(*.cache/*) char=c;;
			(*) char=p;;
		esac
		DIR="$(mktemp -p "${tmpdir}"  -d bh${char}-XXXXXX)"
		sudo mount --bind "${DIR}" "${dir}" || pr-error "Failed to mount ${DIR}"
		pr-end "${?}"

		if ${set_tarball}; then
			bhp "${dir}"
		fi
		popd >${NULL} 2>&1
	done
}
bhp-init "${@}"
BHP_RET="${?}"

function bhp {
	local ext=.tar.${bhp[compressor]%% *} name=bhp tarball

	for dir in ${@:-"${HOME}"/.{${bhp[PROFILE]},cache/${bhp[PROFILE]#config/}}}; do
		[[ -d "${dir}" ]] || continue
		pushd "${dir%/*}" >${NULL} 2>&1 || continue

		pr-begin "Setting up tarball..."
		if [[ -f ${bhp[profile]}/.unpacked ]]; then
			if [[ -f ${bhp[profile]}${ext} ]]; then
				mv -f ${bhp[profile]}{,.old}${ext} ||
					{ pr-end 2 "Moving"; continue; }
			fi
			tar -X ${bhp[profile]}/.unpacked -cpf ${bhp[profile]}${ext} \
				-I "${bhp[compressor]}" ${bhp[profile]} ||
				{ pr-error 3 "Packing"; continue; }
		else
			if [[ -f ${bhp[profile]}${ext} ]]; then
				tarball=${bhp[profile]}${ext}
			elif [[ -f ${bhp[profile]}.old${ext} ]]; then
				tarball=${bhp[profile]}.old${ext} 
			else
				pr-warn "No tarball found"
				continue
			fi
			 tar -xpf ${tarball} -I "${bhp[compressor]}" &&
				touch ${bhp[profile]}/.unpacked ||
				pr-end 5 "Unpacking"
		fi
		pr-end "${?}"
		popd >${NULL} 2>&1
	done
}

case "${0##*/}" in
	(bhp*) (( ${BHP_RET} == 0 )) && bhp;;
esac

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
