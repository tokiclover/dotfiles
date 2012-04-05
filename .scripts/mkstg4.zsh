#!/bin/zsh
# $Id: $HOME/.scripts/mkstg4.zsh,v 1.1 2012/04/05 -tclover Exp $
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
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
opt=$(getopt -o c:e:gK:M:P:p:qr:S:s:t:u -l comp:,exclude:,gpg,pass:,pubkey:,stgdir: \
	-l tarball:,sdr,split:,symmetric,root:,usage -n ${0##*/} -- "$@" || usage && exit 0)
eval set -- ${opt}
[[ -z ${opts[*]} ]] && declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-u|--usage) usage; exit 0;;
		-g|--gpg) opts[gpg]=y; shift;;
		-Q|--sdr) opts[sdr]=y; shift;;
		-b|--boot) opts[boot]=y; shift;;
		-P|pass) opts[pass]=${2}; shift 2;;
		-c|--comp) opts[comp]=${2}; shift 2;;
		-C|--cipher) opts[cipher]=${2}; shift 2;;
		-K|--pubkey) opts[pubkey]=${2}; shift 2;;
		-p|--prefix) opts[prefix]=${2}; shift 2;;
		-s|--stgdir) opts[stgdir]=${2}; shift 2;;
		-S|--split) opts[split]=${2}; shift 2;;
		-M|--symmetric) opts[symmetric]=y; shift;;
		-t|--tarball) opts[tarball]=${2}; shift 2;;
		-e|--exclude) opts[exclude]=${2}; shift 2;;
		-r|--root) opts[root]=${2}; shift 2;;
		--) shift; break;;
	esac
done
: 	${opts[prefix]:=$(uname -r | cut -c-3)}
:	${opts[root]:=/}
:	${opts[stgdir]:=/mnt/sup/bik}
: 	${opts[tarball]:=${opts[prefix]}${opts[tarball]:-.stg4}}
case ${=opts[(w)1,-comp]} in
	bzip2)	opts[tarball]+=.tbz2;;
	xz) 	opts[tarball]+=.txz;;
	gzip) 	opts[tarball]+=.tgz;;
	lzma)	opts[tarball]+=.tlzma;;
	lzip)	opts[tarball]+=.tlz;;
	lzop)	opts[tarball]+=.tlzo;;
esac
cd ${opts[root]} || die "invalid root directory"
opts[exclude]+=" mnt/* media home dev proc sys tmp var/portage var/local/portage 
	usr opt run var/db var/cache/edb var/lib/layman var/run var/lock sqfsd/*/ro 
	sqfsd/*/*/ro sqfsd/*/*/*/ro var/pkg var/dst lib*/rc/init.d lib*/splash/cache 
	var/tmp var/blddir var/.*.tgz *.swp boot/*.iso boot/*.img bootcp/*iso *.swp 
	${opts[tarball]} sqfsd/*.sfs sqfsd/*/*.sfs sqfsd/*/*/*.sfs bootcp/*.img
"
for file (${opts[exclude]//,/ }) { opts[opt]+=" --exclude=./$file" }
opts[opt]+=" --create --absolute-names --${opts[comp]} --verbose --totals --file"
if [[ -n ${opts[boot]} ]] {
	mount /boot
	sleep 3
	cp -aR /boot /bootcp
	umount /boot
	sleep 3 
}
opts[tarball]=${opts[stgdir]}/${opts[tarball]}
tar ${opts[opt]} ${opts[tarball]} .;
if [[ -n ${opts[gpg]} ]] {
	cd ${opts[stgdir]}
 	if [[ -n ${opts[symmetric]} ]] {
		echo ${opts[pass]:-1} | gpg --encrypt --batch --cipher-algo ${opts[cipher]:-aes} \
			--passphrase-fd 0 --symmetric --output ${opts[tarball]}.gpg ${opts[tarball]}
	} else { gpg --encrypt --batch --recipient ${opts[pubkey]} --cipher-algo ${opts[cipher]:-aes} \
			--output ${opts[tarball]}.gpg ${opts[tarball]}
	}
	rm ${opts[tarball]}
	opts[tarball]+=.gpg
}
if [[ -n ${opts[split]} ]] {
	split --bytes=${opts[split]} ${opts[tarball]} ${opts[tarball]}.
}
rm -rf /bootcp
if [[ -n ${opts[sdr]} ]] {
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	sdr -o0 -U -dsbin:bin:lib32:lib64
	sdr -o0    -dvar/db:var/cahce/edb:opt:usr
	rsync -avR ${opts[root]}/sqfsd ${opts[stgdir]}
	mv ${opts[stgdir]}/sqfsd{,-${opts[prefix]}}
}
unset opts opt
