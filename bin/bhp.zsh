#!/bin/zsh
#
# $Header: $HOME/bin/browser-home-profile.zsh           Exp $
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 1.0 2015/05/14                              Exp $
#
# @DESCRIPTION: Set up and maintain browser home profile directory
#   and cache directory in a tmpfs (or zram backed filesystem.)
#   See https://github.com/tokiclover/browser-home-profile
#   for a POSIX sh variant; or else, my prezto module of it.
#
# And maybe something like: */30 * * * * $USER $HOME/bin/bhp.zsh in
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

typeset -A bhp
NULL=/dev/null
case ${0:t} in
	(bhp*|browser-home-profile*) bhp[zero]=${0:t};;
	(*) bhp[zero]=bhp;;
esac

if [[ -f ${0:h}/../lib/functions.zsh ]] {
	source ${0:h}/../lib/functions.zsh
} else {
	function pr-error {
		print -P " %F{red}*%f %1x: %F{yellow}%U%I%u:%f $@" >&2
	}
}
autoload -Uz mktmp

function bhp-help {
	cat <<-EOH
usage: ${bhp[zero]} [OPTIONS] [BROWSER]
  -b, --browser=Web-Browser   Select a browser to set up
  -c, --compressor='lzop -1'  Use lzop compressor, default to lz4
  -t, --tmpdir=DIR            Set up a particular TMPDIR
  -p, --profile=PROFILE       Select a particular profile
  -h, --help                  Print help message and exit
EOH
}

#
# Use an anonymous function to initialize
#
function {
	local ARGS DIR PROFILE browser char dir ext name=${bhp[zero]} profile tmpdir
	ARGS=($(getopt \
		-o b:c:hp:t: -l browser:,compressor:,help,profile:,tmpdir: \
		-n ${bhp[zero]} -s sh -- "${@}"))
	if (( ${?} != 0 )) {
		return 111
	}
	eval set -- "${ARGS[@]}"

	while true; do
	case ${1} {
			(-h|--help) bhp-help; return 128;;
			(-c|--compressor) compressor=${2};;
			(-b|--browser) browser=${2};;
			(-p|--profile) PROFILE=${2};;
			(-t|--tmpdir) tmpdir=${2};;
			(-z|--zsh-exit-hook)
				autoload -Uz add-zsh-hook
				add-zsh-hook zshexit bhp;;
			(*) shift; bhp[profile]=${1}; break;;
		}
	done
	setopt LOCAL_OPTIONS EXTENDED_GLOB

	#
	# Set up web-browser if any
	#
	function {
		local BROWSERS MOZ_BROWSERS set brs dir
		MOZ_BROWSERS='aurora firefox icecat seamonkey'
		BROWSERS='conkeror chrom epiphany midory opera otter qupzilla vivaldi'

		case ${1} {
			(*aurora|firefox*|icecat|seamonkey)
				BROWSER=${1} PROFILE=mozilla/${1}; return;;
			(conkeror*|*chrom*|epiphany|midory|opera*|otter*|qupzilla|vivaldi*)
				BROWSER=${1} PROFILE=config/${1} ; return;;
		}

		for set ("mozilla:${MOZ_BROWSERS}" "config:${BROWSERS}")
			for brs (${=set#*:}) {
				set=${set%:*}
				for dir (${HOME}/.${set}/*${brs}*(N/))
					if [[ -d ${dir} ]] {
						BROWSER=${brs} PROFILE=${set}/${brs}
						return
					}
			}
		return 111
	} ${browser:-$BROWSER}

	if (( ${?} != 0 )) {
		pr-error "No web-browser found."
		return 112
	}

	#
	# Handle (Mozilla) specific profiles
	#
	case ${PROFILE} {
		(mozilla*)
		function {
			if [[ -n ${1} ]] && [[ -d ${HOME}/.${PROFILE}/${1} ]] {
				PROFILE=${PROFILE}/${1}
				return
			}
			PROFILE="${PROFILE}/$(sed -nre "s|^[Pp]ath=(.*$)|\1|p" \
				${HOME}/.${PROFILE}/profiles.ini)"
			[[ -n ${PROFILE} ]] && [[ -d ${HOME}/.${PROFILE} ]]
		} ${bhp[profile]}

		if (( ${?} != 0 )) {
			pr-error "No firefox profile directory found"
			return 113
		}
		;;
	}

:	${compressor:=lz4 -1 -}
:	${profile:=${PROFILE:t}}
:	${bhp[compressor]:=$compressor}
:	${bhp[profile]:=$profile}
:	${bhp[PROFILE]:=$PROFILE}
:	${tmpdir:=${TMPDIR:-/tmp/$USER}}
:	${ext=.tar.$compressor[(w)1]}

	[[ -d ${tmpdir} ]] || mkdir -p -m 1700 ${tmpdir} ||
		{ pr-error "No suitable directory found"; return 114; }

	for dir (${HOME}/.${PROFILE} ${HOME}/.cache/${PROFILE#config/}) {
		[[ -d ${dir} ]] || continue
		grep -q ${dir} /proc/mounts && continue
		pr-begin "Setting up directory..."

		pushd -q ${dir:h} || continue
		if [[ ! -f ${profile}${ext} ]] || [[ ! -f ${profile}.old${ext} ]] {
			tar -Ocp ${profile} | ${=compressor} ${profile}${ext} ||
				{ pr-error "Failed to pack a tarball"; continue; }
		}
		popd -q

		case ${dir} {
			(*.cache/*) char=c;;
			(*) char=p;;
		}
		DIR=$(mktmp -p ${tmpdir}  -d bh${char}-XXXXXX)
		sudo mount --bind ${DIR} ${dir} || pr-error "Failed to mount ${DIR}"
		pr-end ${?}
	}
} "${@}"
BHP_RET=${?}

function bhp {
	local ext=.tar.${bhp[compressor][(w)1]} name=bhp tarball

	for dir (${HOME}/.{,cache/}mozilla/firefox/${bhp[profile]}) {
		pushd -q ${dir:h} || continue
		pr-begin "Setting up tarball..."
		if [[ -f ${bhp[profile]}/.unpacked ]] {
			if [[ -f ${bhp[profile]}${ext} ]] {
				mv -f ${bhp[profile]}{,.old}${ext} ||
				{ pr-error "Failed to override the old tarball"; continue; }
			}
			tar -X ${bhp[profile]}/.unpacked -Ocp ${bhp[profile]} | \
				${=bhp[compressor]} ${bhp[profile]}${ext} ||
				pr-error "Failed to repack a new tarball"
		} else {
			if [[ -f ${bhp[profile]}${ext} ]] {
				tarball=${bhp[profile]}${ext}
			} elif [[ -f ${bhp[profile]}.old${ext} ]] {
				tarball=${bhp[profile]}.old${ext}
			} else { pr-error "No tarball found" }

			${bhp[compressor][(w)1]} -cd ${tarball} | tar -xp &&
				touch ${bhp[profile]}/.unpacked ||
				pr-error "Failed to unpack the profile"
		}
		pr-end ${?}
		popd -q
	}
}

case ${0:t} {
	(bhp*|browser-home-profile*) (( ${BHP_RET} == 0)) && bhp;;
}

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
