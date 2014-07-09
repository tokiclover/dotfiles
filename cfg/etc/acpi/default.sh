#!/bin/sh
# $Id: /etc/acpi/default.sh, 2014/07/07 13:22:59 -tclover Exp $

set $*
group=${1%%/*}
action=${1#*/}
device=$2
id=$3
value=$4

/etc/init.d/alsasound status >/dev/null 2>&1 && alsa=true
/etc/init.d/oss status >/dev/null 2>&1 && oss=true
amixer="amixer -q set Master"
ossmix="ossmix -- vmix0-outvol"

log() {
	logger -p daemon.notice "ACPI: $*"
}

unhandled() {
	log "event unhandled: $*"
}

case "$group" in
	ac_adapter)
		case "$value" in
			*0) log "switching to power.bat power profile"
					hprofile power.bat
				;;
			*1) log "switching to power.adp power profile"
					hprofile power.adp
				;;
			*)	unhandled $*;;
		esac
		;;
	battery)
		case "$value" in
			*0) log "switching to power.adp power profile"
					hprofile power.adp
				;;
			*1) log "switching to power.adp power profile"
						hprofile power.adp
				;;
			*) unhandled $*;;
		esac
		;;
	button)
		case "$action" in
			lid)
				case "$id" in
					close) pm-suspend --quirk-none;;
					*) unhandled $*;;
				esac
				;;
			power) telinit 0;;
			prog1) :;;
			mute) 
				$alsa && $amixer toggle;;
			volumeup) 
				$alsa && $amixer 3dB+
				$oss && $ossmix +3
				;;
			volumedown) 
				$alsa && $amixer 3dB-
				$oss && $ossmix -3
				;;
			*)	unhandled $*;;
		esac
		;;
	cd)
		case "$action" in
			play) :;;
			stop) :;;
			prev) :;;
			next) :;;
			*) unhandled $*;;
		esac
		;;
	jack)
		case "$id" in
			*plug) :;;
			*) unhandled $*;;
		esac
		;;
	*)	unhandled $*;;
esac

# vim:fenc=utf-8:ft=sh:ci:pi:sts=0:sw=2:ts=2:
