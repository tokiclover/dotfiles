#
# $Header: ${HOME}/helpers.bash                         Exp $
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2015/05/15 21:09:26                         Exp $
#

#
# @FUNCTION: little helpter to retrieve Kernel Module Parameters
#
function mod-info {
	local dir line conf mod{,s} info de null=/dev/null

	if [[ -n "$*" ]]; then
		mods=($*)
	else
		while read line; do
			mods+=( ${line%% *})
		done </proc/modules
	fi
	for mod in "${mods[@]}"; do
		dir=/sys/module/$mod/parameters
		[[ -d $dir ]] || continue
		info="$(modinfo -d $mod 2>$null)"
		echo -e "$mod${color[default]} :$(echo "$info" | tr '\n' '\t')"

		pushd $dir >$null 2>&1
		for conf in *; do
			echo -e "\t$conf=$(< $conf 2>$null) -$(echo "$info" | sed "/^$conf/s/^$conf=//" 2>$null)"
		done
		popd >$null 2>&1
	done
}

#
# @FUNCTION: colorful helper to retrieve Kernel Module Parameters
#
function mod-info-color {
	local line conf dir mod{,s} info null=/dev/null newline='
'
	if [[ -n "$*" ]]; then
		mods=($*)
	else
		while read line; do
			mods+=( ${line%% *})
		done </proc/modules
	fi
	for mod in ${mods[@]}; do
		dir=/sys/module/$mod/parameters
		[[ -d $dir ]] || continue
		info="$(modinfo -d $mod 2>$null | tr '\n' '\t')"
		echo -en "${fg[2]}$mod${color[none]}"
		(( ${#info} >= 0 )) && echo -e " - $info"

		declare -a names descs vals
		local add_desc=false desc name IFS="$newline"
		
		while read line; do
			if [[ "$line" =~ ^[[:space:]] ]]; then
				desc+="$newline	$line"
			else
				$add_desc && descs+=("$desc")
				name="${line%%:*}"
				names+=("$name")
				desc=("	${line#*:}")
				vals+=("$(< $dir/$name 2>$null)")
			fi
			add_desc=true
		done < <(modinfo -p $mod 2>$null)
		
		$add_desc && descs+=("$desc")
		for (( i=0; i<${#names[@]}; i++ )); do
			(( "${#names[i]}" > 0 )) || continue
			printf "\t${fg[6]}%s${color[none]} = ${fg[3]}%s${color[none]}\n%s\n" \
			${names[i]} \
			"${vals[i]}" \
			"${descs[i]}"
		done
		echo
	done
}

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
