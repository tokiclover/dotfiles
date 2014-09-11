#!/bin/zsh
#
# $Header: fhp.zsh                                      Exp $
# $Aythor: (c) 2011-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.0 2014/09/09 21:09:26                     Exp $
#
# @DESCRIPTION: set firefox profile dir to tmpfs or zram backed fs
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--comp 'gzip -1'] [-z|--zshexit-hook]
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
	setopt LOCAL_OPTIONS
	setopt EXTENDED_GLOB
	setopt NULL_GLOB

# define a little helper to handle errors
function die {
	local ret=$?
	print -P "%F{red}*%f ${(%):-%1x}: $@" >&2
	return $ret
}

# use an anonymous function to initialize
function {

function usage {
	cat <<-EOH
usage: fhp [options] [firefox-profile]
  -c, --comp 'lzop -1'  set lzop comprssor instead of lz4
  -z, --zshexit-hook    add fhp function to zshexit hook
  -h, --help            print this help message and exit
EOH
}

	for (( ; $# > 0; ))
	case $1 in
		(-h|--help)
			usage
			return 128;;
		(-c|--comp)
			comp=$2
			shift 2;;
		(-z|--zshexit-hook)
			autoload -Uz add-zsh-hook
			add-zsh-hook zshexit fhp;;
		(*) break;;
	esac

:	${comp:="lz4 -1 -"}
:	${ext=$comp[(w)1]}
:	${fhp:=${1:-$FHP}}
:	${fhp:=${$(print ~/.mozilla/firefox/*.default(/) 2>/dev/null):t}}
	if [[ -z $fhp ]] { die "no firefox profile dir found" }
	[[ ${fhp%.default} == $fhp ]] && fhp+=.default
:	${FHPDIR:=~/.mozilla/firefox/$fhp}
:	${TMPDIR:=/tmp/.private/$USER}

	[[ -n $ZRAMDIR ]] || [[ -d $TMPDIR ]] || ( mkdir -p -m1700 $TMPDIR || die )

	( mount | grep -q $FHPDIR ) && return
	
	if [[ ! -f $FHPDIR.tar.$ext ]] || [[ ! -f $FHPDIR.old.tar.$ext ]] {
		pushd -q $FHPDIR:h || die
		tar -Ocp $fhp | ${=comp} $fhp.tar.$ext  ||
		die "failed to pack a new tarball"
		popd -q
	}

	local mnt
	[[ -n $ZRAMDIR ]] && mnt=$(mktemp -d $ZRAMDIR/fhp-XXXXXX) ||
        mnt=$(mktemp -d $TMPDIR/fhp-XXXXXX)
	sudo mount --bind $FHPDIR $mnt || die "failed to mount $mnt"
} "$@"
	
	# check whether -h|--help was passed
	(( $? == 128 )) && return

 	# and finaly maintain firefox home profile
 	local dir=$FHPDIR:h tbl=$fhp.tar.$ext otb=$fhp.old.tar.$ext
	
	pushd -q $dir
	if [[ -f $fhp/.unpacked ]] {
		mv -f $tbl $otb || die "failed to override the old tarball"
		tar -X $fhp/.unpacked -Ocp $fhp | ${=comp} $tbl ||
		die "failed to repack a new tarball"
	} else {
		local decomp=$comp[(w)1]
		if [[ -f $tbl ]] {
			$decomp -cd $tbl | tar -xp && touch $fhp/.unpacked ||
			die "failed to unpack the profile"
		} elif [[ -f $otb ]] {
			$decomp -cd $otb | tar -xp && touch $fhp/.unpacked ||
			die "failed to unpack the profile"
		} else { die "no tarball found" }
	}
	popd -q
	unset comp ext FHPDIR
}

fhp "$@"

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=4:ts=4:
