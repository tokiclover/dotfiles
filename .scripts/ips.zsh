#!/bin/zsh
# $Id: ~/.scripts/ips.zsh , 2012/07/27 01:56:24 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -d|-datadir           data dir location, default is '/var/lib/ipset'
  -f|-file <file>       filename, default is target basename
  -l|-logger            log cron jobs errors in logger
  -p|-params <params>   parameters, options to pass to IPSet
  -t|-target <url>      URL to retrieve the data file
  -u|-usage             print this help/usage and exit
EOF
exit 0
}
error() { 
	if [[ -n ${(k)opts[-l]} ]] || [[ -n ${(k)opts[-logger]} ]] { logger -p cron.err $@ }
	print -P "%B%F{red}*%b%f $@"
}
die() { error "%F{yellow}%1x:%U${(%):-%I}%u:%f $@"; exit 1 }
info()  { 
	if [[ -n ${(k)opts[-l]} ]] || [[ -n ${(k)opts[-logger]} ]] { logger -p cron.info $@ }
	print -P " %B%F{green}*%b%f $@" 
}
zmodload zsh/zutil
zparseopts -E -D -K -A opts d: datadir: f: file: l logger p: params: t: target: \
	u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
: 	${opts[-datadir]:=${opts[-d]:-/var/lib/ipset}}
:	${opts[-target]:=${opts[-t]:-http://feeds.dshield.org/block.txt}}
:	${opts[-file]:=${opts[-f]:-${opts[-target]:t}}}
:	${opts[-params]:=${opts[-p]:-hash:ip --netmask 24 --hashsize 64}}
:	${opts[-datafile]:=${opts[-datadir]}/${opts[-target]:t}}
mkdir -p -m 0750 ${opts[-datadir]} 
for module (/lib/modules/$(uname -r)/**/ip_set{,_${${=opts[-params]}[1]/:/_}}.ko) { 
	modprobe ${${module:t}%.ko} 
}
gtime() {
	opts[-time]=$(date -r ${opts[-datafile]} +%m/%d:%R 2>/dev/null)
	print ${opts[-time]}
}
opts[-oldtime]=$(gtime)
wget -qNP ${opts[-datadir]} ${opts[-target]} || die "IPSet: ${opt[-file]} wget failed"
opts[-time]=$(gtime)
if [[ ${opts[-time]} != ${opts[-oldtime]} ]] {
	opts[-ipset]=${opts[-file]%.*}
	opts[-tmp]=${opts[-ipset]}.tmp
	ipset create ${opts[-tmp]} ${=opts[-params]}
	networks=($(grep -E '^[0-9]' ${opts[-datafile]} | \
		sed -rne 's/(^([0-9]{1,3}.){3}[0-9]{1,3}).*$/\1/p'))
	ip=${#networks[*]}
	while [[ $((--ip)) -ge 0 ]] { ipset add ${opts[-tmp]} ${networks[ip]} }
	ipset create -exist ${opts[-ipset]} ${=opts[-params]}
	ipset swap ${opts[-tmp]} ${opts[-ipset]}
	ipset destroy ${opts[-tmp]}
	info "IPSet: ${opts[-ipset]} updated"
}
unset -v opts networks
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
