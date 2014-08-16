# $Id: ~/scr/functions.zsh, 2014/08/08 11:59:26 -tclover Exp $

if [[ -f ~/scr/functions ]] { source ~/scr/functions }

# @FUNCTION: error
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
function eerror()
{
	[[ -n $LOG ]] && [[ -n $facility ]] &&
	logger -p $facility -t ${(%):-%1x}: $@
	print -P "${(%):-%1x}: ${(%):-%1x}: %B%F{red}*%b%f $@"
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die()
{
	local ret=$?
	print -P "%F{red}*%f $@"
	exit $ret
}

# @FUNCTION: info
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
function einfo()
{
	[[ -n $LOG ]] && [[ -n $facility ]] &&
	logger -p $facility -t ${(%):-%1x}: $@
	print -P "${(%):-%1x}: %B%F{green}*%b%f $@"
}

# @FUNCTION: mktmp
# @DESCRIPTION: make tmp dir or file in ${TMPDIR:-/tmp}
# @ARG: [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE
function mktmp()
{
	[[ $# == 0 ]] &&
	print "usage: mktmp [-d|-f] [-m <mode>] [-o <owner[:group]>] [-g <group>] TEMPLATE" &&
	exit 1
	local type mode owner group tmp TMP=${TMPDIR:-/tmp}
	while [[ $# -ge 1 ]] {
		case $1 in
			-d) type=dir; shift;;
			-f) type=file; shift;;
			-m) mode=$2; shift 2;;
			-o) owner=$2; shitf 2;;
			-g) group=$2; shift 2;;
		 	*) tmp=$1; shift;;
		esac
	}
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
		print -P $o$m$c
		if [[ ${#d} -gt 0 ]] { print -P " - $d" }
		pushd -q $md
		for mc (*(.))
		{
			de=$(modinfo -p $m 2>$n | grep ^$mc 2>$n | sed "s/^$mc=//" 2>$n)
			print -P "\t$mc=$(cat $mc 2>$n)"
			if [[ ${#de} -gt 1 ]] { print -P " - $de" }
			print
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
	  eval $color='%{${fg[(L)color]}%}'
	reset="%{$terminfo[sgr0]%}"
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
	  d="$(modinfo -d $m 2>$n | tr '\n' '\t')"
	  print -P $green$m$reset
	  if [[ ${#d} -gt 0 ]] { print -P " - $d"}
	  print
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
	    print -P "  $cyan${pnames[i]}$reset = $yellow${pvals[i]}$reset\n${pdescs[i]}\n"
	  }
	  print
	}
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
