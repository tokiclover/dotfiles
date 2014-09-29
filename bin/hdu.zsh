#!/bin/zsh
#
# $Header: hdu.zsh,v 1.1 2014/08/31 23:00:55 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)      Exp $
#

function usage {
  cat <<-EOF
  usage: ${(%):-%1x} [options] <files>
  -d|-date<date>      old date or regex to replace by a new date
  -a|-author<author>  include <file> or file
  -h|-help            print this help/usage and exit
EOF
exit $?
}

function error {
	print -P "%B%F{red}%1x%b%f: $argv"
}

function die {
	local ret=$?
	error $@
	exit $ret
}

zmodload zsh/zutil
zparseopts -E -D -K -A opts a: author: d: date: h help || usage

(( $+opts[-h] )) || (( $+opts[-help] )) && usage

if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-date]:=${opts[-d]:-$(date +%Y)}}
: 	${opts[-newd]:=$(date +%Y/%m/%d\ %T)}

if [[ -n ${opts[-author]:-${opts[-a]}} ]] {
	opts[-author]="-e s,-\ .*([a-z][A-Z]).*\ Exp,-\ ${opts[-author]:-${opts[-a]}}\ Exp,g"
}

for file ($*)
	sed -e "s,${opts[-date]}.*-,${opts[-newd]} -,g" ${opts[-author]} \
		-i ${file} || die "${file}: failed to update file"

unset -v opts

#
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
#
