#!/bin/bash
# $Id: ~/scr/fhp.bash,v 2.0 2014/08/31 21:09:26 -tclover Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--comp 'gzip -1']
# @DESCRIPTION: set compressor, default to lz4
#
# And maybe something like: */30 * * * * $USER ~/scr/fhp.bash
# in cron job to keep track of changes is necessary.
# lz4 compressed is required, or else, use -c|-comp 'lzop -1'

# @ENV_VARIABLE: FHP
# @DESCRIPTION: Firefox profile dir to handle
# @EXEMPLE: FHP=abc123
# which correspond to '~/.mozilla/firefox/$FHP.default' profile

# @ENV_VARIABLE: ZRAMDIR:=/mnt/zram
# @DESCRIPTION: Zram block device backed FS to use for firefox profile

# @ENV_VARIABLE: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# you should have this one already, just put it to tmpfs with something like:
# /etc/fstab: tmp	/tmp	tmpfs	mode=1777,size=256M,noatime	0 0

source ~/scr/functions.bash || return 1

function fhp() {
	local n=/dev/null

	function __init()
{
	comp="lz4 -1 -"
	while [[ $# > 0 ]]
	case $1 in
		(-h|--help)
			echo "usage: fhp [-c|--comp 'lzop -1'] [profile]"
			return;;
		(-c|--comp)
			comp=${2:-$comp}
			shift 2;;
		(*) break;;
	esac

	local fhp=${1:-$FHP}
:	${fhp:=$(basename $(ls -d ~/.mozzila/firefox/*.default 2>$n) 2>$n)}
	[[ $fhp ]] || die "fhp: no firefox profile dir found"
	[[ ${fhp%.default} == $fhp ]] && fhp+=.default
	local ext="${comp%% *}"

:	${FHPDIR:=~/.mozilla/firefox/$fhp}
:	${TMPDIR:=/tmp/.private/$USER}
	[[ $ZRAMDIR]] || [[ -d $TMPDIR ]] || mkdir -p -m1700 $TMPDIR

	grep -q $FHPDIR /proc/mounts && return
	
	local dir="${FHPDIR%/*}" fhp="${FHPDIR##*/}" mnt
	if [[ ! -f "$FHPDIR.tar.$ext" ]] || [[ ! -f "$FHPDIR.old.tar.$ext" ]]; then
		pushd "$d" >/dev/null 2>&1 || die
		tar -Ocp $fhp | $comp $fhp.tar.$ext  ||
		die "fhp: failed to pack a new tarball"
		popd >/dev/null 2>&1
	fi

	[[ -n "$ZRAMDIR" ]] && mnt="$(mktemp -d $ZRAMDIR/$USER/fhp-XXXXXX)" ||
        mnt="$(mktemp -d $TMPDIR/fhp-XXXXXX)"

	sudo mount --bind $FHPDIR $mnt || die "fhp: failed to mount $mnt"
};	__init "$@"

	local dir="${FHPDIR%/*}" ext="${comp%% *}" fhp="${FHPDIR##*/}"
	local tbl=$fhp.tar.$ext otb=$fhp.old.tar.$ext
	
	pushd "$dir" >/dev/null 2>&1
	if [[ -f $fhp/.unpacked ]]; then
		mv -f $tbl $otb || die "fhp: failed to override the old tarball"
		tar -X $fhp/.unpacked -Ocp $fhp | $comp $tbl ||
		die "fhp: failed to repack a new tarball"
	else
		local decomp="${comp%% *}" opt
		case $decomp in
			(lz4)
				opt=-;;
			(bzip2|gzip|lzip|lzop|xz)
				opt=-c;;
		esac

		if [[ -f $tbl ]]; then
			$decomp -d $tbl $opt | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		elif [[ -f $otb ]]; then
			$decomp -d $otb $opt | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		else
			die "fhp: no tarball found"
		fi
	fi
	popd >/dev/null 2>&1
}

fhp

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=2:ts=2:
