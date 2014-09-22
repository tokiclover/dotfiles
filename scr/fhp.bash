#!/bin/bash
#
# $Header: fhp.bash                                     Exp $
# $Aythor: (c) 2011-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.0 2014/09/09 21:09:26                     Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--comp 'gzip -1']
# @DESCRIPTION: set compressor, default to lz4
#
# And maybe something like: */30 * * * * $USER /path/to/fhp.zsh
# in cron job to keep track of changes is necessary.
# lz4 compressor is required, or else, use -c|--comp 'lzop -1'

# @ENV_VARIABLE: FHP
# @DESCRIPTION: Firefox profile dir to handle
# @EXEMPLE: FHP=abc123
# which correspond to '~/.mozilla/firefox/$FHP.default' profile

# @ENV_VARIABLE: ZRAMDIR
# @DESCRIPTION: Zram block device backed FS to use for firefox profile

# @ENV_VARIABLE: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# you should have this one already, just put it to tmpfs with something like:
# /etc/fstab: tmp	/tmp	tmpfs	mode=1777,size=256M,noatime	0 0

function fhp {
	local n=/dev/null

# define a little helper to handle errors
function die {
	local ret=$?
	echo -e "\e[1;31m* \e[0m${0##*/}: $@\n" >&2
	return $ret
}

# define an initiliazation function
function __init {

function usage {
	cat <<-EOH
usage: fhp [options] [firefox-profile]
  -c, --comp 'lzop -1'  set lzop comprssor instead of lz4
  -h, --help            print this help message and exit
EOH
}

	while (( $# > 0 )); do
		case $1 in
			(-h|--help)
				usage
				return 128;;
			(-c|--comp)
				comp="$2"
				shift 2;;
			(*) break;;
		esac
	done

:	${comp:="lz4 -1 -"}
:	${ext="${comp%% *}"}
:	${fhp:=${1:-$FHP}}
	if [[ -z "$fhp" ]]; then
		FHPDIR="$(ls -d ~/.mozilla/firefox/*.default 2>$n)"
		fhp="${FHPDIR##*/}"
	fi
	[[ "$fhp" ]] || die "no firefox profile dir found"
	[[ ${fhp%.default} == $fhp ]] && fhp+=.default
:	${FHPDIR:=~/.mozilla/firefox/$fhp}
:	${TMPDIR:=/tmp/.private/"$USER"}
:	${dir="${FHPDIR%/*}"}

	[[ "$ZRAMDIR" ]] || [[ -d "$TMPDIR" ]] || mkdir -p -m1700 "$TMPDIR" || die

	mount | grep -q "$FHPDIR" && return
	
	local mnt
	if [[ ! -f "$FHPDIR.tar.$ext" ]] || [[ ! -f "$FHPDIR.old.tar.$ext" ]]; then
		pushd "$dir" >$n 2>&1 || die
		tar -Ocp $fhp | $comp $fhp.tar.$ext  ||
		die "failed to pack a new tarball"
		popd >$n 2>&1
	fi

	[[ -n "$ZRAMDIR" ]] && mnt="$(mktemp -d $ZRAMDIR/$USER/fhp-XXXXXX)" ||
        mnt="$(mktemp -d $TMPDIR/fhp-XXXXXX)"

	sudo mount --bind $FHPDIR $mnt || die "failed to mount $mnt"
};	__init "$@"

	# check whether -h|--help was passed
	(( $? == 128 )) && return

	# and finaly handle firefox home profile
	local tbl=$fhp.tar.$ext otb=$fhp.old.tar.$ext
	
	pushd "$dir" >$n 2>&1
	if [[ -f $fhp/.unpacked ]]; then
		mv -f $tbl $otb || die "failed to override the old tarball"
		tar -X $fhp/.unpacked -Ocp $fhp | $comp $tbl ||
		die "failed to repack a new tarball"
	else
		local decomp="${comp%% *}"
		if [[ -f $tbl ]]; then
			$decomp -cd $tbl | tar -xp && touch $fhp/.unpacked ||
			die "failed to unpack the profile"
		elif [[ -f $otb ]]; then
			$decomp -cd $otb | tar -xp && touch $fhp/.unpacked ||
			die "failed to unpack the profile"
		else
			die "no tarball found"
		fi
	fi
	popd >$n 2>&1
	unset comp dir ext fhp FHPDIR
}

fhp "$@"

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
