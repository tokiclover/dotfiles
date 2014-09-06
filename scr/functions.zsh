# $Id: functions.zsh, 2014/08/31 11:59:26 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)   Exp $

if [[ -f ~/scr/functions ]] { source ~/scr/functions }

# @FUNCTION: error
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
function eerror()
{
	[[ -n $LOG ]] && [[ -n $facility ]] &&
	logger -p $facility -t ${(%):-%1x}: $@
	print -P "%F{red}*%f ${(%):-%1x}: $@" >&2
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die()
{
	local ret=$?
	error $@
	return $ret
}

# @FUNCTION: info
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
function einfo()
{
	[[ -n $LOG ]] && [[ -n $facility ]] &&
	logger -p $facility -t ${(%):-%1x}: $@
	print -P "%F{green}*%f ${(%):-%1x}: $@"
}

# @FUNCTION: mktmp
# @DESCRIPTION: make tmp dir or file in ${TMPDIR:-/tmp}
# @ARG: [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
function mktmp()
{
	usage='cat <<-EOF
usage: mktmp [OPTIONS] TEMPLATE
  -d, --dir           create a directory
  -f, --file          create a file
  -o, --owner <name>  owner naame
  -g, --group <name>  group name
  -m, --mode <1700>   octal mode
  -h, --help          help/exit
EOF
exit'
	[[ $# == 0 ]] && ${=usage}

	local type mode owner group tmp TMP=${TMPDIR:-/tmp}
	while [[ $# -ge 1 ]]
		case $1 in
			-d|--dir) type=dir; shift;;
			-f|--file) type=file; shift;;
			-h|--help) ${=usage};;
			-m|--mode) mode=$2; shift 2;;
			-o|--owner) owner=$2; shitf 2;;
			-g|-group) group=$2; shift 2;;
		 	*) tmp=$1; shift;;
		esac

	[[ -n $tmp ]] && TMP+=/$tmp-XXXXXX ||
	die "mktmp: no $tmp TEMPLATE provided"
	if [[ $type == "dir" ]] {
		mkdir -p ${mode:+-m$mode} $TMP ||
		die "mktmp: failed to make $TMP"
	} else {
		mkdir -p $TMP:h &&
		touch $TMP || die "mktmp: failed to make $TMP"
		[[ -n $mode ]] && chmod $mode $TMP
	}
	[[ -n $owner ]] && chown $owner $TMP
	[[ -n $group ]] && chgrp $group $TMP
	print "$TMP"
}

# @FUNCTION: kmp-aa
# @DESCRIPTION: little helpter to retrieve Kernel Module Parameters
function kmp-aa () 
{ 
	local c d line m mc mod md de n=/dev/null o
	c=$(tput op) o=$(print -P "\n$(tput setaf 2)-*- $(tput op)")
	if [[ -n "$*" ]] {
		mod=($*)
	} else {
		while read line
		do
			mod+=( ${line%% *})
		done </proc/modules
	}
	for m (${mod[@]})
	{
		md=/sys/module/$m/parameters
		if [[ ! -d $md ]] { continue }
		d=$(modinfo -d $m 2>$n | tr '\n' '\t')
		print -P $o$m$c ${d:+: $d}
		pushd -q $md
		for mc (*(.))
		{
			de=$(modinfo -p $m 2>$n | grep ^$mc 2>$n | sed "s/^$mc=//" 2>$n)
			print -P "\t$mc=$(cat $mc 2>$n)" ${de:+ - $de}
		}
		popd -q
	}
}

# @FUNCTION: kmp-color
# @DESCRIPTION: colorful helper to retrieve Kernel Module Parameters
function kmp-cc ()
{
	local green yellow cyan reset
	autoload colors zsh/terminfo
	if [[ $terminfo[colors] -ge 8 ]] { colors }
	for color (green yellow cyan)
		eval $color="%F{$color}"
	reset="%f"
	newline='
'

	local d line m mc md mod n=/dev/null
	if [[ -n "$*" ]] {
		mod=($*)
	} else {
		while read line
		do
			mod+=( ${line%% *})
		done </proc/modules
	}
	for m (${mod[@]})
	{
		md=/sys/module/$m/parameters
		if [[ ! -d $md ]] { continue }
		d=$(modinfo -d $m 2>$n | tr '\n' '\t')
		print -P $green'-*- '$m$reset ${d:+: $d}
		declare pnames=() pdescs=() pvals=()
		local add_desc=false p pdesc pname
		while IFS="$newline" read p
		do
			if [[ $p =~ ^[[:space:]] ]] {
				pdesc+="$newline	$p"
			} else {
				$add_desc && pdescs+=("$pdesc")
				pname="${p%%:*}"
				pnames+=("$pname")
				pdesc=("	${p#*:}")
				pvals+=("$(cat $md/$pname 2>$n)")
			}
			add_desc=true
		done < <(modinfo -p $m 2>$n)
		$add_desc && pdescs+=("$pdesc")
		for ((i=0; i<${#pnames[@]}; i++))
		{
			if [[ -z ${pnames[i]} ]] { continue }
			print -P "\t$cyan${pnames[i]}$reset=$yellow${pvals[i]}$reset -${pdescs[i]}"
		}
	}
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
