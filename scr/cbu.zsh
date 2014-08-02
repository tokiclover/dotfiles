#!/bin/zsh
# $Id: ~/scr/cbu.zsh,v 1.0 2014/07/31 23:44:53 -tclover Exp $

usage() {
  cat <<-EOF
  usage: ${(%):-%1x} -s|-r [<date>]
  -s, -save            save system config files saving default
  -f, -file :<file>    include <file> or dir file to the backup
  -d, -date <date>     restore using *:<date> files/dirs
  -r, -restore <date>  restore files/dirs from <date> or newest
  -R, -root <~/cfg>    backup directory, default to '~/cfg'
  -u, -usage           print this help/usage and exit
EOF
exit $?
}

error() { print -P "%B%F{red}*%b%f $@" }
die() {
	local ret=$?
	error $@
	exit $ret
}
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'

setopt NULL_GLOB EXTENDED_GLOB
zmodload zsh/zutil
zparseopts -E -D -K -A opts d: date: f+: file+: s save \
	r:: restore:: R: root: u usage || usage

if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-root]:=${opts[-R]:-~/cfg}}
opts[-file]+=:/etc/fstab

if [[ -n ${(k)opts[-s]} ]] || [[ -n ${(k)opts[-save]} ]] {
:	${opts[-date]:=${opts[-D]:-$(date +%Y%m%d%H%M)}}
	for dir (${(pws,:,)opts[-file]} ${(pws,:,)opts[-f]}) { 
		mkdir -p ${opts[-root]}/${dir:h}
		cp -ar ${dir} ${opts[-root]}/${dir}-${opts[-date]}
	}
}

if [[ -n ${(k)opts[-r]} ]] || [[ -n ${(k)opts[-restore]} ]] {
	for dir (${(pws,:,)opts[-file]} ${(pws,:,)opts[-f]}) { 
		if [[ ! -e ${opts[-root]}/${dir}-${opts[-date]}* ]] { 
			opts[-date]=$(ls ${opts[-root]}/${dir}-* | tail -n1)
		}
		cp -ar ${opts[-root]}/${dir}-${opts[-date]}* ${dir}
	}
}

unset opts

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=4:ts=4:
