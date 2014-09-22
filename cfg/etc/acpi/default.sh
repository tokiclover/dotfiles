#!/bin/sh
#
# $Header: /etc/acpi/default.sh                          Exp $
# $Aythor: (c) 2012-2014 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)         Exp $
# $Version: 2014/09/09 21:09:26                          Exp $
#

log() {
	logger -p daemon.notice "acpi: $*"
}

uhd() {
	log "event unhandled: $*"
}

set $*
group=${1%/*}
action=${1#*/}
device=$2
id=$3
value=$4

[ -e /run/openrc/started/alsasound ] && alsa=true || alsa=false
[ -e /run/openrc/started/oss ]       && oss=true  || oss=false
amixer="amixer -q set Master"
ossmix="ossmix -- vmix0-outvol"

mpris=$(which mpris-remote 2>/dev/null)

case $group in
	ac_adapter)
		case $value in
			*0) hprofile power.bat;;
			*1) hprofile power.adp;;
			*) uhd $*;;
		esac
		;;
	battery)
		case $value in
			*0|*1) hprofile power.adp;;
			*) uhd $*;;
		esac
		;;
	button)
		case $action in
			lid)
				case "$id" in
					close) hibernate-ram;;
					open) hprofile power;;
					*) uhd $*;;
				esac
				;;
			power) shutdown -H now;;
			sleep) hibernate-ram;;
			mute) 
				$alsa && $amixer toggle;;
			volumeup) 
				$alsa && $amixer 3dB+
				$oss && $ossmix +3;;
			volumedown) 
				$alsa && $amixer 3dB-
				$oss && $ossmix -3;;
			*) uhd $*;;
		esac
		;;
	cd)
		case $action in
			play|stop|next|prev) :;;
			*) uhd $*;;
		esac
		;;
	jack)
		case $id in
			*plug) :;;
			*) uhd $*;;
		esac
		;;
	video)
		case $action in
			displayoff) :;;
			*) uhd $*;;
		esac
		;;
	*) uhd $*;;
esac

unset alsa oss amixer ossmix group action device id

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
