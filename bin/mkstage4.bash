#!/bin/bash
#
# $Id: mkstage4.bash,v 2.0 2014/08/31 13:08:56 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
#
usage() {
  cat <<-EOF
  usage: ${0##*/} [OPTIONS...]
  -c, --comp               compression command to use, default is 'gzip'
  -e, --exclude <files>    files/dirs to exclude from the tarball archive
  -g, --gpg                encrypt and/or sign the final tarball[.gpg]
      --cipher <aes>       cipher to use when encypting the tarball archive
      --encrypt            encrypt, may be combined with --symmetric/--sign
      --recipient <u-id>   encrypt the final tarball using <user-id> public key
      --sign               sign the tarball using <user-id>, require --recipient
      --symmetric          encrypt with a symmetric cipher using a passphrase
  -p, --prefix <3.3>       prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -t, --tarball <stg4>     suffix scheme to name the tarball,default is 'stg4'
  -r, --root </>           root directory for the backup, default is '/'
  -R, --restore [<dir>]    restore the stage4 backup from optional <dir>
  -q, --sdr                use sdr script to squash squashed directories
      --sdr-root <dir>     squashed directory-ies root directory tree
      --sdr-sys <:dir>     system squashed dirs that require 'sdr --update' option
      --sdr-dir <:dir>     local squashed dirs that do not require 'sdr --update'
  -d, --dir <dir>          stage4 dircteroy, location to save the tarball
  -s, --split <bytes>      size of byte to split the tarball archive
  -h, --help               print this help/usage and exit
EOF
exit $?
}

error() {
	echo -ne "\e[1;31m* \e[0m$@\n" >&2
}

die() {
	error "$@"
	exit
}

opts=$(getopt -o c:e:gqp:r:R::s:d:t:u -l cipher:,comp:,encrypt,exclude:,gpg \
	-l sdr,sdr-root:,split:,sdr-dir:,dir:,symmetric,sdr-sys:,root:,tarball:,usage \
	-l recipient:,sign,restore:: -n ${0##*/} -- "$@" || usage)
eval set -- "$opts"

while [[ $# > 0 ]]; do
	case $1 in
		-q|--sdr) sdr=sdr; shift;;
		--sign) gpg+=" --sign"; shift;;
		--encrypt) gpg+=" --encrypt"; shift;;
		--cipher) gpg+=" --cipher-algo ${2}"; shift 2;;
		--recipient) gpg+=" --recipient \"${2}\""; shift 2;;
		-g|--gpg) gpg="gpg ${gpg}"; shift;;
		-e|--exclude) exclude="${2//:/ }"; shift 2;;
		--symmetric) gpg+=" --symmetric"; shift;;
		-p|--prefix) prefix="${2}"; shift 2;;
		-d|--dir) dir="${2}"; shift 2;;
		-c|--comp) comp="${2}"; shift 2;;
		--sdr-dir) sdrdir+=":${2}"; shift 2;;
		-s|--split) split="${2}"; shift 2;;
		-t|--tarball) tarball="${2}"; shift 2;;
		--sdr-root) sdrroot="${2}"; shift 2;;
		--sdr-sys) sdrsys+="${2}"; shift 2;;
		-r|--root) root="${2}"; shift 2;;
		-R|--restore) restore="${2}"; shift 2
		[[ -n ${restore} ]] || restore=y;;
		--) shift; break;;
		-u|--usage|*) usage;;
	esac
done

[[ -n "${prefix}" ]] || prefix="$(uname -s)-$(uname -m)-$(uname -r | cut -d- -f1)"
[[ -n "${root}" ]] || root=/
[[ -n "${dir}" ]] || dir=/mnt/sup/$(uname -m)
[[ -n "${tarball}" ]] && tarball=${prefix}.${tarball} || tarball=${prefix,}.stage4
[[ -n "${comp}" ]] || comp=gzip
[[ "${sdrroot}" ]] || sdrroot=/aufs
tarball="${dir}/${tarball}"

case ${comp} in
	bzip2)	tarball+=.tar.bz2;;
	xz) 	tarball+=.tar.xz;;
	gzip) 	tarball+=.tar.gz;;
	lzma)	tarball+=.tar.lzma;;
	lzip)	tarball+=.tar.lz;;
	lzop)	tarball+=.tar.lzo;;
esac

build()
{
echo -ne "\e[1;32m>>> building ${tarball} stage4 tarball...\e[0m$@\n"
pushd ${root} || die "invalid root directory"

EXCLUDE=(
	${exclude}
	${tarball}
	boot/iso/*.i{mg,so}
	mnt media home
	dev proc sys tmp run
	lib$(getconf LONG_BIT)/splash/cache
	var/{run,lock,pkg,src,tmp}
)

for file in ${EXCLUDE[@]}; do
	if [[ -f "${file}" ]]; then
		opt+=" --exclude=${file}"
	elif [[ -d "${file}" ]]; then
		opt+=" --exclude=${file}/*"
	fi
done

if [ -n "${sdr}" ]; then
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	[[ "${sdrsys}" ]] && sdr.bash -r${sdrroot} -o0 -U -d${sdrsys}
	[[ "${sdrdir}" ]] && sdr.bash -r${sdrroot} -o0  -d${sdrdir}
	dirname=${sdrroot##*/}
	for file in $(find ${sdrroot} -type f -iname '*.squashfs'); do
		d=${file%.squashfs}
		opt+=" --exclude=${file} --exclude=${d}/rr/* --exclude=${d#${sdrroot//\//}/}/*"
		rsync -avuR ${file} ${dir}/${dirname}-${prefix#*-}
	done
fi

opt+=" --create --absolute-names --${comp} --verbose --totals"

if [ -n "${gpg}" ]; then
	opt+=" ${root} | ${gpg} --output ${tarball}.gpg"
	tarball+=.gpg
else
	opt+=" --file ${tarball} ${root}"
fi

tar ${opt} || die "failed to backup"

if [ -n "${split}" ]; then
	split --bytes=${split} ${tarball} ${tarball}.
fi

echo -ne "\e[1;32m>>> successfuly built ${tarball} stage4 tarball\e[0m$@\n"
}

if [[ -n "${restore}" ]]; then
	opt="--extract --verbose --preserve --directory ${root}"
	echo -ne "\e[1;32m>>> restoring ${tarball} stage4 tarball...\e[0m$@\n"

	[[ -n "${sdr}" ]] && rsync -avuR ${dir}/./${sdrroot}-${prefix} ${root}/

	if [[ -n "${gpg}" ]]; then
		gpg="gpg --decrypt ${tarball}.gpg |"
	else
		opt+=" --file ${tarball}"; gpg=
	fi

	${gpg} tar ${opt} || die "failed to restore"

	sed -e 's:^\#.*(.*)::g' -e 's:SUBSYSTEM.*".*"::g' \
	    -i /etc/udev/rules.d/*persistent-cd.rules \
		-i /etc/udev/rules.d/*persistent-net.rules

	echo -ne "\e[1;32m>>> successfuly restored ${tarball} stage4 tarball\e[0m$@\n"
else 
	build
fi

unset -v EXCLUDE dirname opts opt
popd

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
