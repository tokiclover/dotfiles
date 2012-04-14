#!/bin/zsh
# $Id: $HOME/.scripts/cfg-bup.zsh,v 1.0 2012/04/14 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} -s|-r [<date>]
  -s|--save            save system config files saving default
  -f|--file :<file>    include <file> file to the backup
  -d|--dir :<dir>      include <dir> directory the backup
  -r|--restore <date>  restore files/dirs from <date> or newest
  -R|--root <~/.cfg>   backup root directory, default is '~/.cfg'
  -u|--usage           print this help/usage and exit
EOF
exit 0
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts d: -dir: f: file: s -save r:: -restore:: R: -root: \
	u -usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[--usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[--root]:=${opts[-r]:-~/.cfg}}
opts[--dir]+=/etc/portage:/var/lib/portage:${opts[-d]}
opts[--file]+=/etc/make.conf:/etc/fstab
setopt NULL_GLOB
setopt EXTENDED_GLOB
if [[ -n ${(k)opts[-s]} ]] || [[ -n ${(k)opts[--save]} ]] {
	for dir (${(pws,:,)opts[--dir]}) { mkdir -p ${opts[--root]}/${dir:h}
		cp -ar ${dir} ${opts[--root]}/${dir}:$(date +%Y%m%d%H%M)
	}
	for file (${(pws,:,)opts[--file]}) { mkdir -p ${opts[--root]}/${file:h}
		cp -a ${file} ${opts[--root]}/${file}:$(date +%Y%m%d%H%M)
	}
}
if [[ -n ${(k)opts[-r]} ]] || [[ -n ${(k)opts[--restore]} ]] {
	for dir (${(pws,:,)opts[--dir]}) { date=$(ls -d ${opts[--root]}/${dir}:* | tail -n1)
		cp -ar ${opts[--root]}/${dir}:${date} ${dir}
	}
	for file (${(pws,:,)opts[--file]}) { date=$(ls ${opts[--root]}/${file}:* | tail -n1)
		cp -a ${opts[--root]}/${file}:${date} ${file}
	}
}
