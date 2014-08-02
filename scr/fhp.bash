#!/bin/bash
# $Id: ~/scr/fhp.bash,v 1.5 2014/07/31 21:09:26 -tclover Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
#
# And maybe something like: */30 * * * * $USER ~/scripts/fhp.bash
# in cron job to keep track of changes is necessary.
# lz4 compressed is required, or else, edit to your needs

# @ENV_VARIABLE: FHPDIR
# @DESCRIPTION: Firefox profile dir to handle
# @EXEMPLE: FHPDIR=~/.mozilla/firefox/abc123.default

# @ENV_VARIABLE: ZRAMDIR:=/mnt/zram
# @DESCRIPTION: Zram block device backed FS to use for firefox profile

# @ENV_VARIABLE: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# you should have this one already, just put it to tmpfs with something like:
# /etc/fstab: tmp	/tmp	tmpfs	mode=1777,size=256M,noatime	0 0

source ~/scr/functions.bash || return 1

fhp_init() {
:	${FHPDIR:="$(ls -d ~/.mozilla/firefox/*.default 2>/dev/null)"}
:	${TMPDIR:=/tmp}

	[[ -z "$FHPDIR" ]] && die "fhp: no firefox profile dir found"
	mount | grep "$FHPDIR" >/dev/null 2>&1 && return
	
	local dir="${FHPDIR%/*}" fhp="${FHPDIR##*/}" mnt
	if [[ ! -f "$FHPDIR.tar.lz4" ]] || [[ ! -f "$FHPDIR.old.tar.lz4" ]]; then
		pushd "$d" >/dev/null 2>&1 || die
		tar -Ocp $fhp | lz4c -1 - $fhp.tar.lz4  ||
		die "fhp: failed to pack a new tarball"
		popd >/dev/null 2>&1
	fi

	[[ -n "$ZRAMDIR" ]] && mnt="$(mktemp -d $ZRAMDIR/$USER/fhp-XXXXXX)" ||
        mnt="$(mktemp -d $TMPDIR/fhp-XXXXXX)"
	
	if [[ ! -d "$mnt" ]]; then
		dir="${mnt%/*}"
		sudo mkdir -p -m1700 "$mnt" &&
		sudo chown $UID:$GID -R $dir
	fi
	sudo mount --bind $FHPDIR $mnt || die "fhp: failed to mount $mnt"
}

fhp_update() {
	local dir="${FHPDIR%/*}" fhp="${FHPDIR##*/}"
	local tbl=$fhp.tar.lz4 otb=$fhp.old.tar.lz4
	
	pushd "$dir" >/dev/null 2>&1
	if [[ -f $fhp/.unpacked ]]; then
		mv -f $tbl $otb || die "fhp: failed to override the old tarball"
		tar -X $fhp/.unpacked -Ocp $fhp | lz4c -1 - $tbl ||
		die "fhp: failed to repack a new tarball"
	else
		if [[ -f $tbl ]]; then
			lz4c -d $tbl - | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		elif [[ -f $otb ]]; then
			lz4c -d $otb - | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		else
			die "fhp: failed to unpack the profile"
		fi
	fi
	popd >/dev/null 2>&1
}

fhp_init
fhp_update

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=2:ts=2:
