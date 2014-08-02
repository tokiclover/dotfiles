#!/bin/zsh
# $Id: ~/scr/mkstage4.zsh,v 1.3 2014/07/31 13:08:56 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -b|-boot               whether to backup /boot to /bootcp
  -c|-comp               compression command to use, default is 'gzip'
  -e|-exclude <files>    files/dirs to exclude from the tarball archive
  -g|-gpg                encrypt and/or sign the final tarball[.gpg]
     -cipher <aes>       cipher to use when encypting the tarball archive
     -encrypt            encrypt, may be combined with -symmetric/-sign
     -recipient <u-id>   encrypt the final tarball using <user-id> public key
     -sign               sign the tarball using <user-id>, require -recipient
     -symmetric          encrypt with a symmetric cipher using a passphrase
  -p|-prefix <3.3>       prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -t|-tarball <stg4>     sufix scheme to name the tarball,default is 'stg4'
  -r|-root </>           root directory for the backup, default is '/'
  -R|-restore [<dir>]    restore the stage4 backup from optional <dir>
  -q|-sdr                use sdr script to squash squashed directories
     -sqfsdir <dir>      squashed directory-ies root directory tree
     -sysdir <:dir>      system squashed dirs that require 'sdr -update' option
     -sqfsd <:dir>       local squashed dirs that do not require 'sdr -update'
  -d|-dir <dir>          stage4 dircteroy, location to store/save the tarball
  -s|-split <bytes>      size of byte to split the tarball archive
  -u|-usage              print this help/usage and exit
EOF
exit 0
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts b c: e+: g q p: r: s: d: t: u cipher: comp: dir: \
	exclude+: gpg sdr recipient: root: R:: restore:: split: sqfsdir: sqfsd+: \
	encrypt sign symmetric sysdir+: tarball: usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-comp]:=${opts[-c]:-gzip}}
: 	${opts[-prefix]:=${opts[-p]:-$(uname -s)-$(uname -m)-$(uname -r | cut -d- -f1)}}
:	${opts[-root]:=${opts[-r]:-/}}
:	${opts[-dir]:=${opts[-d]:-/mnt/sup/$(uname -m)}}
: 	${opts[-tarball]:=${opts[-t]:-stage4}}
opts[-tarball]=${opts[-dir]}/${opts[-prefix]:l}.${opts[-tarball]}
case ${opts[-comp]} in
	bzip2)	opts[-tarball]+=.tar.bz2;;
	xz) 	opts[-tarball]+=.tar.xz;;
	gzip) 	opts[-tarball]+=.tar.gz;;
	lzma)	opts[-tarball]+=.tar.lzma;;
	lzip)	opts[-tarball]+=.tar.lz;;
	lzop)	opts[-tarball]+=.tar.lzo;;
esac
setopt NULL_GLOB
build() {
print -P "%F{green}>>> building ${opts[-tarball]} stage4 tarball...%f"
pushd ${opts[-root]} || die "invalid root directory"
for file (mnt/* media home/* dev proc sys tmp run boot/*.i{mg,so} bootcp/*.i{mg,so} \
	var/{run,lock,pkg,src,bdir,tmp,*.tgz} lib*/rc/init.d/* lib*/splash/cache \
	${(pws,:,)opts[-exclude]} ${opts[-tarball]}) {
	if [[ -f ${file} ]] { opts[-opt]+=" --exclude=${file}"
	} elif [[ -d ${file} ]] { opts[-opt]+=" --exclude=${file}/*" }
}
if [[ -n ${(k)opts[-sdr]} ]] || [[ -n ${(k)opts[-q]} ]] {
	which sdr &>/dev/null || die "there's no sdr script in PATH"
:	${opts[-sqfsdir]:=sqfsd}
	if [[ -n ${opts[-sysdir]} ]] { sdr.zsh -r${opts[-sqfsdir]} -o0 -U -d${opts[-sysdir]} }
	if [[ -n ${opts[-sqfsd]} ]] { sdr.zsh -r${opts[-sqfsdir]} -o0  -d${opts[-sqfsd]} }
	for file (${opts[-sqfsdir]}/**/*.sfs) {
		opts[-opt]+=" --exclude=${file} --exclude=${file%.sfs}/rr/*"
		opts[-opt]+=" --exclude=${${file%.sfs}#${opts[-sqfsdir]}/}"
		rsync -avuR ${file} ${opts[-dir]}/${opts[-sqfsdir]:t}-${${opts[-prefix]}#*-}
	}
}
if [[ -n ${(k)opts[-boot]} ]] || [[ -n ${(k)opts[-b]} ]] {
	mount /boot
	sleep 3
	cp -aR /boot{,cp}
	umount /boot
	sleep 3 
}
opts[-opt]+=" --wildcards --create --absolute-names --${opts[-comp]} --verbose --totals"
if [[ -n ${(k)opts[-gpg]} ]] || [[ -n ${(k)opts[-g]} ]] { 
	for opt (cipher encrypt recipient sign symmetric) {
		if [[ -n ${(k)opts[-${opt}]} ]] { opts[-gpg]+=" --${opt} ${opts[-${opt}]:+${(qq)opts[-${opt}]}}" }
	}
	opts[-opt]+=" ${opts[-root]} | gpg ${opts[-gpg]} --output ${opts[-tarball]}.gpg"
	opts[-tarball]+=.gpg
} else { opts[-opt]+=" --file ${opts[-tarball]} ${opts[-root]}" }
tar ${=opts[-opt]} || die "failed to backup"
if [[ -n ${opts[-split]} ]] || [[ -n ${opts[-s]} ]] {
:	${opts[-s]:=${opts[-split]}}
	split --bytes=${opts[-s]} ${opts[-tarball]}, ${opts[-tarball]}.
}
print -P "%F{green}>>> successfuly built ${opts[-tarball],} stage4 tarball%f"
}
if [[ -n ${(k)opts[-restore]} ]] || [[ -n ${(k)opts[-R]} ]] {
	opts[-opt]="--extract --verbose --preserve --directory ${opts[-root]}"
	print -P "%F{green}>>> restoring ${opts[-tarball],} stage4 tarball...%f"
:	${opts[-restore]:-${opts[-R]:-${opts[-dir]}}}
	if [[ -n ${(k)opts[-sdr]} ]] || [[ -n ${(k)opts[-q]} ]] { rsync -avuR \
		${opts[-dir]}/./${opts[-sqfsdir]:t}-${opts[-prefix]} ${opts[-root]}/
	}
	if [[ -n ${(k)opts[-gpg]} ]] || [[ -n ${(k)opts[-g]} ]] { 
		opts[-gpg]="gpg --decrypt ${opts[-tarball]}.gpg |"
	} else { opts[-opt]+=" --file ${opts[-tarball]}"; opts[-gpg]= }
	${=opts[-gpg]} tar ${opts[-opt]} || die "failed to restore"
	if [[ -d /bootcp ]] { mount /boot && cp -aru /bootcp/* /boot/ }
	sed -e 's:^\#.*(.*)::g' -e 's:SUBSYSTEM.*".*"::g' -i /etc/udev/rules.d/*persistent-cd.rules \
		-i /etc/udev/rules.d/*persistent-net.rules
	print -P "%F{green}>>> successfuly restored ${opts[-tarball]} stage4 tarball%f"
} else { build }
rm -rf /bootcp
unset -v opts exclude
popd
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
