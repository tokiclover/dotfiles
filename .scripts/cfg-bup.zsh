#!/bin/zsh
# $Id: $HOME/.scripts/cfg-bup.zsh,v 1.0 2012/04/27 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} -s|-r [<date>]
  -s|-save            save system config files saving default
  -f|-file :<file>    include <file> or dir file to the backup
  -d|-date <date>     restore using *:<date> files/dirs
  -r|-restore <date>  restore files/dirs from <date> or newest
  -R|-root <~/.cfg>   backup root directory, default is '~/.cfg'
  -u|-usage           print this help/usage and exit
EOF
exit 0
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts d: date: f: file: s save r:: restore:: R: root:	u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-root]:=${opts[-r]:-~/.cfg}}
opts[-file]+=:/etc/make.conf:/etc/fstab:/etc/portage:/var/lib/portage:${opts[-d]}
setopt NULL_GLOB
setopt EXTENDED_GLOB
if [[ -n ${(k)opts[-s]} ]] || [[ -n ${(k)opts[-save]} ]] {
:	${opts[-date]:=${opts[-D]:-$(date +%Y%m%d%H%M)}}
	for dir (${(pws,:,)opts[-file]}) { 
		mkdir -p ${opts[-root]}/${dir:h}
		cp -ar ${dir} ${opts[-root]}/${dir}:${opts[-date]}
	}
}
if [[ -n ${(k)opts[-r]} ]] || [[ -n ${(k)opts[-restore]} ]] {
	for dir (${(pws,:,)opts[-file]}) { 
		if [[ ! -e ${opts[-root]}/${dir}:${opts[-date]}* ]] { 
			opts[-date]=$(ls -d ${opts[-root]}/${dir}:* | tail -n1)
		}; cp -ar ${opts[-root]}/${dir}:${opts[-date]}* ${dir}
	}
}
unset opts
# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=4:ts=4:
