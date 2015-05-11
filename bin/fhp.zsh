#!/bin/zsh
#
# $Header: $HOME/bin/fhp.zsh                            Exp $
# $Author: (c) 2012-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.4 2014/05/05                              Exp $
#
# @DESCRIPTION: Set up and maintain firefox home profile directory
#   and cache directory in a tmpfs (or zram backed filesystem.)
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--compressor 'lzop -1']
#   [-z|--zsh-exit-hook] [-t|--tmpdir]
#
# And maybe something like: */30 * * * * $USER $HOME/bin/fhp.zsh
# in cron job to keep track of changes is necessary.
# lz4 compressor is required, or else, use -c|--compression 'lzop -1'
#
# @ENVIRONMENT: TMPDIR:-/tmp/.private/$USER
# @DESCRIPTION: tmpfs directory to use instead of zram backed filesystem
#   WARN: Use something like the following in fstab(5) to set up a tmpfs
#   /tmp: tmp /tmp tmpfs nodev,exec,mode=1777,size=256M 0 0
#

function error {
	print -P " %F{red}*%f %1x: %F{yellow}%U%I%u:%f $@" >&2
}

function fhp-help {
	cat <<-EOH
usage: fhp [OPTIONS] [Firefox-Home-Profile]
  -c, --compressor 'lzop -1'  Use lzop compressor, default to lz4
  -t, --tmpdir [DIR]          Set up a particular TMPDIR
  -z, --zsh-exit-hook         Add ZSH exit hook to zshexit
  -h, --help                  Print help message and exit
EOH
}

typeset -A fhpinfo
#
# Use an anonymous function to initialize
#
function {
	local DIR dir char ext tmpdir
	for (( ; $# > 0; ))
	case $1 in
		(-h|--help)
			fhp-help
			return 128;;
		(-c|--compressor)
			compressor=$2
			shift 2;;
		(-t|--tmpdir)
			tmpdir=$2
			shift 2;;
		(-z|--zsh-exit-hook)
			autoload -Uz add-zsh-hook
			add-zsh-hook zshexit fhp;;
		(*)
			fhpinfo[profile]=$1
			break;;
	esac
	setopt LOCAL_OPTIONS EXTENDED_GLOB

	(( $+fhpinfo[profile] )) && [[ -d $HOME/.mozzila/firefox/$fhpinfo[profile] ]] ||
		fhpinfo[profile]=
:	${fhpinfo[profile]:=${1:-$(print $HOME/.mozilla/firefox/*.default(/N:t))}}

	[[ -z $fhpinfo[profile] ]] && { error "No firefox profile dir found"; return 1; }
	case $fhpinfo[profile] {
		(*.default) ;;
		(*) fhpinfo[profile]+=.default;;
	}
:	${fhpinfo[compressor]:=lz4 -1 -}
:	${tmpdir:=${TMPDIR:-/tmp/$USER}}
:	${ext=.tar.${fhpinfo[compressor][(w)1]}}

	[[ -d $TMPDIR ]] || mkdir -p -m 1700 $TMPDIR ||
		{ error "No suitable directory found"; return 2; }

	for dir ("$HOME"/.{,cache/}mozilla/firefox/$fhpinfo[profile]) {
		grep -q "$dir" /proc/mounts && continue
		pushd -q "$dir:h" || continue
		if [[ ! -f $fhpinfo[profile]$ext ]] || [[ ! -f $fhpinfo[profile].old$ext ]] {
			tar -Ocp $fhpinfo[profile] | $=fhpinfo[compressor] $fhpinfo[profile]$ext  ||
			{ error "Failed to pack a new tarball"; continue; }
		}
		popd -q

		case "$dir" {
			(*.cache/*) char=c;;
			(*) char=p;;
		}
		if (( $+commands[mktemp] )); then
			mktmp=$commands[mktemp]
		elif autoload -Uz checkpath >/dev/null 2>&1; then
			mktmp=checkpath
		else
			DIR="$tmpdir/fh${char}-XXXXXX"
			mkdir -p -m 1700 "$DIR"
		fi
		(( $+mktmp )) && DIR=$($mktmp -p "$tmpdir"  -d fh${char}-XXXXXX)
		sudo mount --bind "$DIR" "$dir" 2>/dev/null ||
			{ error "Failed to mount $DIR"; continue; }
	}
} "$@"
FHP_RET=$?

function fhp {
	local ext=.tar.${fhpinfo[compressor][(w)1]}

	for dir ("$HOME"/.{,cache/}mozilla/firefox/$fhpinfo[profile]) {
		pushd -q "$dir:h" || continue
		if [[ -f $fhpinfo[profile]/.unpacked ]] {
			if [[ -f $fhpinfo[profile]$ext ]] {
				mv -f $fhpinfo[profile]{,.old}$ext ||
				{ error "Failed to override the old tarball"; continue; }
			}
			tar -X $fhpinfo[profile]/.unpacked -Ocp $fhpinfo[profile] | \
				$=fhpinfo[compressor] $fhpinfo[profile]$ext ||
				error "Failed to repack a new tarball"
		} else {
			if [[ -f $fhpinfo[profile]$ext ]] {
				local tarball=$fhpinfo[profile]$ext
			} elif [[ -f $fhp.old$ext ]] {
				local tarball=$fhpinfo[profile].old$ext
			} else { error "No tarball found" }

			${fhpinfo[compressor][(w)1]} -cd $tarball | tar -xp &&
				touch $fhpinfo[profile]/.unpacked ||
				error "Failed to unpack the profile"
		}
		popd -q
	}
}

if [[ ${(%):-%1x} == fhp(|.zsh) ]] {
	(( $FHP_RET == 0)) && fhp
	unset FHP_RET fhpinfo
}

#
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=2:sw=2:ts=2:
#
