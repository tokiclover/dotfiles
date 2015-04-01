#!/bin/sh
#
# $Header: /etc/acpi/default.sh                          Exp $
# $Author: (c) 2012-2015 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)         Exp $
# $Version: 2015/02/14 21:09:26                          Exp $
#

log() {
	logger -p daemon.notice "acpi: $*"
}
#
# Unhandled Events helper
#
uhd() {
	log "event unhandled: $*"
}
#
# (Intel GPU) Brightness helper
#
btn() {
	local BTF=/sys/class/backlight/intel_backlight/brightness
	[ -e $BTF ] || return
	local BTM=$(cat /sys/class/backlight/intel_backlight/max_brightness)
	local BTN=$(cat $BTF) NEW=0 STP=24

	case "$1" in
		up)   NEW=$(($BTN + $STP));;
		down) NEW=$(($BTN - $STP));;
		*)    return;;
	esac
	if [ $NEW -lt 0 ]; then
		NEW=0
	elif [ $NEW -gt $BTM ]; then
		NEW=$BTM
	fi
	echo $NEW >$BTF
}

set $*
group=${1%/*}
action=${1#*/}
device=$2
id=$3
value=$4

[ -d /dev/snd ] && alsa=true || alsa=false
[ -d /dev/oss ] && oss=true  || oss=false
amixer="amixer -q set Master"
ossmix="ossmix -- vmix0-outvol"

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
			brightness*) btn ${action#brightness};;
			*) uhd $*;;
		esac
		;;
	*) uhd $*;;
esac

unset alsa oss amixer ossmix group action device id

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=4:ts=4:
#
