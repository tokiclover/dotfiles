#!/bin/bash
#
# retrieve IP block lists to be added to iptables rules
#
# $Header: ips.bash, 2.1 2014/09/26 13:56:21 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)      Exp $
#

declare -A PKG
PKG=(
	[name]=ips
	[shell]=bash
	[version]=2.1
)

function usage {
  cat <<-EOH
  usage: ${PKG[name]}.${PKG[shell]}  [-f|-file <file>] [-t|-target <url>] [OPTIONS]
  
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
	echo -ne " \e[1;31m* \e[0m${PKG[name]}.${PKG[shell]}: $@\n" >&2
	[[ "${opts[logger]}" ]] && logger -p $facility.err "${PKG[name]}.${PKG[shell]}: $@"
}

function die {
	local ret=$?
	error "$@"
	exit $ret
}

function info {
	echo -ne " \e[1;32m* \e[0m${PKG[name]}.${PKG[shell]}: $@\n"
	[[ "${opts[logger]}" ]] && logger -p $facility.info "${PKG[name]}.${PKG[shell]}: $@"
}

declare -A opts
declare -a opt
opt=(
	"-o" "ad:f:g::o::p:rt:ux:"
	"-l" "archive,datadir:,filename:,gpg::,logger::"
	"-l" "params:,raw,target:,usage,xtr:,dshield,ipdeny"
	"-n" "${PKG[name]}.${PKG[shell]}"
	"-s" "${PKG[shell]}"
)
opt=($(getopt "${opt[@]}" -- "$@" || usage))
eval set -- "${opt[@]}"

for (( ; $# > 0; )); do
	case $1 in
		(-a|--archive)
			opts[archive]=true
			shift;;
		(-o|--logger)
			opts[logger]=true facility=${2:-user}
			shift 2;;
		(-f|--file)
			opts[file]="${2}"
			shift 2;;
		(-l|--list)
			opts[params]=list:net
			shift 2;;
		(-p|--params)
			opts[params]="${2}"
			shift 2;;
		(-d|--datadir)
			opts[datadir]="${2}"
			shift 2;;
		(-g|--gpg)
			opts[gpg]="${2:-true}"
			shift 2;;
		(-r|--raw)
			opts[raw]=true
			shift;;
		(-t|--target)
			opts[target]+=" ${2}"
			shift 2;;
		(-x|--xtr)
			xtr="$2"
			shift 2;;
		(--dshield)
			opts[dshield]="http://feeds.dshield.org/block.txt"
			shift;;
		(--ipdeny)
			opts[raw]=true opts[ipdeny]="http://www.ipdeny.com/ipblocks/data/countries/MD5SUM"
			shift;;
		(--)
			shift
			break;;
		(-?|-h|--help|*) usage;;
	esac
done

[[ "${opts[datadir]}" ]] || opts[datadir]="/var/lib/ipset"
[[ "${opts[params]}" ]] || opts[params]="hash:net hashsize 64"
if [[ "${opts[ipdeny]}" ]]; then
	opts[target]="${opts[ipdeny]}"
elif [[ "${opts[dshield]}" ]]; then
	opts[target]="${opts[dshield]}"
fi

mkdir -p -m 0600 ${opts[datadir]} 
for module in $(find /lib/modules/$(uname -r) -name \
	ip_set_$(echo ${opts[params]} | cut -d' ' -f1 | sed -e 's/:/_/').ko)
do modprobe $(basename ${module%.ko}); done

function get_time {
	echo $(date -r ${1:-$datafile} +%m/%d:%R)
}

function get_file {
	wget -qNP ${opts[datadir]} ${1} || die "wget failed to get ${1}"
}

function get_sign {
	[[ -e "$gpgfile" ]] || die "$gpgfile not found"
	gpg --verify $gpgfile $datafile ||
	die "gpg failed to verify $datafile file"
}

function get_target {
	local target=${1:-opts[target]}
	datafile=${opts[datadir]}/${target##*/}
	oldtime=$(get_time)
	get_file $target

	if [[ "${opts[gpg]}" ]]; then
		if [[ -z $gpgfile ]]; then
			gpgfile=${datafile%*.}.asc
			get_file ${opts[target]}.asc
		elif [[ "${gpgfile%%*/}" == "http*:" ]]; then
			gpgfile=${opts[datadir]}/${gpgfile##*/}
			get_file ${opts[gpg]}
		fi
	fi
}

function ipfilter {
	sed -nre 's/(^([0-9]{1,3}\.){3}[0-9]{1,3}).*$/\1/p' ${1:-$datafile}
}

function ipblock {
	local data=${1:-$datafile} name=${2} tmp net i
:	${name:=$(basename "${data%.*}")}
	tmp=${name%-*}-tmp

	[[ "${opts[raw]}" ]] && net=($(<$data)) || net=($(ipfilter $data))
	ipset create $tmp ${opts[params]}

	for (( i=0; i < ${#net[@]}; ++i )); do
		ipset add $tmp ${net[i]}
	done

	ipset create -exist $name ${opts[params]}
	ipset swap $tmp $name &&
	ipset destroy $tmp &&
	info "$ipb IPSet updated"
}

if [[ "${opts[gpg]}" ]]; then
	[[ "${opts[gpg]}" != "true" ]] && gpgfile=${opts[gpg]}
fi

if [[ "${opts[target]}" ]]; then
	get_file ${opts[target]}
elif [[ "${opts[file]}" ]]; then
	datafile=${opts[file]}
	[[ -e "$datafile" ]] || die "no $datafile file provided"
	oldtime=$(get_time)
	[[ "${opts[gpg]}" ]] && [[ -z "$gpgfile" ]] && gpgfile="$datafile.asc"
else
	die "-t|-f should be passed with a url|file"
fi

[[ "${opts[gpg]}" ]] && get_sign

newtime=$(get_time)
if [[ "$newtime" != "$oldtime" ]]; then
	if [[ "${opts[archive]}" ]]; then
		[[ "${opts[xtr]}" ]] || opts[xtrr]="~/bin/xtr"
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
	elif [[ "${opts[ipdeny]}" ]]; then
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
			[[ "${s[1]}" != "${h}" ]] &&
				rm "${datafile}" || cat <"${datafile}" >>"${d}"/${n}
		done <"${d}"/MD5SUM

		if [[ "${opts[dshield]}" ]]; then
			get_target "${opts[dshield]}"
			for i in $(ipfilter "${d}"/${opts[dshield]##*/}); do
				echo $i/24 >>"${d}"/${n}
			done
		fi
		datafile="${d}"/${n} ipblock
		unset n t h c d
	else
		ipblock
	fi
fi

unset -v datafile opts tmpdir oldtime newtime

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=4:sw=4:ts=4:
#
