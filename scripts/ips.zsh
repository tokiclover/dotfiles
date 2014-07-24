#!/bin/zsh
# $Id: ~/.scripts/ips.zsh,v 2.0 2014/07/22 14:56:24 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [-f|-file <file>] [-t|-target <url>] [OPTIONS]
  
  -d, -datadir           data dir location, default to '/var/lib/ipset'
  -f, -file <file>       file src to use insted of using a url target
  -o, -logger <cron>     use facility to log in logger, default to cron
  -l, -list [<name>]     add set to <name> list:net, IPBlock by default
  -p, -params <params>   parameters, options to pass to IPSet
  -t, -target <url>      use url src to use instead using a file target
  -g, -gpg [<url.asc>]   use url to get pub key or use <file.asc> if -f,
                         default to <url.asc> if <use.asc> not specified
  -x, -xtr [</path/xtr>] path to xtr script, default to '~/.scripts/xtr'
  -r, -raw               data file is raw file with only usable data
  -a, -archive           data file is an archive or tarball file
  -h, -help              print this help/usage and exit

   default:             :...two implemented use cases...:
  -ipdeny               use http://ipdeny.com/../all-zones.tar.gz
  -dshield              use https://www.dshield.org/block.txt
EOF
exit $?
}

error() {
	[[ -n $LOG ]] && logger -p $facility.err -t ips: $@
	print -P "ips: %B%F{red}*%b%f $@"
}
die() {
	local ret=$?
	error $@
	exit $ret
}
info()  { 
	[[ -n $LOG ]] && logger -p $facility.notice -t ips: $@
	print -P "ips: %B%F{green}*%b%f $@" 
}

zmodload zsh/zutil
zparseopts -E -D -K -A opts d: datadir: f: file: L logger p: params: t: target: \
	g:: gpg:: x: xtr: r raw a archive dshield ipdeny h help || usage

if [[ -z ${opts[*]} ]] { typeset -A opts }
if [[ -n ${(k)opts[-h]} ]] || [[ -n ${(k)opts[-help]} ]] { usage }
if [[ -n ${(k)opts[-o]} ]] || [[ -n ${(k)opts[-logger]} ]] {
	LOG=true
	facility=${opts[-logger]:-${opts[-l]:-cron}}
}
if [[ -n ${(k)opts[-r]} ]] || [[ -n ${(k)opts[-raw]} ]] { RAW=true }
if [[ -n ${(k)opts[-a]} ]] || [[ -n ${(k)opts[-archive]} ]] { ARCHIVE=true }
if [[ -n ${(k)opts[-dshield]} ]] {
	opts[-target]=https://feeds.dshield.org/block.txt
#	opts[-gpg]=${opts[-target]}.asc
}
if [[ -n ${(k)opts[-ipdeny]} ]] {
	opts[-target]=http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
	ARCHIVE=true RAW=true
}
: 	${opts[-datadir]:=${opts[-d]:-/var/lib/ipset}}
:	${opts[-xtr]:=${opts[-x]:-~/scripts/xtr}}
if [[ -n ${(k)opts[-l]} ]] || [[ -n ${(k)opts[-list]} ]] {
:	${opts[-params]:=${opts[-p]:-list:net}}
} else {
:	${opts[-params]:=${opts[-p]:-hash:ip netmask 24 hashsize 64}}
}

mkdir -p -m 0750 ${opts[-datadir]} 
for module (/lib/modules/$(uname -r)/**/ip_set{,_${${=opts[-params]}[1]/:/_}}.ko) { 
	modprobe ${${module:t}%.ko} 
}

get_time() {
	print $(date -r $datafile +%m/%d:%R 2>/dev/null)
}

get_file() {
	wget -qNP ${opts[-datadir]} $1 || die "wget failed to get ${1}"
}

get_sign() {
	[[ -e $gpgfile ]] || die "$gpgfile not found"
	gpg --verify $gpgfile $datafile ||
	die "gpg failed to verify $datafile file"
}

ipb() {
	local ipb=${${datafile:t}%.*}-ips tmp net ip
	tmp=${ipb/ips/tmp}
	ipset create $tmp ${=opts[-params]}
	if [[ -n $RAW ]] {
		while read line; do
			info "$line"
			ipset add $tmp ${=line}
		done <$datafile
	} else {
		net=($(sed -nre 's/(^([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p' $datafile))
		ip=${#net[*]}
		while [[ $((--ip)) -ge 0 ]] {
			info "$net[ip]"
			ipset add $tmp ${net[ip]}
		}
	}
	ipset create -exist $ipb ${=opts[-params]}
	ipset swap $tmp $ipb &&
	ipset destroy $tmp &&
	info "$ipb IPSet updated"
}

if [[ -n ${(k)opts[-gpg]} ]] || [[ -n ${(k)opts[-g]} ]] {
	GPG=true
:	${opts[-gpg]:=${opts[-g]}}
	[[ -n ${opts[-gpg]} ]] && gpgfile=${opts[-gpg]}
}

if [[ -n ${(k)opts[-target]} ]] || [[ -n ${(k)opts[-t]} ]] {
:	${opts[-target]:=${opts[-t]}}
	datafile=${opts[-datadir]}/${opts[-target]:t}
	oldtime=$(get_time)
	get_file ${opts[-target]}
	if [[ -n $GPG ]] {
		if [[ -z $gpgfile ]] {
			gpgfile=${datafile%*.}.asc
			get_file ${opts[-target]}.asc
		} elif [[ ${gpgfile%%*/} == "http*:" ]] {
			gpgfile=${opts[-datadir]}/$gpgfile:t
			get_file ${opts[-gpg]}
		}
	}
} elif [[ -n ${(k)opts[-file]} ]] || [[ -n ${(k)opts[-f]} ]] {
:	${opts[-file]:=${opts[-f]}}
	datafile=${opts[-file]}
	[[ -e $datafile ]] || die "no $datafile file provided"
	oldtime=$(get_time)
	$GPG && [[ -z $gpgfile ]] && gpgfile=$datafile.asc
} else { die "-t|-f should be passed with a url|file" }

[[ -n $GPG ]] && get_sign

newtime=$(get_time)
if [[ $newtime != $oldtime ]] {
	if [[ -n $ARCHIVE ]] {
		[[ -x ${opts[-xtr]} ]] || die "xtr script not found"
		tmpdir=$(mktemp -d ips-XXXXXX)
		pushd -q $tmpdir || die "failed to make a $tmpdir"
		$xtr $datafile || die "xtr: failed to deflate $datafile"
		for file ((*/)#) {
			datafile=${opts[-datadir]}/${file:t}
			oldtime=$(get_time)
			cp -a $file $datafile
			newtime=$(get_time)
			[[ $newtime != $oldtime ]] && ipb
		}
		popd -q
	}
	ipb
}

unset -v archive datafile facility opts tmpdir oldtime newtime raw GPG LOG

# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
