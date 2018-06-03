#!/bin/bash
#
# $Header: ~/bin/mkstage4.bash                              Exp $
# $Author: -tclover <tokiclover@gmail.com>                  Exp $
# $Version: 2.0 2015/07/26 13:08:56                         Exp $
# $License: MIT (or 2-clause/new/simplified BSD)            Exp $
#

shopt -qs extglob nullglob

declare -A PKG
PKG=(
	[name]=mkstage4
	[shell]=bash
	[version]=2.1
)

function usage {
  cat <<-EOH
  usage: ${PKG[name]}.${PKG[shell]} [OPTIONS]

  -c, --compressor=lzop    compression command to use, default is 'gzip'
  -X, --exclude=<files>    files/dirs to exclude from the tarball archive
  -g, --gpg                encrypt and/or sign the final tarball[.gpg]
  -C, --cipher=<aes>       cipher to use when encypting the tarball archive
  -e, --encrypt            encrypt, may be combined with --symmetric/--sign
      --recipient <u-id>   encrypt the final tarball using <user-id> public key
  -S, --sign               sign the tarball using <user-id>, require --recipient
      --symmetric          encrypt with a symmetric cipher using a passphrase
  -p, --prefix=<3.3>       prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -t, --tarball=<stg4>     suffix scheme to name the tarball,default is 'stg4'
  -r, --root=</>           root directory for the backup, default is '/'
  -R, --restore=[<dir>]    restore the stage4 backup from optional <dir>
  -q, --sdr                use sdr script to squash squashed directories
      --sdr-root=<dir>     squashed directory-ies root directory tree
      --sdr-sys=<:dir>     system squashed dirs that require 'sdr --update' option
      --sdr-dir=<:dir>     local squashed dirs that do not require 'sdr --update'
  -d, --dir=<dir>          stage4 dircteroy, location to save the tarball
  -s, --split <bytes>      size of byte to split the tarball archive
  -h, --help, -?           print this help/usage and exit
EOH
exit $?
}

function error {
	echo -ne " \e[1;31m* \e[0m${PKG[name]}.${PKG[shell]}: $@\n" >&2
}

function die {
	local ret=$?
	error "$@"
	exit $ret
}

declare -A opts
declare -a exclude gpg opt
opt=(
	"-o" "?C:c:d:ehqR::r:Ss:t:X:"
	"-l" "exclude:,cipher:,compressor:,dir:,encrypt,gpg,help"
	"-l" "sdr,sdr-root:,sdr-dir:,sdr-sys:,root,tarball"
	"-l" "recipient:,symmetric,sign,restore"
	"-n" "${PKG[name]}.${PKG[shell]}"
	"-s" "${PKG[shell]}"
)
opt=($(getopt "${opt[@]}" -- "$@" || usage))
eval set -- "${opt[@]}"
exclude=()

for (( ; $# > 0; )); do
	case $1 in
		(-q|--sdr)
			sdr=$(type -p sdr)
			if [[ -z "$sdr" ]]; then
				[[ -f "$HOME"/bin/sdr.bash ]] && sdr="$HOME"/bin/sdr.bash || die
			fi
			shift;;
		(-S|--sign)
			gpg+=(--sign)
			shift;;
		(-e|--encrypt)
			gpg+=(--encrypt)
			shift;;
		(-C|--cipher)
			gpg+=(--cipher-algo $2)
			shift 2;;
		(--recipient)
			gpg+=(--recipient "$2")
			shift 2;;
		(-g|--gpg)
			gpg=(gpg "${gpg[@]}")
			shift;;
		(-X|--exclude)
			exclude+=(${2//:/ })
			shift 2;;
		(--symmetric)
			gpg+=(--symmetric)
			shift;;
		(-p|--prefix)
			opts[prefix]="$2"
			shift 2;;
		(-d|--dir)
			opts[dir]="$2"
			shift 2;;
		(-c|--compressor)
			opts[compressor]="$2"
			shift 2;;
		(--sdr-dir)
			opts[sdr-dir]+=":$2"
			shift 2;;
		(-s|--split)
			opts[split]="$2"
			shift 2;;
		(-t|--tarball)
			opts[tarball]="$2"
			shift 2;;
		(--sdr-root)
			opts[sdr-root]="$2"
			shift 2;;
		--sdr-sys)
			opts[sdr-sys]+=":$2"
			shift 2;;
		(-r|--root)
			opts[root]="$2"
			shift 2;;
		(-R|--restore)
			opts[restore]="$2"
			[[ "${opts[restore]}" ]] || opts[restore]=true
			shift 2;;
		(--)
			shift
			break;;
		(-?|-h|--help|*) usage;;
	esac
done
opt=("${@}")

:	${opts[prefix]:=$(uname -s)-$(uname -m)-$(uname -r | cut -d- -f1)}
:	${opts[root]:=/}
:	${opts[dir]:=/mnt/bak/$(uname -m)}
:	${opts[tarball]:=${opts[prefix]}-stage4}
:	${opts[tarball]:=${opts[prefix]}-${opts[tarball]}}
:	${opts[compressor]:=gzip}
:	${opts[sdr-root]:=/squash}
opts[tarball]="${opts[dir]}/${opts[tarball]}"

case "${opts[compressor]}" in
	(bzip2)	opts[tarball]+=.tar.bz2;;
	(xz) 	opts[tarball]+=.tar.xz;;
	(gzip) 	opts[tarball]+=.tar.gz;;
	(lzma)	opts[tarball]+=.tar.lzma;;
	(lzip)	opts[tarball]+=.tar.lz;;
	(lzop)	opts[tarball]+=.tar.lzo;;
	(lz4)	opts[tarball]+=.tar.lz4;;
esac

function mkstage {

echo -ne "\e[1;32m>>> building ${opts[tarball]} stage4 tarball...\e[0m$@\n"
pushd "${opts[root]}" || die "invalid root directory"

exclude+=(
	"${opts[tarball]}"
	boot/iso/*.i{mg,so}
	mnt media home
	dev proc sys tmp run
	var/{run,lock,pkg,src,tmp}
)

for file in "${exclude[@]}"; do
	opt+=("--exclude=${file}")
done

if [[ "${sdr}" ]]; then
	[[ "${opts[sdr-sys]}" ]] &&
		${sdr} -q${opts[sdr-root]} -o0 -u "${opts[sdr-sys]}"
	[[ "${opts[sdr-dir]}" ]] &&
		${sdr} -q${opts[sdr-root]} -o0  "${opts[sdr-dir]}"

	dirname="${opts[sdr-root]##*/}"
	for file in $(find "${opts[sdr-root]}" -type f -iname '*.squashfs'); do
		opt+=(--exclude=${file} --exclude=${file%.squashfs}/rr)
		rsync -avuR "${file}" "${opts[dir]}/${dirname}-${opts[prefix]#*-}"
	done
fi

opt+=(--create -I "${opts[compressor]}" --verbose --totals)

if [[ "${gpg[@]}" ]]; then
	opts[tarball]+=.gpg
	opt+=("${opts[root]}" '|' "${gpg[@]}" --output "${opts[tarball]}")
else
	opt+=(--file "${opts[tarball]}" "${opts[root]}")
fi

eval tar "${opt[@]}" || die "failed to backup"

if [[ "${opts[split]}" ]]; then
	split --bytes="${opts[split]}" "${opts[tarball]}" "${opts[tarball]}."
fi

echo -ne "\e[1;32m>>> successfuly built ${opts[tarball]} stage4 tarball\e[0m$@\n"

}

if [[ "${opts[restore]}" ]]; then
	opt=(--extract --verbose --preserve --directory "${opts[root]}")
	echo -ne "\e[1;32m>>> restoring ${opts[tarball]} stage4 tarball...\e[0m$@\n"

	[[ "$sdr" ]] && rsync -avuR "${opts[dir]}/./${opts[sdr-root]}-${opts[prefix]}" \
		"${opts[root]}"/

	if [[ "${gpg[@]}" ]]; then
		gpg=(gpg --decrypt "${opts[tarball]}".gpg '|')
	else
		opt+=(--file "${opts[tarball]}")
		gpg=()
	fi

	eval "${gpg[@]}" tar "${opt[@]}" || die "failed to restore"

	echo >/etc/udev/rules.d/*persistent-cd.rules
	echo >/etc/udev/rules.d/*persistent-net.rules

	echo -ne "\e[1;32m>>> successfuly restored ${opts[tarball]} stage4 tarball\e[0m$@\n"
	exit
fi

mkstage

unset -v exclude dirname opts opt
popd

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
