#!/bin/zsh
# $Id: ~/.scripts/hdu.zsh,v 1.0 2012/05/08 16:38:33 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} -f <file>
  -o|-olddate <date>     old date or regex to replace by a new date
  -f|-file :<file>       include <file> or file
  -u|-usage              print this help/usage and exit
EOF
exit 0
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts f+: file+: o: olddate: u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-olddate]:=${opts[-o]:-2012/05/}}
: 	${opts[-newdate]:=$(date +%Y/%m/%d\ %T)}
opts[-file]+=:${opts[-f]}
for file (${(pws,:,)opts[-file]}) if [[ -n "$(grep ${opts[-olddate]} ${file})" ]] {
	sed -e "s,${opts[-olddate]}.*-,${opts[-newdate]} -,g" \
		-i ${file} || die "${file}: failed to update file"
}
unset -v opts
