#!/bin/bash
# $Id: ~/.scripts/mkstg4.bash,v 1.3 2013/01/07 12:55:37 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${0##*/} [OPTIONS...]
  -b, --boot               whether to backup /boot to /bootcp
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
      --sqfsdir <dir>      squashed directory-ies root directory tree
      --sysdir <:dir>      system squashed dirs that require 'sdr --update' option
      --sqfsd <:dir>       local squashed dirs that do not require 'sdr --update'
  -d, --dir <dir>          stage4 dircteroy, location to save the tarball
  -s, --split <bytes>      size of byte to split the tarball archive
  -u, --usage              print this help/usage and exit
EOF
exit $?
}
error() { echo -ne "\e[1;31m* \e[0m$@\n"; }
die()   { error "$@"; exit 1; }
opts=$(getopt -o bc:e:gqp:r:R::s:d:t:u -l cipher:,comp:,encrypt,exclude:,gpg \
	-l sdr,sqfsd:,split:,sqfsdir:,dir:,symmetric,sysdir:,root:,tarball:,usage \
	-l recipient:,sign,restore:: -n ${0##*/} -- "$@" || usage)
eval set -- "$opts"
while [[ $# > 0 ]]; do
	case $1 in
		-q|--sdr) sdr=sdr; shift;;
		-b|--boot) boot=y; shift;;
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
		--sqfsd) sqfsd=":${2}"; shift 2;;
		-s|--split) split="${2}"; shift 2;;
		-t|--tarball) tarball="${2}"; shift 2;;
		--sqfsdir) sqfsdir="${2}"; shift 2;;
		--sysdir) sysdir="${2}"; shift 2;;
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
[[ -n "${tarball}" ]] && tarball=${prefix}.${tarball} \
	|| tarball=${prefix,}.stage4
[[ -n "${comp}" ]] || comp=gzip
tarball="${dir}/${tarball}"
case ${comp} in
	bzip2)	tarball+=.tar.bz2;;
	xz) 	tarball+=.tar.xz;;
	gzip) 	tarball+=.tar.gz;;
	lzma)	tarball+=.tar.lzma;;
	lzip)	tarball+=.tar.lz;;
	lzop)	tarball+=.tar.lzo;;
esac
build() {
echo -ne "\e[1;32m>>> building ${tarball} stage4 tarball...\e[0m$@\n"
pushd ${root} || die "invalid root directory"
for file in mnt/* media home dev proc sys tmp run boot/*.i{mg,so} bootcp/*.i{mg,so} \
	var/{run,lock,pkg,src,bdir,.*.tgz,tmp} lib*/rc/init.d lib*/splash/cache \
	${tarball}; do
	if [[ -f "${file}" ]]; then opt+=" --exclude=${file}"
	elif [[ -d "${file}" ]]; then opt+=" --exclude=${file}/*"; fi
done
if [ -n "${sdr}" ]; then
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	[[ -n "${sqfsdir}" ]] || sqfsdir=sqfsd
	[[ -n "${sysdir}" ]] && sdr.bash -r${sqfsdir} -o0 -U -d${sysdir}
	[[ -n "${sqfsd}" ]] && sdr.bash -r${sqfsdir} -o0  -d${sqfsd}
	dirname=${sqfsdir##*/}
	for file in $(find ${sqfsdir} -type f -iname '*.sfs'); do
		d=${file%.sfs}
		opt+=" --exclude=${file} --exclude=${d}/rr/* --exclude=${d#${sqfsdir//\//}/}/*"
		rsync -avuR ${file} ${dir}/${dirname}-${prefix#*-}
	done
fi
if [ -n "${boot}" ]; then
	mount /boot
	sleep 3
	cp -aR /boot{,cp}
	umount /boot
	sleep 3
fi
opt+=" --create --absolute-names --${comp} --verbose --totals"
if [ -n "${gpg}" ]; then
	opt+=" ${root} | ${gpg} --output ${tarball}.gpg"
	tarball+=.gpg
else  opt+=" --file ${tarball} ${root}"
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
	[[ -n "${sdr}" ]] && rsync -avuR \
		${dir}/./${sqfsdir:t}-${prefix} ${root}/
	if [[ -n "${gpg}" ]]; then gpg="gpg --decrypt ${tarball}.gpg |"
	else opt+=" --file ${tarball}"; gpg=
	fi
	${gpg} tar ${opt} || die "failed to restore"
	[[ -d /bootcp ]] && mount /boot && cp -aru /bootcp/* /boot/
	sed -e 's:^\#.*(.*)::g' -e 's:SUBSYSTEM.*".*"::g' -i /etc/udev/rules.d/*persistent-cd.rules \
		-i /etc/udev/rules.d/*persistent-net.rules
	echo -ne "\e[1;32m>>> successfuly restored ${tarball} stage4 tarball\e[0m$@\n"
else build; fi
rm -rf /bootcp
unset -v dirname opts opt
popd
# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
