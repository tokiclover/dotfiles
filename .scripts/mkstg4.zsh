#!/bin/zsh
# $Id: $HOME/.scripts/mkstg4.zsh,v 1.1 2012/04/07 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -b|-boot            whether to backup /boot to /bootcp
  -c|-comp            compression command to use, default is 'gzip'
  -C|-cipher <aes>    cipher to use when encypting the tarball archive
  -e|-exclude <files> files/dirs to exclude from the tarball archive
  -g|-gpg             encrypt using GnuPG, require --pubkey or -symmetric
  -K|-pubkey <id>     encrypt the final tarball using <id> public key
  -M|-symmetric       encrypt using a signed symmetricly encrypted key
  -p|-prefix <p>      prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -P|-pass <1>        number of pass to encrypt the tarball when using -S
  -t|-tarball         suffix scheme to name the tarball,default is 'stg4'
  -r|-root </>        root directory for the backup, default is '/'
  -Q|-sdr             use sdr script to squash squashed directories
  -s|-stgdir          stage4 dircteroy, location to save the tarball
  -S|-split <b>       size of byte to split the tarball archive
  -u|-usage           print this help/usage and exit
EOF
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts b boot c: comp: C: cipher: e: exclude: g gpg K: pubkey: \
	M symmetric p: prefix: P: pass: t: tarball r: root: Q sdr s: stgdir: S: split u usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage; exit 0 }
if [[ -z ${opts[*]} ]] { typeset -A opts }
: 	${opts[-prefix]:=${opts[-p]:-$(uname -r | cut -c-3)}}
:	${opts[-root]:=${opts[-r]:-/}}
:	${opts[-stgdir]:=${opts[-s]:-/mnt/sup/bik}}
: 	${opts[-tarball]:=${opts[-prefix]}${opts[-tarball]:-${opts[-t]:-.stg4}}}
:	${opts[-split]:=${opts[-S]}}
:	${opts[-cipher]:=${opts[-C]:-aes}}
:	${opts[-comp]:=${opts[-c]:-gzip}}
opts[-tarball]=${opts[-stgdir]}/${opts[-tarball]}
case ${=opts[-comp]} in
	bzip2)	opts[-tarball]+=.tbz2;;
	xz) 	opts[-tarball]+=.txz;;
	gzip) 	opts[-tarball]+=.tgz;;
	lzma)	opts[-tarball]+=.tlzma;;
	lzip)	opts[-tarball]+=.tlz;;
	lzop)	opts[-tarball]+=.tlzo;;
esac
cd ${opts[-root]} || die "invalid root directory"
opts[-exclude]+=" mnt/* media home dev proc sys tmp var/portage var/local/portage 
	run var/run var/lock var/pkg var/dst lib*/rc/init.d lib*/splash/cache var/tmp 
	var/blddir var/.*.tgz boot/*.iso boot/*.img bootcp/*iso *.swp bootcp/*.img
	usr/portage usr/local/portage ${opts[-tarball]}
"
for file (${=opts[-exclude]//,/ } ${=opts[-e]//,/ }) { 
	opts[-opt]+=" --exclude=./$file"
}
opts[-opt]+=" --create --absolute-names --${opts[-comp]} --verbose --totals --file"
if [[ -n ${opts[-sdr]} ]] || [[ -n ${opts[-Q]} ]] {
	which sdr &> /dev/null || die "there's no sdr script in PATH"
	sdr -o0 -U -dsbin:bin:lib32:lib64
	sdr -o0    -dvar/db:var/cahce/edb:opt:usr
	rsync -avR ${opts[-root]}/sqfsd ${opts[-stgdir]}
	mv ${opts[-stgdir]}/sqfsd{,-${opts[-prefix]}}
	opts[-exclude]+=" usr opt var/db var/cache/edb var/lib/layman sqfsd/*.sfs
	sqfsd/*/*.sfs sqfsd/*/*/*.sfs sqfsd/*/ro sqfsd/*/*/ro sqfsd/*/*/*/ro"
}
if [[ -n ${opts[-boot]} ]] || [[ -n ${opts[-b]} ]] {
	mount /boot
	sleep 3
	cp -aR /boot /bootcp
	umount /boot
	sleep 3 
}
tar ${=opts[-opt]} ${opts[-tarball]} .;
if [[ -n ${opts[-gpg]} ]] || [[ -n ${opts[-g]} ]] {
	cd ${opts[-stgdir]}
 	if [[ -n ${opts[-symmetric]} ]] {
		echo ${opts[-pass]:-1} | gpg --encrypt --batch --cipher-algo ${opts[-cipher]} \
			--passphrase-fd 0 --symmetric --output ${opts[-tarball]}.gpg ${opts[-tarball]}
	} else { gpg --encrypt --batch --recipient ${opts[-pubkey]} --cipher-algo ${opts[-cipher]} \
			--output ${opts[-tarball]}.gpg ${opts[-tarball]}
	}
	rm ${opts[-tarball]}
	opts[tarball]+=.gpg
}
if [[ -n ${opts[-split]} ]] {
	split --bytes=${opts[-split]} ${opts[-tarball]} ${opts[-tarball]}.
}
rm -rf /bootcp
unset opts
