#!/bin/bash
# $Id: $HOME/.scripts/mkstg4.bash,v 1.0 2012/04/10 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${1##*/} [OPTIONS...]
  -b, --boot               whether to backup /boot to /bootcp
  -c, --comp               compression command to use, default is 'gzip'
  -e, --exclude <files>    files/dirs to exclude from the tarball archive
  -g, --gpg                encrypt and/or sign the final tarball[.gpg]
      --cipher <aes>       cipher to use when encypting the tarball archive
      --encrypt            encrypt, may be combined with --symmetric/--sign
      --pass <1>           number of pass to encrypt the tarball when using -S
      --recipient <u-id>   encrypt the final tarball using <user-id> public key
      --sign               sign the tarball using <user-id>, require --recipient
      --symmetric          encrypt with a symmetric cipher using a passphrase
  -p, --prefix <3.3>       prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -t, --tarball <stg4>     suffix scheme to name the tarball,default is 'stg4'
  -r, --root </>           root directory for the backup, default is '/'
  -q, --sdr                use sdr script to squash squashed directories
      --sqfsdir <dir>      squashed directory-ies root directory tree
      --sysdir <:dir>      system squashed dirs that require 'sdr --update' option
      --sqfsd <:dir>       local squashed dirs that do not require 'sdr --update'
  -d, --dir <dir>          stage4 dircteroy, location to save the tarball
  -s, --split <bytes>      size of byte to split the tarball archive
  -u, --usage              print this help/usage and exit
EOF
}
error() { echo -ne "\e[1;31m* \e[0m$@\n"; }
die()   { error "$@"; exit 1; }
opt=$(getopt -o bc:e:gqp:r:s:d:t:u -l cipher:,comp:,encrypt,exclude:,gpg,pass: \
	-l sdr,sqfsd:,split:,sqfsdir:,dir:,symmetric,sysdir:,root:,tarball:,usage \
	-l recipient:,sign -n ${0##*/} -- "$@" || usage && exit 0)
eval set -- "$opt"
declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-u|--usage) usage; exit 0;;
		-g|--gpg) opts[gpg]=gpg; shift;;
		-q|--sdr) opts[sdr]=sdr; shift;;
		-b|--boot) opts[boot]=y; shift;;
		--pass) opts[pass]=${2}; shift 2;;
		--sign) opts[gpg]+=" --sign"; shift;;
		--encrypt) opts[gpg]+=" --encrypt"; shift;;
		--cipher) opts[gpg]+=" --cipher-algo ${2}"; shift 2;;
		--recipient) opts[gpg]+=" --recipient ${2}"; shift 2;;
		-e|--exclude) opts[exclude]="${2//,/ }"; shift 2;;
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
		--) shift; break;;
	esac
done
[[ -n ${opts[prefix]} ]] || opts[prefix]="$(uname -r | cut -c-3)"
[[ -n "${opts[root]}" ]] || opts[root]=/
[[ -n "${opts[dir]}" ]] || opts[dir]=/mnt/sup/bik
[[ -n "${opts[tarball]}" ]] && opts[tarball]=${opts[prefix]}.${opts[tarball]} \
	|| opts[tarball]=${opts[prefix]}.stg4
[[ -n "${opts[comp]}" ]] || opts[comp]=gzip
opts[tarball]="${opts[dir]}/${opts[tarball]}"
case ${opts[comp]} in
	bzip2)	opts[tarball]+=.tbz2;;
	xz) 	opts[tarball]+=.txz;;
	gzip) 	opts[tarball]+=.tgz;;
	lzma)	opts[tarball]+=.tlzma;;
	lzip)	opts[tarball]+=.tlz;;
	lzop)	opts[tarball]+=.tlzo;;
esac
echo -ne "\e[1;32m>>> building ${opts[tarball]} stage4 tarball...\e[0m$@\n"
cd ${opts[root]} || die "invalid root directory"
for file in mnt/* media home dev proc sys tmp run boot/*.i{mg,so} bootcp/*.i{mg,so} \
	var/{{,local/}portage,run,lock,pkg,dst,blddir,.*.tgz,tmp} lib*/rc/init.d *.swp \
	lib*/splash/cache usr/{,local/}portage ${opts[tarball]}; do 
	opts[opt]+=" --exclude=$file"; done
if [ -n "${opts[sdr]}" ]; then
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	[[ -n "${opts[sqfsdir]}" ]] || opts[sqfsdir]=sqfsd
	[[ -n "${opts[sysdir]}" ]] && sdr -r${opts[sqfsdir]} -o0 -U -d${opts[sysdir]}
	[[ -n "${opts[sqfsd]}" ]] && sdr -r${opts[sqfsdir]} -o0  -d${opts[sqfsd]}
	dirname=${opts[sqfsdir]}; dirname=${dirname##*/}
	rsync -avuR ${opts[root]}/${opts[sqfsdir]}/./{*,*/*,*/*/*}.sfs \
		${opts[dir]}/${dirname}-${opts[prefix]}
	for file in usr opt var/{db,cache/edb,lib/layman} ${opts[sqfsdir]}/{*,*/*,*/*/*}.sfs \
		${opts[sqfsdir]}/{*,*/*,*/*/*}/ro; do opts[opt]+=" --exclude=$file"; done
fi
if [ -n "${opts[boot]}" ]; then
	mount /boot
	sleep 3
	cp -aR /boot /bootcp
	umount /boot
	sleep 3
fi
opts[opt]+=" --create --absolute-names --${opts[comp]} --verbose --totals --file"
tar ${opts[opt]} ${opts[tarball]} ${opts[root]}
if [ -n "${opts[gpg]}" ]; then opts[gpg]+=" --output ${opts[tarball]}.gpg ${opts[tarball]}"
 	[[ -n "${opts[pass]}" ]] && opts[gpg]="echo ${opts[pass]} | ${opts[gpg]}"
	$(${opts[gpg]} && rm ${opts[tarball]})
	opts[tarball]+=.gpg
fi
if [ -n "${opts[split]}" ]; then
	split --bytes=${opts[split]} ${opts[tarball]} ${opts[tarball]}.
fi
rm -rf /bootcp
echo -ne "\e[1;32m>>> successfuly built ${opts[tarball]} stage4 tarball\e[0m$@\n"
unset -v dirname opts opt
# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
