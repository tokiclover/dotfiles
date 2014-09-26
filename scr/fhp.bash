#!/bin/bash
#
# $Header: fhp.bash                                     Exp $
# $Aythor: (c) 2011-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.2 2014/09/09 21:09:26                     Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--compression 'lzop -1']
# @DESCRIPTION: set compressor, default to lz4
#
# And maybe something like: */30 * * * * $USER /path/to/fhp.zsh
# in cron job to keep track of changes is necessary.
# lz4 compressor is required, or else, use -c|--compression 'lzop -1'

# @ENV_VARIABLE: ZRAMDIR
# @DESCRIPTION: Zram block device backed FS to use for firefox profile

# @ENV_VARIABLE: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# you should have this one already, just put it to tmpfs with something like:
# /etc/fstab: tmp /tmp tmpfs mode=1777,size=256M,noatime 0 0
#

shopt -qs extglob
shopt -qs nullglob

# Define a little helper to handle errors
function die {
	local ret=$?
	echo -e "\e[1;31m* \e[0m${0##*/}: $@\n" >&2
	exit $ret
}

function fhp-help {
	cat <<-EOH
usage: fhp [options] [firefox-profile]
  -c, --compressor 'lzop -1'  set lzop compressor instead of lz4
  -z, --zsh-exit-hook         add fhp function to zshexit hook
  -h, --help                  print this help message and exit
EOH
}

typeset -A fhpinfo

function fhp-init {
	while (( $# > 0 )); do
		case $1 in
			(-h|--help)
				usage
				exit;;
			(-c|--compressor)
				fhpinfo[compressor]="$2"
				shift 2;;
			(*)
				fhpinfo[fhp]="$1"
				break;;
		esac
	done

	[[ "$fhpinfo[fhp]}" ]] && [[ -d "$HOME/.mozzila/firefox/${fhpinfo[fhp]}" ]] ||
		fhpinfo[fhp]=
	[[ "$fhpinfo[fhp]}" ]] ||	fhpinfo[fhp]="${1:-$FHP}"
	if [[ -z "${fhpinfo[fhp]}" ]]; then
		FHPDIR=$(ls -d $HOME/.mozilla/firefox/*.default 2>/dev/null)
		fhpinfo[fhp]="${FHPDIR##*/}"
	fi
	[[ "${fhpinfo[fhp]}" ]] || die "no firefox profile dir found"
	[[ ${fhpinfo[fhp]%.default} == ${fhpinfo[fhp]} ]] && fhpinfo[fhp]+=.default

	[[ "${fhpinfo[compressor]}" ]] || fhpinfo[compressor]="lz4 -1 -"
	local ext=.tar.${fhpinfo[compressor]%% *}

:	${FHPDIR:=$HOME/.mozilla/firefox/${fhpinfo[fhp]}}
:	${TMPDIR:=/tmp/.private/"$USER"}

	[[ "$ZRAMDIR" ]] || [[ -d "$TMPDIR" ]] || mkdir -p -m1700 "$TMPDIR" || die

	mount | grep -q "$FHPDIR" && return
	
	local mntdir
	if [[ ! -f "$FHPDIR$ext" ]] || [[ ! -f "$FHPDIR.old$ext" ]]; then
		pushd "${FHPDIR%/*}" >/dev/null 2>&1 || die
		tar -Ocp ${fhpinfo[fhp]} | ${fhpinfo[compressor]} ${fhpinfo[fhp]}$ext ||
			die "failed to pack a new tarball"
		popd >/dev/null 2>&1
	fi

	[[ -n "$ZRAMDIR" ]] && mnt="$(mktemp -d "$ZRAMDIR/$USER"/fhp-XXXXXX)" ||
		mntdir="$(mktemp -d $TMPDIR/fhp-XXXXXX)"

	sudo mount --bind "$mntdir" "$FHPDIR" || die "failed to mount $mntdir"
}
fhp-init "$@"


function fhp {
	local ext=.tar.${fhpinfo[compressor]%% *}

	pushd "$HOME/.mozilla/firefox" >/dev/null 2>&1 || die
	if [[ -f ${fhpinfo[fhp]}/.unpacked ]]; then
		if [[ -f ${fhpinfo[fhp]}$ext ]]; then
			mv -f ${fhpinfo[fhp]}{,.old}$ext || die "failed to override the old tarball"
		fi
		tar -X ${fhpinfo[fhp]}/.unpacked -Ocp ${fhpinfo[fhp]} | \
			${fhpinfo[compressor]} ${fhpinfo[fhp]}$ext ||
			die "failed to repack a new tarball"
	else
		local decompress="${fhpinfo[compressor]%% *}"
		if [[ -f ${fhpinfo[fhp]}$ext ]]; then
			$decompress -cd ${fhpinfo[fhp]}$ext | tar -xp &&
				touch ${fhpinfo[fhp]}/.unpacked ||
				die "failed to unpack the profile"
		elif [[ -f ${fhpinfo[fhp]}.old$ext ]]; then
			$decompress -cd ${fhpinfo[fhp]}.old$ext | tar -xp &&
				touch ${fhpinfo[fhp]}/.unpacked ||
				die "failed to unpack the profile"
		else
			die "no tarball found"
		fi
	fi
	popd >/dev/null 2>&1
}

if [[ "${0##*/}" == fhp*(.bash) ]]; then
	fhp
	unset fhpinfo
fi

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
