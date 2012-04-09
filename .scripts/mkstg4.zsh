#!/bin/zsh
# $Id: $HOME/.scripts/mkstg4.zsh,v 1.0 2012/04/08 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -b|--boot            whether to backup /boot to /bootcp
  -c|--comp            compression command to use, default is 'gzip'
  -e|--exclude <files> files/dirs to exclude from the tarball archive
  -g|--gpg             encrypt the tarball, require -pubkey or -symmetric
     --cipher <aes>    cipher to use when encypting the tarball archive
     --pubkey <id>     encrypt the final tarball using <id> public key
     --symmetric       encrypt using a signed symmetricly encrypted key
     --pass <1>        number of pass to encrypt the tarball when using -S
  -p|--prefix <3.3>    prefix scheme to name the tarball, default is $(uname -r | cut -c-3).
  -t|--tarball <stg4>  suffix scheme to name the tarball,default is 'stg4'
  -r|--root </>        root directory for the backup, default is '/'
  -q|--sdr             use sdr script to squash squashed directories
     --sqfsdir <dir>   squashed directory-ies root directory tree
     --sysdir <:dir>   system squashed dirs that require 'sdr --update' option
     --sqfsd <:dir>    local squashed dirs that do not require 'sdr --update'
  -d|--dir <dir>       stage4 dircteroy, location to store/save the tarball
  -l|--split <bytes>   size of byte to split the tarball archive
  -u|--usage           print this help/usage and exit
EOF
}
error() { print -P "%B%F{red}*%b%f $@"; }
die()   { error $@; exit 1; }
alias die='die "%F{yellow}%1x:%U${(%):-%I}%u:%f" $@'
zmodload zsh/zutil
zparseopts -E -D -K -A opts b c: e: g q p: r: s: d: t: u -cipher: -comp: -dir: \
	-exclude: -gpg -sdr -pass: -pubkey: -root: -split: -sqfsdir: -sqfsd+: \
	-symmetric -sysdir+: -tarball: -usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[--usage]} ]] { usage; exit 0 }
if [[ -z ${opts[*]} ]] { typeset -A opts }
:	${opts[-c]:=${opts[--comp]:-gzip}}
: 	${opts[-p]:=${opts[--prefix]:-$(uname -r | cut -c-3)}}
:	${opts[-r]:=${opts[--root]:-/}}
:	${opts[-d]:=${opts[--dir]:-/mnt/sup/bik}}
: 	${opts[-t]:=${opts[--tarball]:-.stg4}}
opts[-t]=${opts[-d]}/${opts[-p]}.${opts[-t]}
print -- $opts[-p]:$opts[-t]
exit 0
case ${opts[-c]} in
	bzip2)	opts[-t]+=.tbz2;;
	xz) 	opts[-t]+=.txz;;
	gzip) 	opts[-t]+=.tgz;;
	lzma)	opts[-t]+=.tlzma;;
	lzip)	opts[-tl]+=.tlz;;
	lzop)	opts[-t]+=.tlzo;;
esac
setopt NULL_GLOB
print -P "%F{green}>>> building ${opts[-t]} stage4 tarball...%f"
cd ${opts[-r]} || die "invalid root directory"
for file (mnt/* media home dev proc sys tmp run boot/*.i{mg,so} bootcp/*.i{mg,so} 
	var/{{,local/}portage,run,lock,pkg,dst,blddir,.*.tgz,tmp} lib*/rc/init.d *.swp 
	lib*/splash/cache usr/{,local/}portage ${opts[-t]}) { opts[-o]+=" --exclude=$file" }
if [[ -n ${(k)opts[--sdr]} ]] || [[ -n ${(k)opts[-q]} ]] {
	which sdr &> /dev/null || die "there's no sdr script in PATH"
:	${opts[--sqfsdir]:=sqfsd}
	if [[ -n ${opts[--sysdir]} ]] { sdr -r${opts[--sqfsdir]} -o0 -U -d${opts[--sysdir]} }
	if [[ -n ${opts[--sqfsd]} ]] { sdr -r${opts[--sqfsdir]} -o0  -d${opts[--sqfsd]} }
	rsync -avuR ${opts[-r]}/${opts[--sqfsdir]}/./{*,*/*,*/*/*}.sfs \
		${opts[-d]}/${opts[--sqfsdir]:t}-${opts[-p]}
	for file (usr opt var/{db,cache/edb,lib/layman} ${opts[--sqfsdir]}/{*,*/*,*/*/*}.sfs 
		${opts[--sqfsdir]}/{*,*/*,*/*/*}/ro) { opts[-o]+=" --exclude=$file"	}
}
if [[ -n ${(k)opts[--boot]} ]] || [[ -n ${(k)opts[-b]} ]] {
	mount /boot
	sleep 3
	cp -aR /boot /bootcp
	umount /boot
	sleep 3 
}
opts[-o]+=" --create --absolute-names --${opts[-c]} --verbose --totals --file"
tar ${=opts[-o]} ${opts[-t]} ${opts[-r]}
if [[ -n ${(k)opts[--gpg]} ]] || [[ -n ${(k)opts[-g]} ]] {
	cd ${opts[-d]}
 	if [[ -n ${(k)opts[--symmetric]} ]] {
		echo ${opts[--pass]:-1} | gpg --encrypt --batch --cipher-algo ${opts[--cipher]:-aes} \
			--passphrase-fd 0 --symmetric --output ${opts[-t]}.gpg ${opts[-t]}
	} else { gpg --encrypt --batch --recipient ${opts[--pubkey]} --cipher-algo \
			${opts[--cipher]:-aes} --output ${opts[-t]}.gpg ${opts[-t]}
	}
	rm ${opts[-t]}
	opts[-t]+=.gpg
}
if [[ -n ${opts[--split]} ]] || [[ -n ${opts[-s]} ]] {
:	${opts[-s]:=${opts[--split]}}
	split --bytes=${opts[-s]} ${opts[-t]} ${opts[-t]}.
}
rm -rf /bootcp
print -P "%F{green}>>> successfuly built ${opts[-t]} stage4 tarball%f"
unset opts
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
