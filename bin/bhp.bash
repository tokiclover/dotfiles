#!/bin/bash
#
# $Header: $HOME/bin/browser-home-profile.bash          Exp $
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 1.0 2015/08/24                              Exp $
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

function bhp-help {
	cat <<-EOH
usage: bhp [OPTIONS] [Browser-Home-Profile]
  -b, --browser=Web-Browser   Select a browser to set up
  -c, --compressor='lzop -1'  Use lzop compressor, default to lz4
  -t, --tmpdir=DIR            Set up a particular TMPDIR
  -p, --profile=PROFILE       Select a particular profile
  -h, --help                  Print help message and exit
EOH
}

#
# Use a private initializer function
#
function bhp-init {
	local ARGS DIR PROFILE browser char dir ext name="${bhp[zero]}" profile tmpdir

	ARGS=($(getopt \
		-o b:c:hp:t: -l browser:,compressor:,help,profile:,tmpdir: \
		-n ${bhp[zero]} -s sh -- "${@}"))
	if (( ${?} != 0 )); then
		return 111
	fi
	eval set -- "${ARGS[@]}"

	while true; do
		case "${1}" in
			(-b|--browser) browser="${2}";;
			(-c|--compressor) compressor="${2}";;
			(-p|--profile) bhp[profile]="${2}";;
			(-h|--help) bhp-help; return 128;;
			(-t|--tmpdir) tmpdir="${2}";;
			(*) shift; break;;
		esac
	done

	#
	# Set up web-browser if any
	#
	function bhp-browser {
		local BROWSERS MOZ_BROWSERS set brs dir
		MOZ_BROWSERS='aurora firefox icecat seamonkey'
		BROWSERS='conkeror chrom epiphany midory opera otter netsurf qupzilla vivaldi'

		case "${1}" in
			(*aurora|firefox*|icecat|seamonkey)
				BROWSER="${1}" PROFILE="mozilla/${1}"; return;;
			(conkeror*|*chrom*|epiphany|midory|opera*|otter*|netsurf*|qupzilla|vivaldi*)
				BROWSER="${1}" PROFILE="config/${1}" ; return;;
		esac

		for set in "mozilla:${MOZ_BROWSERS}" "config:${BROWSERS}"; do
			for brs in ${set#*:}; do
				set="${set%:*}"
				for dir in "${HOME}"/.${set}/*${brs}*; do
					if [[ -d "${dir}" ]]; then
						BROWSER="${brs}" PROFILE="${set}/${brs}"
						return
					fi
				done
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

:	${compressor:=lz4 -1 -}
:	${profile:=${PROFILE##*/}}
:	${bhp[compressor]:=${compressor}}
:	${bhp[profile]:=${profile}}
:	${bhp[PROFILE]:=${PROFILE}}
:	${tmpdir:=${TMPDIR:-/tmp/$USER}}
:	${ext=.tar.${compressor%% *}}

	[[ -d "${tmpdir}" ]] || mkdir -p -m 1700 "${tmpdir}" ||
		{ pr-error "No suitable directory found"; return 114; }

	for dir in "${HOME}"/.${PROFILE} "${HOME}"/.cache/${PROFILE#config/}; do
		[[ -d "${dir}" ]] || continue
		grep -q "${dir}" /proc/mounts && continue
		pr-begin "Setting up directory...\n"

		pushd "${dir%/*}" >${NULL} 2>&1 || continue
		if [[ ! -f ${profile}${ext} ]] || [[ ! -f ${profile}.old${ext} ]]; then
			tar -Ocp ${profile} | ${compressor} ${profile}${ext} ||
				{ pr-error "Failed to pack a tarball"; continue; }
		fi
		popd >${NULL} 2>&1

		case "${dir}" in
			(*.cache/*) char=c;;
			(*) char=p;;
		esac
		DIR="$(mktmp -p "${tmpdir}"  -d bh${char}-XXXXXX)"
		sudo mount --bind "${DIR}" "${dir}" || pr-error "Failed to mount ${DIR}"
		pr-end "${?}"
	done
}
bhp-init "${@}"
BHP_RET="${?}"

function bhp {
	local ext=.tar.${bhp[compressor]%% *} name=bhp tarball

	for dir in "${HOME}"/.{${bhp[PROFILE]},cache/${bhp[PROFILE]#config/}}; do
		pushd "${dir%/*}" >${NULL} 2>&1 || continue

		pr-begin "Setting up tarball...\n"
		if [[ -f ${bhp[profile]}/.unpacked ]]; then
			if [[ -f ${bhp[profile]}${ext} ]]; then
				mv -f ${bhp[profile]}{,.old}${ext} ||
					{ pr-error "Failed to override the old tarball"; continue; }
			fi
			tar -X ${bhp[profile]}/.unpacked -Ocp ${bhp[profile]} | \
				${bhp[compressor]} ${bhp[profile]}${ext} ||
				{ pr-error "Failed to repack a new tarball"; continue; }
		else
			if [[ -f ${bhp[profile]}${ext} ]]; then
				tarball=${bhp[profile]}${ext}
			elif [[ -f ${bhp[profile]}.old${ext} ]]; then
				tarball=${bhp[profile]}.old${ext} 
			else
				pr-warn "No tarball found"
			fi
			${bhp[compressor]%% *} -cd ${tarball} | tar -xp &&
				touch ${bhp[profile]}/.unpacked ||
				pr-error "Failed to unpack the tarball"
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
