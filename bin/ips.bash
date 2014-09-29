#!/bin/bash
#
# $Id: ips.bash, 2.0 2014/08/31 13:56:21 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)  Exp $
#
function usage()
{
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
  -x, --xtr [</path/xtr>] path to xtr script, default to '~/scr/xtr'
  -r, --raw               data file is raw file with only usable data
  -a, --archive           data file is an archive or tarball file
  -h, --help, -?          print this help/usage and exit

    default:              :...two implemented use cases...:
  --ipdeny                use http://ipdeny.com/ipblocks/data
  --dshield               use https://www.dshield.org/block.txt
EOF
exit $?
}

function error()
{
	echo -ne "ips: \e[1;31m \e[0m$@\n" >&2
	[[ -n "$LOG" ]] && logger -p $facility.err "ips: $@"
}

function die()
{
	local ret=$?
	error "$@"
	exit $ret
}

function info()
{
	echo -ne "ips: \e[1;32m \e[0m$@\n"
	[[ -n "$LOG" ]] && logger -p $facility.info "ips: $@"
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
		--dshield) DSHIELD="http://feeds.dshield.org/block.txt"
			   shift;;
		--ipdeny) RAW=true IPDENY="http://www.ipdeny.com/ipblocks/data/countries/MD5SUM"
			shift;;
		--) shift; break;;
		-?|-h|--help|*) usage;;
	esac
done

[[ -n "${opts[datadir]}" ]] || opts[datadir]="/var/lib/ipset"
[[ -n "${opts[params]}" ]] || opts[params]="hash:net hashsize 64"
if [[ -n "$IPDENY" ]]; then
	opts[target]="$IPDENY"
elif [[ -n "$DSHIELD" ]]; then
	opts[target]="$DSHIELD"
fi

mkdir -p -m 0600 ${opts[datadir]} 
for module in $(find /lib/modules/$(uname -r) -name \
	ip_set_$(echo ${opts[params]} | cut -d' ' -f1 | sed -e 's/:/_/').ko)
do modprobe $(basename ${module%.ko}); done

function get_time()
{
	echo $(date -r ${1:-$datafile} +%m/%d:%R 2>/dev/null)
}

function get_file()
{
	wget -qNP ${opts[datadir]} ${1} || die "wget failed to get ${1}"
}

function get_sign()
{
	[[ -e "$gpgfile" ]] || die "$gpgfile not found"
	gpg --verify $gpgfile $datafile ||
	die "gpg failed to verify $datafile file"
}

function get_target()
{
	local target=${1:-opts[target]}
	datafile=${opts[datadir]}/${target##*/}
	oldtime=$(get_time)
	get_file $target

	if [[ -n "$GPG" ]]; then
		if [[ -z $gpgfile ]]; then
			gpgfile=${datafile%*.}.asc
			get_file ${opts[target]}.asc
		elif [[ "${gpgfile%%*/}" == "http*:" ]]; then
			gpgfile=${opts[datadir]}/${gpgfile##*/}
			get_file ${opts[gpg]}
		fi
	fi
}

function ipfilter()
{
	sed -nre 's/(^([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p' ${1:-$datafile}
}

function ipblock()
{
	local data=${1:-$datafile} name=${2} tmp net i
:	${name:=$(basename "${data%.*}")}
	tmp=${name%-*}-tmp
	[[ -n "$RAW" ]] && net=($(<$data)) || net=($(ipfilter $data))
	i=${#net[*]}
	ipset create $tmp ${opts[params]}
	while [[ $((--i)) -ge 0 ]]
		do ipset add $tmp ${net[$i]}
	done
	ipset create -exist $name ${opts[params]}
	ipset swap $tmp $name &&
	ipset destroy $tmp &&
	info "$ipb IPSet updated"
}

if [[ -n ${opts[gpg]} ]]; then
	GPG=true
	[[ "${opts[gpg]}" != "y" ]] && gpgfile=${opts[-gpg]}
fi

if [[ -n "${opts[target]}" ]]; then
	get_file ${opts[target]}
elif [[ -n "${opts[file]}" ]]; then
	datafile=${opts[file]}
	[[ -e $datafile ]] || die "no $datafile file provided"
	oldtime=$(get_time)
	[[ -n "$GPG" ]] && [[ -z $gpgfile ]] && gpgfile=$datafile.asc
else
	die "-t|-f should be passed with a url|file"
fi

[[ -n "$GPG" ]] && get_sign

newtime=$(get_time)
if [[ $newtime != $oldtime ]]; then
	if [[ -n "$ARCHIVE" ]]; then
		[[ -n "${opts[xtr]}" ]] || opts[xtrr]="~/scr/xtr"
		[[ -x "${opts[xtr]}" ]] || die "xtr script not found"
		tmpdir=$(mktemp -d ips-XXXXXX)
		pushd $tmpdir >/dev/null 2>&1 || die "failed to make a $tmpdir"
		$xtr $datafile || die "xtr: failed to deflate $datafile"
		for file in $(find . -name *); do
			datafile=${opts[datadir]}/${file##*/}
			oldtime=$(get_time)
			cp -a $file $datafile
			newtime=$(get_time)
			[[ $newtime != $oldtime ]] && ipblock
		done
		popd >/dev/null 2>&1
	elif [[ -n "${IPDENY}" ]]; then
		n=IPBlock t="${opts[target]%/*}" d="${opts[datadir]}"
		echo >"${d}"/${n}
		while read h c; do
			[[ "${c/*.}" != "zone" ]] && continue
			datafile="${d}/${c}"
			if [[ -f "${datafile}" ]]; then
				s=($(md5sum "${datafile}"))
				[[ "${s[1]}" != "${h}" ]] && get_file "${t}/${c}"
			else
				get_file "${t}/${c}"
			fi
			s=($(md5sum "${datafile}"))
			[[ ${s[1]} != ${h} ]] && rm "${datafile}" || cat <"${datafile}" >>"${d}"/${n}
		done <"${d}"/MD5SUM

		if [[ -n "${DSHIELD}" ]]; then
			get_target "${DSHIELD}"
			for i in $(ipfilter "${d}"/${DSHIELD##*/}); do
				echo $i/24 >>"${d}"/${n}
			done
		fi
		datafile="${d}"/${n} ipblock
		unset n t h c d
	else
		ipblock
	fi
fi

unset -v ARCHIVE DSHIELD GPG LOG RAW datafile facility opts tmpdir oldtime newtime

# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
