#!/bin/bash
# $Id: ~/scripts/ips.bash, 2.0 2014/07/07 11:56:21 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${0##*/}  [-f|-file <file>] [-t|-target <url>] [OPTIONS]
  
  -d, --datadir           data dir location, default to '/var/lib/ipset'
  -f, --file <file>       file src to use insted of using a url target
  -o, --logger <cron>     use facility to log in logger, default to cron
  -l, --list [<name>]     add set to <name> list:net, IPBlock by default
  -p, --params <params>   parameters, options to pass to IPSet
  -t, --target <url>      use url src to use instead using a file target
  -g, --gpg [<url.asc>]   use url to get pub key or use <file.asc> if -f,
                          default to <url.asc> if <use.asc> not specified
  -x, --xtr [</path/xtr>] path to xtr script, default to '~/.scripts/xtr'
  -r, --raw               data file is raw file with only usable data
  -a, --archive           data file is an archive or tarball file
  -u, --usage             print this help/usage and exit

    default:              :...two implemented use cases...:
  --ipdeny                use http://ipdeny.com/../all-zones.tar.gz url
  --dshield               use http://feeds.dshield.org/block.txt url
EOF
exit $?
}

error() { 
	echo -ne "\e[1;31m ips: \e[0m$@\n"
	$LOG && logger -p $facility.err "$@"
}

die() {
	local ret=$?
	error "$@"
	exit $ret
}

info() { 
	echo -ne " \e[1;32m ips: \e[0m$@\n"
	$LOG && logger -p $facility.info "ips: $@"
}

opt=$(getopt -o ad:f:g::o::p:rt:ux: -l archive,datadir:,filename:,gpg::,logger:: \
	-l params:,raw,target:,usage,xtr:,dshield,ipdeny \
	-n ${0##*/} -- "$@" || usage)
eval set -- "$opt"
declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-a|--archive) ARCHIVE=true; shift;;
		-o|--logger) LOG=true facility=${2:-cron}; shift 2;;
		-f|--file) opts[file]="${2}"; shift 2;;
		-l|--list) opts[params]=list:net; shift 2;;
		-p|--params) opts[params]="${2}"; shift 2;;
		-d|--datadir) opts[datadir]="${2}"; shift 2;;
		-g|--gpg) opts[gpg]="${2:-y}"; shift 2;;
		-r|--raw) RAW=true; shift;;
		-t|--target) opts[target]+=" ${2}"; shift 2;;
		-x|--xtr) xtr="$2"; shift 2;;
		--dshield) opts[target]=http://feeds.dshield.org/block.txt
		           opts[gpg]=${opts[target]}.asc;;
		--ipdeny) ARCHIVE=true RAW=true
		opts[target]=http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz;;
		--) shift; break;;
		-u|--usage|*) usage;;
	esac
done
[[ -n "${opts[datadir]}" ]] || opts[datadir]="/var/lib/ipset"
[[ -n "${opts[params]}" ]] || opts[params]="hash:ip --netmask 24 --hashsize 64"
[[ -n "${opts[xtr]}" ]] || opts[xtrr]="~/scripts/xtr"

mkdir -p -m 0750 ${opts[datadir]} 
for module in $(find /lib/modules/$(uname -r) -name \
	ip_set_$(echo ${opts[params]} | cut -d' ' -f1 | sed -e 's/:/_/').ko)
do modprobe $(basename ${module%.ko}); done

get_time() {
	echo $(date -r $datafile +%m/%d:%R 2>/dev/null)
}

get_file() {
	wget -qNP ${opts[datadir]} $1 || die "wget failed to get ${1}"
}

get_sign() {
	[[ -e $gpgfile ]] || die "$gpgfile not found"
	gpg --verify $gpgfile $datafile ||
	die "gpg failed to verify $datafile file"
}

ipb() {
	ipb=${datafile%.*}-ips
	tmp=$(mktemp ${datafile##*/}-tmp-XXXXXX)
	ipset create $tmp ${opts[params]}
	if $RAW; then
		while read line; do
			ipset add $tmp $line
		done <$datafile
	else
		net=($(sed -rne 's/(^([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p' $datafile))
		for ip in ${net[*]}; do
			ipset add $tmp $ip
		done
	fi
	ipset create -exist $ips ${opts[params]}
	ipset swap $tmp $ipb
	ipset destroy $tmp
	info "$ipb IPSet updated"
}
if [[ -n ${opts[gpg]} ]]; then
	GPG=true
	[[ "${opts[gpg]}" != "y" ]] && gpgfile=${opts[-gpg]}
fi

if [[ -n ${opts[target]} ]]; then
	datafile=${opts[datadir]}/${opts[target]##*/}
	oldtime=$(get_time)
	get_file ${opts[target]}
	if $GPG; then
		if [[ -z $gpgfile ]] {
			gpgfile=${datafile%*.}.asc
			get_file ${opts[target]}.asc
		elif [[ "${gpgfile%%*/}" == "http*:" ]]; then
			gpgfile=${opts[datadir]}/${gpgfile##*/}
			get_file ${opts[gpg]}
		fi
	fi
elif [[ -n ${opts[file]} ]]; then
	datafile=${opts[file]}
	[[ -e $datafile ]] || die "no $datafile file provided"
	oldtime=$(get_time)
	$GPG && [[ -z $gpgfile ]] && gpgfile=$datafile.asc
else
	die "-t|-f should be passed with a url|file"
fi

$GPG && get_sign

newtime=$(get_time)
if [[ $newtime != $oldtime ]]; then
	if $ARCHIVE; then
		[[ -x ${opts[xtr]} ]] || die "xtr script not found"
		tmpdir=$(mktemp -d ips-XXXXXX)
		pushd $tmpdir || die "failed to make a $tmpdir"
		$xtr $datafile || die "xtr: failed to deflate $datafile"
		for file in $(find . -name *); do
			datafile=${opts[datadir]}/${file##*/}
			oldtime=$(get_time)
			cp -a $file $datafile
			newtime=$(get_time)
			[[ $newtime != $oldtime ]] && ipb
		done
		popd
	fi
	ipb
fi

unset -v archive datafile facility opts net ip ipb tmp tmpdir \
	oldtime newtime raw GPG LOG
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
