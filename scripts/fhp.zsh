#!/bin/zsh
# $Id: ~/scripts/fhp.zsh,v 1.4 2014/07/22 21:09:26 -tclover Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
#
# And maybe something like: */30 * * * * $USER ~/scripts/fhp.zsh
# in cron job to keep track of changes is necessary.

# @ENV_VARIABLE: FHPDIR
# @DESCRIPTION: Firefox profile dir to handle
# @EXEMPLE: FHPDIR=~/.mozilla/firefox/abc123.default

# @ENV_VARIABLE: ZRAMDIR:=/mnt/zram
# @DESCRIPTION: Zram block device backed FS to use for firefox profile

# @ENV_VARIABLE: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# you should have this one already, just put it to tmpfs with something like:
# /etc/fstab: tmp	/tmp	tmpfs	mode=1777,size=256M,noatime	0 0

fhp_init() {
	local mnt
:	${FHPDIR:=$(print ~/.mozilla/firefox/*.default 2>/dev/null)}

	[[ -z $FHPDIR ]] && die "fhp: no profile found"
	grep $FHPDIR /proc/mounts && return
	
	if [[ -n $ZRAMDIR ]] {
		mnt=$ZRAMDIR/$USER/fhp
	} elif [[ -n $TMPDIR ]] {
		 mnt=$TMPDIR/fhp
	} else {
		die "fhp: neither ZRAMDIR nor TMPDIR env variable is set"
	}
	
	if [[ ! -d $mnt ]] {
		sudo mkdir -p $mnt &&
		sudo chown $UID:$GID -R $mnt:h
		chmod 1700 $mnt:h
	}
	sudo mount --bind $FHPDIR $mnt || die "fhp: failed to mount $mnt"
}

fhp_update() {
	local dir=$FHPDIR:h fhp=$FHPDIR:t
	
	pushd -q $dir
	if [[ -f $fhp/.unpacked ]] {
		mv -f $fhp.tar.gz $fhp.old.tar.gz || die "fhp: failed to override old tarball"
		tar -X $fhp/.unpacked -czpf $fhp.tar.gz $fhp/ ||
		die "fhp: failed to pack the profile"
	} else {
		tar xzpf $fhp.tar.gz || tar xzpf $fhp.old.tar.gz &&
		touch $fhp/.unpacked || die "fhp: failed to unpack the profile"
	}
	popd -q
}

fhp_init
fhp_update

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
