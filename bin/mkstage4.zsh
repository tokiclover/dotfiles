#!/bin/zsh
#
# $Header: ~/bin/mkstage4.zsh                              Exp $
# $Author: -tclover <tokiclover@gmail.com>                 Exp $
# $Version: 2.0 2015/07/26 13:08:56                        Exp $
# $License: MIT (or 2-clause/new/simplified BSD)           Exp $
#

function usage {
  cat <<-EOH
  usage: ${(%):-%1x} [OPTIONS]

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
exit
}

function error {
	print -P "%B%F{red}*%b %1x:%f $@" >&2
}

function die {
	local ret=$?
	error $argv
	exit $ret
}

typeset -A opts
typeset -a exclude gpg opt
opt=(
	"-o" "?C:c:d:ehqR::r:Ss:t:X:"
	"-l" "exclude:,cipher:,compressor:,dir:,encrypt,gpg,help"
	"-l" "sdr,sdr-root:,sdr-dir:,sdr-sys:,root,tarball"
	"-l" "recipient:,symmetric,sign,restore"
	"-n" "${(%):-%1x}"
)

opt=($(getopt ${opt} -- ${argv} || usage))
eval set -- ${opt}
exclude=()

for (( ; $# > 0; ))
	case $1 {
		(-q|--sdr)
			(( $+commands[sdr] )) && sdr=$commands[sdr] || sdr=$HOME/bin/sdr.zsh
			[[ -x $sdr ]] || die
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
			gpg+=(--recipient $2)
			shift 2;;
		(-g|--gpg)
			gpg=(gpg $gpg)
			shift;;
		(-X|--exclude)
			exclude+=(${2//:/ })
			shift 2;;
		(--symmetric)
			gpg+=(--symmetric)
			shift;;
		(-p|--prefix)
			opts[-prefix]=$2
			shift 2;;
		(-d|--dir)
			opts[-dir]=$2
			shift 2;;
		(-c|--compressor)
			opts[-compressor]=$2
			shift 2;;
		(--sdr-dir)
			opts[-sdr-dir]+=:$2
			shift 2;;
		(-s|--split)
			opts[-split]=$2
			shift 2;;
		(-t|--tarball)
			opts[-tarball]=$2
			shift 2;;
		(--sdr-root)
			opts[-sdr-root]=$2
			shift 2;;
		--sdr-sys)
			opts[-sdr-sys]+=:$2
			shift 2;;
		(-r|--root)
			opts[-root]=$2
			shift 2;;
		(-R|--restore)
			opts[-restore]=$2
			shift 2;;
		(--)
			shift
			break;;
		(-?|-h|--help|*) usage;;
	}

opt=(${@})
:	${opts[-compressor]:=gzip}
: ${opts[-prefix]:=$(uname -s)-$(uname -m)-$(uname -r | cut -d- -f1)}
:	${opts[-root]:=/}
:	${opts[-dir]:=/mnt/bak/$(uname -m)}
: ${opts[-tarball]:=stage4}
:	${opts[-sdr-root]:=/squash}

opts[-tarball]=${opts[-dir]}/${opts[-prefix]:l}-${opts[-tarball]}
case ${opts[-compressor]} in
	bzip2)	opts[-tarball]+=.tar.bz2;;
	xz) 	opts[-tarball]+=.tar.xz;;
	gzip) 	opts[-tarball]+=.tar.gz;;
	lzma)	opts[-tarball]+=.tar.lzma;;
	lzip)	opts[-tarball]+=.tar.lz;;
	lzop)	opts[-tarball]+=.tar.lzo;;
	lz4)	opts[tarball]+=.tar.lz4;;
esac

setopt NULL_GLOB
setopt EXTENDED_GLOB

function mkstage {

print -P "%F{green}>>> building ${opts[-tarball]} stage4 tarball...%f"
pushd ${opts[-root]} || die "invalid root directory"

exclude+=(
	$opts[-tarball]
	boot/**/*.i{mg,so}
	{mnt,media,home}
	{dev,proc,sys,tmp,run}
	var/{run,lock,pkg,src,tmp}
)

for file (${exclude}) opt+=(--exclude=${file})

if (( ${+sdr} )) {
	if (( ${+opts[-sdr-sys]} )) {
		${sdr} -q${opts[-sdr-root]} -o0 -u ${opts[-sdr-sys]}
	}
	if (( ${+opts[-squashd]} )) {
		${sdr} -q${opts[-sdr-root]} -o0    ${opts[-sdr-dir]}
	}
	for file (${opts[-sdr-root]}/**/*.squashfs) {
		opt+=(--exclude=${file} --exclude=${file%.*}/rr)
		rsync -avuR ${file} ${opts[-dir]}/${opts[-sdr-root]:t}-${${opts[-prefix]}#*-}
	}
}

opt+=(--create -I ${opts[-compressor]} --verbose --totals)

if (( ${+opts[gpg]} )) { 
	for o (cipher encrypt recipient sign symmetric) {
		(( ${+opts[-${o}]} )) && opts[-gpg]+=" --${o} ${opts[-${o}]}"
	}
	opts[-tarball]+=.gpg
	opt+=(${opts[-root]} '|' gpg ${opts[-gpg]} --output ${opts[-tarball]})
} else {
	opt+=(--file ${opts[-tarball]} ${opts[-root]})
}

eval tar "${opt[@]}" || die "failed to backup"

if (( ${+opts[-split]} )) {
	split --bytes=${opts[-split]} ${opts[-tarball]}, ${opts[-tarball]}.
}

print -P "%F{green}>>> successfuly built ${opts[-tarball]:l} stage4 tarball%f"

}

if (( ${+opts[-restore]} )) {
	opts[-opt]="--extract --verbose --preserve --directory ${opts[-root]}"
	print -P "%F{green}>>> restoring ${opts[-tarball],} stage4 tarball...%f"
:	${opts[-restore]:-${opts[-dir]}}

	if (( ${+sdr} )) {
		rsync -avuR ${opts[-dir]}/./${opts[-sdr-root]:t}-${opts[-prefix]} ${opts[-root]}/
	}

	if (( ${+opts[-gpg]} )) { 
		opts[-gpg]="gpg --decrypt ${opts[-tarball]}.gpg |"
	} else {
		opt+=(--file ${opts[-tarball]})
		opts[-gpg]=
	}

	eval ${=opts[-gpg]} tar ${opt} || die "failed to restore"

	print >/etc/udev/rules.d/*persistent-cd.rules \
	print >/etc/udev/rules.d/*persistent-net.rules

	print -P "%F{green}>>> successfuly restored ${opts[-tarball]} stage4 tarball%f"
	exit
}

mkstage

unset -v opts exclude
popd

#
# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
#
