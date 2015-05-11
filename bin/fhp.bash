#!/bin/bash
#
# $Header: $HOME/bin/fhp.bash                           Exp $
# $Author: (c) 2012-014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2.4 2014/05/05                              Exp $
#
# @DESCRIPTION: Set up and maintain firefox home profile directory
#   and cache directory in a tmpfs (or zram backed filesystem.)
# @USAGE: [OPTIONS] [profile]
# @OPTIONS: [-h|--help] [-c|--compressor 'lzop -1'] [-t|--tmpdir]
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

shopt -qs extglob
shopt -qs nullglob

function error {
	echo -e "\e[1;31m* \e[0m${0##*/}: $@\n" >&2
}

function fhp-help {
	cat <<-EOH
usage: fhp [OPTIONS] [Uirefox-Home-Profile]
  -c, --compressor 'lzop -1'  Use lzop compressor, default to lz4
  -t, --tmpdir [DIR]          Set up a particular TMPDIR
  -h, --help                  Print help message and exit
EOH
}

NULL=/dev/null
typeset -A fhpinfo
#
# Use a private initializer function
#
function fhp-init {
	local DIR  dir char ext tmpdir
	for (( ; $# > 0; )); do
		case $1 in
			(-h|--help)
				fhp-help
				return 128;;
			(-c|--compressor)
				fhpinfo[compressor]="$2"
				shift 2;;
		(-t|--tmpdir)
			tmpdir=$2
			shift 2;;
			(*)
				fhpinfo[profile]="$1"
				break;;
		esac
	done

	[[ "${fhpinfo[profile]}" ]] && [[ -d "$HOME/.mozzila/firefox/${fhpinfo[profile]}" ]] ||
		fhpinfo[profile]=
	[[ "${fhpinfo[profile]}" ]] ||
	fhpinfo[profile]="${1:-$(ls -d $HOME/.mozilla/firefox/*.default 2>$NULL)}"
	fhpinfo[profile]="${fhpinfo[profile]##*/}"
	[[ "${fhpinfo[profile]}" ]] || { error "No firefox profile dir found"; return 1; }
	case "${fhpinfo[profile]}" in
		(*.default) ;;
		(*) fhpinfo[profile]+=.default;;
	esac
	[[ "${fhpinfo[compressor]}" ]] || fhpinfo[compressor]="lz4 -1 -"
:	${ext=.tar.${fhpinfo[compressor]%% *}}
:	${tmpdir:=${TMPDIR:-/tmp/"$USER"}}

	[[ -d "$TMPDIR" ]] || mkdir -p -m1700 "$TMPDIR" ||
		{ error "No suitable directory found"; return 2; }

	for dir in "$HOME"/.{,cache/}mozilla/firefox/${fhpinfo[profile]}; do
		grep -q "$dir" /proc/mounts && continue
		pushd "${dir%/*}" >$NULL 2>&1 || continue
		if [[ ! -f "${fhpinfo[profile]}$ext" ]] ||
			[[ ! -f "${fhpinfo[profile]}.old$ext" ]]; then
			tar -Ocp ${fhpinfo[profile]} | ${fhpinfo[compressor]} ${fhpinfo[profile]}$ext ||
			{ error "Failed to pack a new tarball"; continue; }
		fi
		popd >$NULL 2>&1

		case "$dir" in
			(*.cache/*) char=c;;
			(*) char=p;;
		esac
		if type -p mktemp >$NULL 2>&1; then
			mktmp=mktemp
		elif command -v checkpath >$NULL 2>&1; then
			mktmp=checkpath
		else
			DIR="$tmpdir/fh${char}-XXXXXX"
			mkdir -p -m 1700 "$DIR"
		fi
		[[ "$mktmp" ]] && DIR="$($mktmp -p "$tmpdir" -d fh${char}-XXXXXX)"
		sudo mount --bind "$DIR" "$dir" 2>$NULL ||
			{ error "Failed to mount $DIR"; continue; }
	done
}
fhp-init "$@"
FHP_RET="$?"

function fhp {
	local ext=.tar.${fhpinfo[compressor]%% *}

	for dir in "$HOME"/.{,cache/}mozilla/firefox/${fhpinfo[profile]}; do
		pushd "${dir%/*}" >$NULL 2>&1 || continue
		if [[ -f ${fhpinfo[profile]}/.unpacked ]]; then
			if [[ -f ${fhpinfo[profile]}$ext ]]; then
				mv -f ${fhpinfo[profile]}{,.old}$ext ||
					{ error "Failed to override the old tarball"; continue; }
			fi
			tar -X ${fhpinfo[profile]}/.unpacked -Ocp ${fhpinfo[profile]} | \
				${fhpinfo[compressor]} ${fhpinfo[profile]}$ext ||
				{ error "Failed to repack a new tarball"; continue; }
		else
			local decompress="${fhpinfo[compressor]%% *}"

			if [[ -f ${fhpinfo[profile]}$ext ]]; then
				local tarball=${fhpinfo[profile]}$ext
			elif [[ -f ${fhpinfo[profile]}.old$ext ]]; then
				local tarball=${fhpinfo[profile]}.old$ext 
			else
				error "no tarball found"
			fi

			$decompress -cd $tarball | tar -xp &&
				touch ${fhpinfo[profile]}/.unpacked ||
				{ error "failed to unpack the profile"; continue; }
		fi
		popd >$NULL 2>&1
	done
}

if [[ "${0##*/}" == fhp*(.bash) ]]; then
	(( $FHP_RET == 0 )) && fhp
	unset FHP_RET fhpinfo
fi

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
