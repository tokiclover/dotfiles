#!/bin/bash
# $Id: ~/scripts/fhp.bash,v 1.3 2014/07/07 22:00:26 -tclover Exp $

# A handy script to put firefox profile to tmpfs or zram device.
# A frst environment variable is required in ~/.bashrc or whatever:
# `export FHP=$(ls -d ~/.mozilla/firefox/*.default)';
# and maybe something like: */30 * * * * $USER ~/.scripts/fhp
# to keep track of changes.
# If you have an entry like this in your `/etc/fstab':
# tmp	/tmp	tmpfs	mode=0777,size=128M,noatime	0 0
# just set `TMPFS=/tmp' in your env; or else, if you have a fs
# mount on top of a zram device, then just set ZRAMFS.

# @ENV_VARIABLE: FHP
# @DESCRIPTION: Firefox profile
# @EXEMPLE: FHP=/$USER/.mozilla/firefox/abhd123.default

# @ENV_VARIABLE: ZRAMFS
# @DESCRIPTION: Zram block device backed FS to use for firefox profile
# @EXAMPLE: ZRAMFS=/zram

# @ENV_VARIABLE: TMPFS
# @DESCRIPTION: tmpfs directory to use instead of zram fs backed fs
# @EXEMPLE: TMPFS=/tmp/.private/$USER

# @ENV_VARIABLE: FHP_INIT
# @DESCRIPTION: an env variable to avoid wasting extra cpu cycles

# @ENV_VARIABLE: FHP
# @DESCRIPTION: Firefox Home Profile (~/.mozilla/firefox/*.default)

# @FUNCTION: fhp
# @DESCRIPTION: put firefox profile to tmpfs by default, or use zam instead
fhp_init() {
:	${FHP:=$(ls -d ~/.mozilla/firefox/*.default)}
	local _m=/.private/"$USER"

	[[ -z $FHP ]] && die "no profile found"

	if [[ -n "$ZRAMFS" ]]; then
		_m="$ZRAMFS$_m"
	elif [[ -n "$TMPFS" ]]; then
		_m="$TMPFS$_m"
	else
		die "neither ZRAMFS nor TMPFS env variable is set"
	fi

	if [[ ! -d "$_m" ]] {
		sudo mkdir -p "$_m" &&
		sudo chown $UID:$GID -R ${_m%/*}
		chmod 0700 ${_m%/*}
	fi
	sudo mount --bind "$FHP" "$_m" || die "Failed to mount $_m"

	export FHP_INIT=1
}

fhp_update() {
	local _d="${FHP%/*}" _p="${FHP##*/}"

	pushd "$_d"
	if [[ -f "$FHP"/.unpacked ]]; then
		mv $_p.tgz $_p.old.tgz || die "failed to override .old profile"
		tar -X $_p/.unpacked -czpf $_p.tgz $_p ||
		die "failed to pack the profie"
	else
		tar xzpf $_p.tgz || tar xzpf $_p.old.tgz &&
		touch $FHP/.unpacked || die "failed to unpack the profile"
	fi
	popd
}

[[ -n "$FHP_INIT" ]] || fhp_init
fhp_update

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=2:ts=2:
