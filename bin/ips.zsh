#!/bin/zsh
#
# retrieve IP block lists to be added to iptables rules
#
# $Header: ips.zsh,v 2.1 2014/09/26 14:56:24 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)      Exp $
#

function usage {
  cat <<-EOH
  usage: ${(%):-%1x} [-f|--file=<file>] [-t|--target=<url>] [OPTIONS]
  
  -d, --datadir           data dir location, default to '/var/lib/ipset'
  -f, --file <file>       file src to use insted of using a url target
  -o, --logger <cron>     use facility to log in logger, default to cron
  -l, --list [<name>]     add set to <name> list:net, IPBlock by default
  -p, --params <params>   parameters, options to pass to IPSet
  -t, --target <url>      use url src to use instead using a file target
  -g, --gpg [<url.asc>]   use url to get pub key or use <file.asc> if -f,
                          default to <url.asc> if <use.asc> not specified
  -x, --xtr [</path/xtr>] path to xtr script, default to '~/bin/xtr'
  -r, --raw               data file is raw file with only usable data
  -a, --archive           data file is an archive or tarball file
  -h, --help, -?          print this help/usage and exit

    default:              :...two implemented use cases...:
  --ipdeny                use http://ipdeny.com/ipblocks/data
  --dshield               use https://www.dshield.org/block.txt
EOH
exit $?
}

function error {
	(( $+opts[-logger] )) && logger -p $opts[-facility].err -t ips: $argv
	print -P " %B%F{red}*%b %1x: %F{yellow}%U%I%u%f: $argv" >&2
}

function die {
	local ret=$?
	error $argv
	exit $ret
}

function info {
	(( $+opts[-logger] )) && logger -p $opts[-facility].notice -t ips: $argv
	print -P " %B%F{green}*%b%f %1x: $argv"
}


typeset -A opts
typeset -a opt
opt=(
	"-o" "ad:f:g::o::p:rt:ux:"
	"-l" "archive,datadir:,filename:,gpg::,logger::"
	"-l" "params:,raw,target:,usage,xtr:,dshield,ipdeny"
	"-n" ${(%):-%1x}
)
opt=($(getopt $opt -- $argv || usage))
eval set -- $opt

for (( ; $# > 0; ))
	case $1 {
		(-a|--archive)
			opts[-archive]=
			shift;;
		(-o|--logger)
			opts[-logger]= opts[-facility]=${2:-user}
			shift 2;;
		(-f|--file)
			opts[-file]=$2
			shift 2;;
		(-l|--list)
			opts[-params]=list:net
			shift 2;;
		(-p|--params)
			opts[-params]=$2
			shift 2;;
		(-d|--datadir)
			opts[-datadir]=$2
			shift 2;;
		(-g|--gpg)
			opts[-gpg]=$2
			shift 2;;
		(-r|--raw)
			opts[-raw]=
			shift;;
		(-t|--target)
			opts[-target]+=" $2"
			shift 2;;
		(-x|--xtr)
			xtr=$2
			shift 2;;
		(--dshield)
			opts[-dshield]="http://feeds.dshield.org/block.txt"
			shift;;
		(--ipdeny)
			opts[-raw]= opts[-ipdeny]="http://www.ipdeny.com/ipblocks/data/countries/MD5SUM"
			shift;;
		(--)
			shift
			break;;
		(-?|-h|--help|*) usage;;
	}

mkdir -p -m 0600 ${opts[-datadir]} 
for module (/lib/modules/$(uname -r)/**/ip_set{,_${${=opts[-params]/:/_}[(w)1]}}.ko)
	modprobe ${${module:t}%.ko} 

function get_time {
	print $(date -r ${1:-$datafile} +%m/%d:%R)
}

function get_file {
	wget -qNP ${opts[-datadir]} ${1} || die "wget failed to get ${1}"
}

function get_sign {
	[[ -e $gpgfile ]] || die "$gpgfile not found"
	gpg --verify $gpgfile $datafile ||
	die "gpg failed to verify $datafile file"
}

function get_target {
	local target=${1:-opts[-target]}
	datafile=${opts[-datadir]}/${target:t}
	oldtime=$(get_time)
	get_file $target

	if (( $+opts[-gpg] )) {
		if [[ -z $gpgfile ]] {
			gpgfile=${datafile%*.}.asc
			get_file ${opts[-target]}.asc
		} elif [[ ${gpgfile%%*/} == "http*:" ]] {
			gpgfile=${opts[-datadir]}/$gpgfile:t
			get_file ${opts[-gpg]}
		}
	}
}

function ipfilter {
	sed -nre 's/(^([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p' ${1:-$datafile}
}

function ipblock {
	local data=${1:-$datafile} name=${2} tmp net i
:	${name:=${${data:t}%.*}}
	tmp=${name%-*}-tmp

	(( $+opts[-raw] )) && net=($(<$data)) || net=($(ipfilter $data))
	ipset create $tmp ${=opts[-params]}

	for (( i=1; i <= $#net[@]; ++i ))
		ipset add $tmp $net[i]

	ipset create -exist $name ${=opts[-params]}
	ipset swap $tmp $name &&
	ipset destroy $tmp &&
	info "$name IPSet updated"
}

if (( $+opts[-gpg] )) {
	[[ -n ${opts[-gpg]} ]] || gpgfile=${opts[-gpg]}
}

if (( $+opts[-target]} )) {
	get_target ${opts[-target]}
} elif (( $+opts[-file] )) {
	datafile=${opts[-file]}
	[[ -e $datafile ]] || die "no $datafile file provided"
	oldtime=$(get_time)
	(( $+opts[-gpg] )) && [[ -z $gpgfile ]] && gpgfile=$datafile.asc
} else { die "-t|-f should be passed with a url|file" }

(( $+opts[-gpg] )) && get_sign

newtime=$(get_time)
if [[ $newtime != $oldtime ]] {
	if (( $+opts[-archive] )) {
		[[ -x ${opts[-xtr]} ]] || die "xtr script not found"
		tmpdir=$(mktemp -d ips-XXXXXX)
		pushd -q $tmpdir || die "failed to make a $tmpdir"
		$xtr $datafile || die "xtr: failed to deflate $datafile"
		for file ((*/)#) {
			datafile=${opts[-datadir]}/${file:t}
			oldtime=$(get_time)
			cp -a $file $datafile
			newtime=$(get_time)
			[[ $newtime != $oldtime ]] && ipblock
		}
		popd -q
	} elif (( $+opts[-ipdeny] )) {
		n=IPBlock t=${opts[-target]:h} d=${opts[-datadir]}
		echo >${d}/${n}
		while read h c; do
			if [[ ${c/*.} != zone ]] { continue }
			datafile=${d}/${c}
			if [[ -f ${datafile} ]] { s=($(md5sum ${datafile}))
				if [[ ${s[1]} != ${h} ]] { get_file ${t}/${c} }
			} else { get_file ${t}/${c} }
			s=($(md5sum $datafile))
			if [[ ${s[1]} != ${h} ]] { rm ${datafile}
			} else { cat <${datafile} >>${d}/${n} }
		done <${d}/MD5SUM

		if (( $+opts[-dshield] )) {
			get_target ${opts[-dshield]}
			for i ($(ipfilter ${opts[-datadir]}/${opts[-dshield]:t}))
				echo $i/24 >>${d}/${n}
		}
		datafile=${d}/$n ipblock
		unset n t h c d
	} else { ipblock }
}

unset -v opts tmpdir oldtime newtime

#
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
#
