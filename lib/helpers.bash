#
# $Header: ${HOME}/helpers.bash                         Exp $
# $Author: (c) 2012-015 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2015/05/14 21:09:26                         Exp $
#

#
# @FUNCTION: little helpter to retrieve Kernel Module Parameters
#
function kmod-pa {
	local c d line m mc mod md de n=/dev/null o
	c=$(tput op) o=$(echo -en "\n$(tput setaf 2)-*- $(tput op)")
	if [[ -n "$*" ]]
	then
		mod=($*)
	else
		while read line
		do
			mod+=( ${line%% *})
		done </proc/modules
	fi
	for m in ${mod[@]}
	do
		md=/sys/module/$m/parameters
		[[ ! -d $md ]] && continue
		d=$(modinfo -d $m 2>$n | tr '\n' '\t')
		echo -en "$o$m$c ${d:+:$d}"
		echo
		pushd $md >$n 2>&1
		for mc in *
		do
			de=$(modinfo -p $m 2>$n | grep ^$mc 2>$n | sed "s/^$mc=//" 2>$n)
			echo -en "\t$mc=$(cat $mc 2>$n) ${de:+ -$de}"
			echo
		done
		popd >$n 2>&1
	done
}

#
# @FUNCTION: colorful helper to retrieve Kernel Module Parameters
#
function kmod-pc {
	local green yellow cyan reset
	if [[ "$(tput colors)" -ge 8 ]]
	then
		green="\e[1;32m"
		yellow="\e[1;33m"
		cyan="\e[1;36m"
		reset="\e[0m"
	fi
	newline='
'

	local d line m mc md mod n=/dev/null
	if [[ -n "$*" ]]
	then
		mod=($*)
	else
		while read line
		do
			mod+=( ${line%% *})
		done </proc/modules
	fi
	for m in ${mod[@]}
	do
		md=/sys/module/$m/parameters
		[[ ! -d $md ]] && continue
		d="$(modinfo -d $m 2>$n | tr '\n' '\t')"
		echo -en "$green$m$reset"
		[[ ${#d} -gt 0 ]] && echo -n " - $d"
		echo
		declare pnames=() pdescs=() pvals=()
		local add_desc=false p pdesc pname
		while IFS="$newline" read p
		do
			if [[ $p =~ ^[[:space:]] ]]
			then
				pdesc+="$newline	$p"
			else
				$add_desc && pdescs+=("$pdesc")
				pname="${p%%:*}"
				pnames+=("$pname")
				pdesc=("	${p#*:}")
				pvals+=("$(cat $md/$pname 2>$n)")
			fi
			add_desc=true
		done < <(modinfo -p $m 2>$n)
		$add_desc && pdescs+=("$pdesc")
		for ((i=0; i<${#pnames[@]}; i++))
		do
			[[ -z ${pnames[i]} ]] && continue
			printf "\t$cyan%s$reset = $yellow%s$reset\n%s\n" \
			${pnames[i]} \
			"${pvals[i]}" \
			"${pdescs[i]}"
		done
		echo
	done
}

#
# @FUNCTION: generate a random password using openssl to stdout
#
function genpwd {
	openssl rand -base64 48
}
#
# @FUNCION: simple xev key code
#
function xev-key-code {
	xev | grep -A2 --line-buffered '^KeyRelease' | \
	sed -nre '/keycode /s/^.*keycode ([0-9]*).* (.*, (.*)).*$/\1 \2/p'
}

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
