#!/bin/bash
# $Id: $HOME/.scripts/mkstg4.bash,v 1.1 2012/04/07 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${1##*/} [OPTIONS...]
  -b, --boot            whether to backup /boot to /bootcp
  -c, --comp            compression command to use, default is 'gzip'
  -C, --cipher <aes>    cipher to use when encypting the tarball archive
  -e, --exclude <files> files/dirs to exclude from the tarball archive
  -g, --gpg             encrypt using GnuPG, require --pubkey or -symmetric
  -K, --pubkey <id>     encrypt the final tarball using <id> public key
  -M, --symmetric       encrypt using a signed symmetricly encrypted key
  -p, --prefix <p>      prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -P, --pass <1>        number of pass to encrypt the tarball when using -S
  -t, --tarball         suffix scheme to name the tarball,default is 'stg4'
  -r, --root </>        root directory for the backup, default is '/'
  -Q, --sdr             use sdr script to squash squashed directories
  -s, --stgdir          stage4 dircteroy, location to save the tarball
  -S, --split <b>       size of byte to split the tarball archive
  -u, --usage           print this help/usage and exit
EOF
}
error() { echo -ne "\e[1;31m* \e[0m$@\n"; }
die()   { error "$@"; exit 1; }
opt=$(getopt -o c:e:gK:M:P:p:qr:S:s:t:u -l comp:,exclude:,gpg,pass:,pubkey:,stgdir: \
	-l tarball:,sdr,split:,symmetric,root:,usage -n ${0##*/} -- "$@" || usage && exit 0)
eval set -- "$opt"
[[ -z "${opts[*]}" ]] && declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-u|--usage) usage; exit 0;;
		-g|--gpg) opts[gpg]=y; shift;;
		-Q|--sdr) opts[sdr]=y; shift;;
		-b|--boot) opts[boot]=y; shift;;
		-P|pass) opts[pass]=${2}; shift 2;;
		-c|--comp) opts[comp]="${2}"; shift 2;;
		-C|--cipher) opts[cipher]="${2}"; shift 2;;
		-K|--pubkey) opts[pubkey]="${2}"; shift 2;;
		-p|--prefix) opts[prefix]="${2}"; shift 2;;
		-s|--stgdir) opts[stgdir]="${2}"; shift 2;;
		-S|--split) opts[split]="${2}"; shift 2;;
		-M|--symmetric) opts[symmetric]=y; shift;;
		-t|--tarball) opts[tarball]="${2}"; shift 2;;
		-e|--exclude) opts[exclude]="${2//,/ }"; shift 2;;
		-r|--root) opts[root]="${2}"; shift 2;;
		--) shift; break;;
	esac
done
[[ -n ${opts[prefix]} ]] || opts[prefix]="$(uname -r | cut -c-3)"
[[ -n "${opts[root]}" ]] || opts[root]=/
[[ -n "${opts[stgdir]}" ]] || opts[stgdir]=/mnt/sup/bik
[[ -n "${opts[tarball]}" ]] && opts[tarball]=${opts[prefix]}${opts[tarball]} \
	|| opts[tarball]=${opts[prefix]}.stg4
[[ -n "${opts[comp]}" ]] || opts[comp]=gzip
[[ -n "${opts[cipher]}" ]] || opts[cipher]=aes
[[ -n "${opts[pass]}" ]] || opts[pass]=1
opts[tarball]="${opts[stgdir]}/${opts[tarball]}"
case ${opts[comp]} in
	bzip2)	opts[tarball]+=.tbz2;;
	xz) 	opts[tarball]+=.txz;;
	gzip) 	opts[tarball]+=.tgz;;
	lzma)	opts[tarball]+=.tlzma;;
	lzip)	opts[tarball]+=.tlz;;
	lzop)	opts[tarball]+=.tlzo;;
esac
cd ${opts[root]} || die "invalid root directory"
opts[exclude]+=" mnt/* media home dev proc sys tmp var/portage var/local/portage 
	run var/run var/lock var/pkg var/dst lib*/rc/init.d lib*/splash/cache var/tmp 
	var/blddir var/.*.tgz boot/*.iso boot/*.img bootcp/*iso *.swp bootcp/*.img
	iusr/portage usr/local/portage ${opts[-tarball]}
"
for file in ${opts[exclude]}; do opts[opt]+=" --exclude=./$file"; done
opts[opt]+=" --create --absolute-names --${opts[comp]} --verbose --totals --file"
if [ -n "${opts[sdr]}" ]; then
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	sdr -o0 -U -dsbin:bin:lib32:lib64
	sdr -o0    -dvar/db:var/cahce/edb:opt:usr
	rsync -avR ${opts[root]}/sqfsd ${opts[stgdir]}
	mv ${opts[stgdir]}/sqfsd{,-${opts[prefix]}}
	opts[-exclude]+=" usr opt var/db var/cache/edb var/lib/layman sqfsd/*.sfs
	sqfsd/*/*.sfs sqfsd/*/*/*.sfs sqfsd/*/ro sqfsd/*/*/ro sqfsd/*/*/*/ro"; fi
if [ -n "${opts[boot]}" ]; then
	mount /boot
	sleep 3
	cp -aR /boot /bootcp
	umount /boot
	sleep 3; fi
tar ${opts[opt]} ${opts[tarball]} .;
if [ -n "${opts[gpg]}" ]; then
	cd ${opts[stgdir]}
 	if [ -n "${opts[symmetric]}" ]; then
		echo ${opts[pass]} | gpg --encrypt --batch --cipher-algo ${opts[cipher]} \
			--passphrase-fd 0 --symmetric --output ${opts[tarball]}.gpg ${opts[tarball]}
	else gpg --encrypt --batch --recipient ${opts[pubkey]} --cipher-algo ${opts[cipher]} \
			--output ${opts[tarball]}.gpg ${opts[tarball]}; fi
	rm ${opts[tarball]}
	opts[tarball]+=.gpg; fi
if [ -n "${opts[split]}" ]; then
	split --bytes=${opts[split]} ${opts[tarball]} ${opts[tarball]}.; fi
rm -rf /bootcp
unset opts opt
