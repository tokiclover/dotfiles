#!/bin/bash
# $Id: ~/.scripts/mkstg4.bash,v 1.2 2012/11/06 18:25:05 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${0##*/} [OPTIONS...]
  -b, --boot               whether to backup /boot to /bootcp
  -c, --comp               compression command to use, default is 'gzip'
  -e, --exclude <files>    files/dirs to exclude from the tarball archive
  -E, --estring d          append an extra 'd' string after \${prefix}
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
opt=$(getopt -o bc:e:gqp:r:R::s:d:t:u -l cipher:,comp:,encrypt,exclude:,gpg \
	-l sdr,sqfsd:,split:,sqfsdir:,dir:,symmetric,sysdir:,root:,tarball:,usage \
	-l recipient:,sign,estring:,restore:: -o E: -n ${0##*/} -- "$@" || usage)
eval set -- "$opt"
declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-q|--sdr) opts[sdr]=sdr; shift;;
		-b|--boot) opts[boot]=y; shift;;
		--sign) opts[gpg]+=" --sign"; shift;;
		--encrypt) opts[gpg]+=" --encrypt"; shift;;
		--cipher) opts[gpg]+=" --cipher-algo ${2}"; shift 2;;
		--recipient) opts[gpg]+=" --recipient \"${2}\""; shift 2;;
		-g|--gpg) opts[gpg]="gpg ${opts[gpg]}"; shift;;
		-E|--estring) opts[estring]="${2}"; shift 2;;
		-e|--exclude) exclude="${2//:/ }"; shift 2;;
		--symmetric) opts[gpg]+=" --symmetric"; shift;;
		-p|--prefix) opts[prefix]="${2}"; shift 2;;
		-d|--dir) opts[dir]="${2}"; shift 2;;
		-c|--comp) opts[comp]="${2}"; shift 2;;
		--sqfsd) opts[sqfsd]=":${2}"; shift 2;;
		-s|--split) opts[split]="${2}"; shift 2;;
		-t|--tarball) opts[tarball]="${2}"; shift 2;;
		--sqfsdir) opts[sqfsdir]="${2}"; shift 2;;
		--sysdir) opts[sysdir]="${2}"; shift 2;;
		-r|--root) opts[root]="${2}"; shift 2;;
		-R|--restore) opts[restore]="${2}"; shift 2
		[[ -n ${opts[restore]} ]] || opts[restore]=y;;
		--) shift; break;;
		-u|--usage|*) usage;;
	esac
done
[[ -n ${opts[prefix]} ]] || opts[prefix]="$(uname -s)-$(uname -m)-$(uname -r | cut -d- -f1)"
[[ -n "${opts[root]}" ]] || opts[root]=/
[[ -n "${opts[dir]}" ]] || opts[dir]=/mnt/sup/$(uname -m)
[[ -n "${opts[tarball]}" ]] && opts[tarball]=${opts[prefix]}.${opts[tarball]} \
	|| opts[tarball]=${opts[prefix],}${opts[estring]}.stage4
[[ -n "${opts[comp]}" ]] || opts[comp]=gzip
opts[tarball]="${opts[dir]}/${opts[tarball]}"
case ${opts[comp]} in
	bzip2)	opts[tarball]+=.tar.bz2;;
	xz) 	opts[tarball]+=.tar.xz;;
	gzip) 	opts[tarball]+=.tar.gz;;
	lzma)	opts[tarball]+=.tar.lzma;;
	lzip)	opts[tarball]+=.tar.lz;;
	lzop)	opts[tarball]+=.tar.lzo;;
esac
build() {
echo -ne "\e[1;32m>>> building ${opts[tarball]} stage4 tarball...\e[0m$@\n"
pushd ${opts[root]} || die "invalid root directory"
for file in mnt/* media home dev proc sys tmp run boot/*.i{mg,so} bootcp/*.i{mg,so} \
	var/{run,lock,pkg,src,bldir,.*.tgz,tmp} lib*/rc/init.d lib*/splash/cache \
	${opts[tarball]}; do
	if [[ -f "${file}" ]]; then opts[opt]+=" --exclude=${file}"
	elif [[ -d "${file}" ]]; then opts[opt]+=" --exclude=${file}/*"; fi
done
if [ -n "${opts[sdr]}" ]; then
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	[[ -n "${opts[sqfsdir]}" ]] || opts[sqfsdir]=sqfsd
	[[ -n "${opts[sysdir]}" ]] && sdr.bash -r${opts[sqfsdir]} -o0 -U -d${opts[sysdir]}
	[[ -n "${opts[sqfsd]}" ]] && sdr.bash -r${opts[sqfsdir]} -o0  -d${opts[sqfsd]}
	dirname=${opts[sqfsdir]##*/}
	for file in $(find ${opts[sqfsdir]} -type f -iname '*.sfs'); do
		opts[opt]+=" --exclude=${file} --exclude=${file%.sfs}/rr"
		rsync -avuR ${file} ${opts[dir]}/${dirname}-${opts[prefix]}${opts[estring]}
	done
fi
if [ -n "${opts[boot]}" ]; then
	mount /boot
	sleep 3
	cp -aR /boot{,cp}
	umount /boot
	sleep 3
fi
opts[opt]+=" --create --absolute-names --${opts[comp]} --verbose --totals"
if [ -n "${opts[gpg]}" ]; then
	opts[opt]+=" ${opts[root]} | ${opts[gpg]} --output ${opts[tarball]}.gpg"
	opts[tarball]+=.gpg
else  opts[opt]+=" --file ${opts[tarball]} ${opts[root]}"
fi
tar ${opts[opt]} || die "failed to backup"
if [ -n "${opts[split]}" ]; then
	split --bytes=${opts[split]} ${opts[tarball]} ${opts[tarball]}.
fi
echo -ne "\e[1;32m>>> successfuly built ${opts[tarball]} stage4 tarball\e[0m$@\n"
}
if [[ -n "${opts[restore]}" ]]; then
	opts[opt]="--extract --verbose --preserve --directory ${opts[root]}"
	echo -ne "\e[1;32m>>> restoring ${opts[tarball]} stage4 tarball...\e[0m$@\n"
	[[ -n "${opts[sdr]}" ]] && rsync -avuR \
		${opts[dir]}/./${opts[sqfsdir]:t}-${opts[prefix]}${opts[estring]} ${opts[root]}/
	if [[ -n "${opts[gpg]}" ]]; then opts[gpg]="gpg --decrypt ${opts[tarball]}.gpg |"
	else opts[opt]+=" --file ${opts[tarball]}"; opts[gpg]=
	fi
	${opts[gpg]} tar ${opts[opt]} || die "failed to restore"
	[[ -d /bootcp ]] && mount /boot && cp -aru /bootcp/* /boot/
	sed -e 's:^\#.*(.*)::g' -e 's:SUBSYSTEM.*".*"::g' -i /etc/udev/rules.d/*persistent-cd.rules \
		-i /etc/udev/rules.d/*persistent-net.rules
	echo -ne "\e[1;32m>>> successfuly restored ${opts[tarball]} stage4 tarball\e[0m$@\n"
else build; fi
rm -rf /bootcp
unset -v dirname opts opt
popd
# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
