#!/bin/zsh
# $Id: ~/scr/fhp.zsh,v 1.5 2014/07/31 21:09:26 -tclover Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
#
# And maybe something like: */30 * * * * $USER ~/scr/fhp.zsh
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

source ~/scr/functions.zsh || return 1

fhp_init() {
:	${FHPDIR:=$(print ~/.mozilla/firefox/*.default 2>/dev/null)}
:	${TMPDIR:=/tmp}

	[[ -z $FHPDIR ]] && die "fhp: no firefox profile dir found"
	mount | grep "$FHPDIR" >/dev/null 2>&1 && return
	
	local fhp=$FHPDIR:t mnt
	if [[ ! -f $FHPDIR.tar.lz4 ]] || [[ ! -f $FHPDIR.old.tar.lz4 ]] {
		pushd -q $FHPDIR:h || die
		tar -Ocp $fhp | lz4c -1 - $fhp.tar.lz4  ||
		die "fhp: failed to pack a new tarball"
		popd -q
	}

	[[ -n $ZRAMDIR ]] && mnt=$(mktemp -d $ZRAMDIR/fhp-XXXXXX) ||
        mnt=$(mktemp -d $TMPDIR/fhp-XXXXXX)
	
	if [[ ! -d $mnt ]] {
		sudo mkdir -p -m1700 $mnt &&
		sudo chown $UID:$GID -R $mnt:h
	}
	sudo mount --bind $FHPDIR $mnt || die "fhp: failed to mount $mnt"
}

fhp_update() {
	local dir=$FHPDIR:h fhp=$FHPDIR:t
	local tbl=$fhp.tar.lz4 otb=$fhp.old.tar.lz4
	
	pushd -q $dir
	if [[ -f $fhp/.unpacked ]] {
		mv -f $tbl $otb || die "fhp: failed to override the old tarball"
		tar -X $fhp/.unpacked -Ocp $fhp | lz4c -1 - $tbl ||
		die "fhp: failed to repack a new tarball"
	} else {
		if [[ -f $tbl ]] {
			lz4c -d $tbl - | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		} elif [[ -f $otb ]] {
			lz4c -d $otb - | tar -xp && touch $fhp/.unpacked ||
			die "fhp: failed to unpack the profile"
		} else { die "fhp: failed to unpack the profile" }
	}
	popd -q
}

fhp_init
fhp_update

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
