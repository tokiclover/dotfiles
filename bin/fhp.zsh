#!/bin/zsh
#
# $Header: fhp.zsh                                      Exp $
# $Aythor: (c) 2011-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.1 2014/09/30                              Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--comp 'gzip -1'] [-z|--zsh-exit-hook]
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

# Define a little helper to handle errors
function die {
	local ret=$?
	print -P " %F{red}*%f %1x: %F{yellow}%U%I%u:%f $@" >&2
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

# Use an anonymous function to initialize
function {
	for (( ; $# > 0; ))
	case $1 in
		(-h|--help)
			fhp-help
			exit;;
		(-c|--compressor)
			compressor=$2
			shift 2;;
		(-z|--zsh-exit-hook)
			autoload -Uz add-zsh-hook
			add-zsh-hook zshexit fhp;;
		(*)
			fhpinfo[fhp]=$1
			break;;
	esac

	setopt LOCAL_OPTIONS EXTENDED_GLOB

	(( $+fhpinfo[fhp] )) && [[ -d $HOME/.mozzila/firefox/$fhpinfo[fhp] ]] ||
		fhpinfo[fhp]=
:	${fhpinfo[fhp]:=${1:-$FHP}}
:	${fhpinfo[fhp]:=$(print $HOME/.mozilla/firefox/*.default(/N:t))}

	[[ -z $fhpinfo[fhp] ]] && die "no firefox profile dir found"
	[[ ${fhpinfo[fhp]%.default} == $fhpinfo[fhp] ]] && fhpinfo[fhp]+=.default

:	${fhpinfo[compressor]:=lz4 -1 -}
	local ext=.tar.${fhpinfo[compressor][(w)1]}

	local FHPDIR=$HOME/.mozilla/firefox/$fhpinfo[fhp]
:	${TMPDIR:=/tmp/.private/$USER}

	[[ -n $ZRAMDIR ]] || [[ -d $TMPDIR ]] || mkdir -p -m1700 $TMPDIR || die

	mount | grep -q $FHPDIR && return
	
	if [[ ! -f $FHPDIR$ext ]] || [[ ! -f $FHPDIR.old$ext ]] {
		pushd -q $FHPDIR:h || die
		tar -Ocp $fhpinfo[fhp] | $=fhpinfo[compressor] $fhpinfo[fhp]$ext  ||
			die "failed to pack a new tarball"
		popd -q
	}

	local mntdir
	[[ -n $ZRAMDIR ]] && mntdir=$(mktemp -d $ZRAMDIR/fhp-XXXXXX) ||
		mntdir=$(mktemp -d $TMPDIR/fhp-XXXXXX)
	sudo mount --bind "$mntdir" "$FHPDIR" || die "failed to mount $mntdir"
} "$@"

function fhp {
	local ext=.tar.${fhpinfo[compressor][(w)1]}

	pushd -q $HOME/.mozilla/firefox || die
	if [[ -f $fhpinfo[fhp]/.unpacked ]] {
		if [[ -f $fhpinfo[fhp]$ext ]] {
			mv -f $fhpinfo[fhp]{,.old}$ext || die "failed to override the old tarball"
		}
		tar -X $fhpinfo[fhp]/.unpacked -Ocp $fhpinfo[fhp] | \
			$=fhpinfo[compressor] $fhpinfo[fhp]$ext ||
			die "failed to repack a new tarball"
	} else {
		if [[ -f $fhpinfo[fhp]$ext ]] {
			local tarball=$fhpinfo[fhp]$ext
		} elif [[ -f $fhp.old$ext ]] {
			local tarball=$fhpinfo[fhp].old$ext
		} else { die "no tarball found" }

		${fhpinfo[compressor][(w)1]} -cd $tarball | tar -xp &&
			touch $fhpinfo[fhp]/.unpacked ||
			die "failed to unpack the profile"
	}
	popd -q
}

if [[ ${(%):-%1x} == fhp(|.zsh) ]] {
	fhp
	unset fhpinfo
}

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
