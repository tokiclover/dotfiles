#!/bin/bash
# $Id: ~/scripts/ips.bash , 2014/07/07 01:56:21 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${0##*/} [OPTIONS...]
  -d, --datadir           data dir location, default is '/var/lib/ipset'
  -f, --file <file>       filename, default is target basename
  -l, --logger            log cron jobs errors in logger
  -p, --params <params>   parameters, options to pass to IPSet
  -t, --target <url>      URL to retrieve the data file
  -u, --usage             print this help/usage and exit
EOF
exit $?
}
error() { 
	echo -ne "\e[1;31m* \e[0m$@\n"
	[[ -n "${opts[logger]}" ]] && logger -p cron.err "$@"
}
die() { error "$@"; exit 1; }
info() 	{ 
	echo -ne " \e[1;32m* \e[0m$@\n"
	[[ -n "${opts[logger]}" ]] && logger -p cron.info "$@"
}
opt=$(getopt -o d:f:p:t:u -l datadir:,filename:,params:,target:,usage \
	-n ${0##*/} -- "$@" || usage)
eval set -- "$opt"
declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-l|--logger) opts[logger]=y; shift;;
		-f|--file) opts[file]="${2}"; shift 2;;
		-p|--params) opts[params]="${2}"; shift 2;;
		-d|--datadir) opts[datadir]="${2}"; shift 2;;
		-t|--target) opts[target]+=" ${2}"; shift 2;;
		--) shift; break;;
		-u|--usage|*) usage;;
	esac
done
[[ -n ${opts[datadir]} ]] || opts[datadir]="/var/lib/ipset"
[[ -n "${opts[target]}" ]] || opts[target]="http://feeds.dshield.org/block.txt"
[[ -n "${opts[file]}" ]] || opts[file]=${opts[target]##*/}
[[ -n "${opts[params]}" ]] || opts[params]="hash:ip --netmask 24 --hashsize 64"
opts[datafile]=${opts[datadir]}/${opts[target]##*/}
mkdir -p -m 0750 ${opts[datadir]} 
for module in $(find /lib/modules/$(uname -r) -name \
	*$(echo ${opts[params]} | cut -s -d' ' -f1 | sed -e 's/:/_/').ko)
do modprobe $(basename ${module%.ko}); done
gtime() {
	opts[time]=$(date -r ${opts[datafile]} +%m/%d:%R 2>/dev/null)
	echo "${opts[time]}"
}
opts[oldtime]="$(gtime)"
wget -qNP ${opts[datadir]} ${opts[target]} || die "IPSet: ${opt[file]} wget failed"
opts[time]="$(gtime)"
if [ "${opts[time]}" != "${opts[oldtime]}" ]; then
	opts[ipset]="${opts[file]%.*}"
	opts[tmp]="${opts[ipset]}".tmp
	ipset create ${opts[tmp]} ${opts[params]}
	networks=($(grep -E '^[0-9]' ${opts[datafile]} | \
		sed -rne 's/(^([0-9]{1,3}.){3}[0-9]{1,3}).*$/\1/p'))
	ip=${#networks[*]}
	while [ $((--ip)) -ge 0 ]; do ipset add ${opts[tmp]} ${networks[ip]}; done
	ipset create -exist ${opts[ipset]} ${opts[params]}
	ipset swap ${opts[tmp]} ${opts[ipset]}
	ipset destroy ${opts[tmp]}
	info "IPSet: ${opts[ipset]} updated"
fi
unset -v opts networks
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
