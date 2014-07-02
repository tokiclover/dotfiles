#!/bin/zsh
# $Id: ~/.oh-my-zsh/functions/fhp.zsh,v 1.3 2014/06/31 21:09:26 -tclover Exp $
#
# A handy script to put firefox profile to tmpfs or zram device.
# A frst environment variable is required in ~/.zshrc or whatever:
# `export FHP=$(print ~/.mozilla/firefox/*.default(/))';
# and maybe something like: */30 * * * * $USER ~/.scripts/fhp
# in cron to keep track of changes.
# If you have an entry like this in your `/etc/fstab':
# tmp	/tmp	tmpfs	mode=0777,size=128M,noatime	0 0
# just set `TMPFS=/tmp' in your env; or else, if you have a fs
# mount on top of a zram device, then just set ZRAMFS.

# @ENV_VARIABLE: FHP
# @DESCRIPTION: Firefox profile
# @EXEMPLE: FHP=/$USER/.mozilla/firefox/abc123.default

# @ENV_VARIABLE: ZRAMFS
# @DESCRIPTION: Zram block device backed FS to use for firefox profile
# @EXAMPLE: ZRAMFS=/zram

# @ENV_VARIABLE: TMPFS
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# @EXEMPLE: TMPFS=/tmp

# @ENV_VARIABLE: FHP_INIT
# @DESCRIPTION: an env variable to avoid wasting extra cpu cycles

fhp_init() {
:	${FHP:=$(print ~/.mozilla/firefox/*.default)}
	local _m=/.private/$USER

	[[ -z $FHP ]] && die "no profile found"
	
	if [[ -n $ZRAMFS ]] {
		_m=$ZRAMFS$_m
	} elif [[ -n $TMPFS ]] {
		 _m=$TMPFS$_m
	} else {
		die "neither ZRAMFS nor TMPFS env variable is set"
	}
	
	if [[ ! -d $_m ]] {
		sudo mkdir -p $_m &&
		sudo chown $UID:$GID -R $_m:h
		chmod 0700 $_m:h
	}
	sudo mount --bind $FHP $_m || die "Failed to mount $_m"

	export FHP_INIT=1
}

fhp_update() {
	local _d=$FHP:h _p=$FHP:t
	
	pushd -q $_d
	if [[ -f $_p/.unpacked ]] {
		mv -f $_p.tgz $_p.old.tgz || die "failed to override .old profile"
		tar -X $_p/.unpacked -czpf $_p.tgz $_p/ ||
		die "failed to pack the profie"
	} else {
		tar xzpf $_p.tgz || tar xzpf $_p.old.tgz &&
		touch $_p/.unpacked || die "failed to unpack the profile"
	}
	popd -q
}

[[ -n $FHP_INIT ]] || fhp_init
fhp_update

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
