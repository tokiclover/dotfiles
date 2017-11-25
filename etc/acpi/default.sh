#!/bin/sh
#
# $Header: /etc/acpi/default.sh                          Exp $
# $Author: (c) 2012-2015 -tclover <tokiclover@gmail.com> Exp $
# $License: MIT (or 2-clause/new/simplified BSD)         Exp $
# $Version: 2015/02/14 21:09:26                          Exp $
#

log_event() {
	logger -p daemon.notice "acpi: $*"
}
#
# Unhandled Events helper
#
unhandled_event() {
	log_event "event unhandled: $*"
}
#
# (Intel GPU) Brightness helper
#
brightness() {
	local cur FILE max step
	FILE=/sys/class/backlight/intel_backlight/brightness
	[ -e $FILE ] || return
	cur="$(cat $FILE)" max="$(cat ${FILE%/*}/max_brightness)"
	step="$(($max / 20 ))"

	case "$1" in
		(*up)   new="$(($cur + $step))";;
		(*down) new="$(($cur - $step))";;
		(*)    return;;
	esac
	if [ "$new" -lt 0 ]; then
		new=0
	elif [ "$new" -gt "$max" ]; then
		new="$max"
	fi
	echo "$new" >$FILE
}

set $*
group="${1%/*}" action="${1#*/}"
device="$2" id="$3" value="$4"

[ -d /dev/snd ] && alsa=true || alsa=false
[ -d /dev/oss ] && oss=true  || oss=false
amixer="/usr/bin/amixer -q set Master"
ossmix="/usr/bin/ossmix -- vmix0-outvol"

case "$group" in
	(ac_adapter)
		case "$value" in
			(*0) hprofile power.bat ;;
			(*1) hprofile power.adp ;;
			(*) unhandled_event "$@";;
		esac
		;;
	(battery)
		case "$value" in
			(*[01]) hprofile power.adp;;
			(*) unhandled_event "$@"  ;;
		esac
		;;
	button)
		case "$action" in
			(lid)
				case "$id" in
					(close) hibernate-ram   ;;
					(open) hprofile power   ;;
					(*) unhandled_event "$@";;
				esac
				;;
			(power)
				if [ $(pgrep runit) = 1 ]; then
					/lib/sv/bin/sv-shutdown -0
				else
					/sbin/shutdown -H now
				fi
				;;
			(sleep) /usr/sbin/hibernate-ram;;
			(*mute) 
				$alsa && $amixer toggle;;
			(volumeup) 
				$alsa && $amixer 3dB+ ||
				($oss && $ossmix +3);;
			(volumedown) 
				$alsa && $amixer 3dB- ||
				($oss && $ossmix -3);;
			(*) unhandled_event "$@";;
		esac
		;;
	(cd)
		case "$action" in
			(pause|play)     /usr/bin/mpc "toggle" ;;
			(stop|next|prev) /usr/bin/mpc "$action";;
			(*) unhandled_event "$@";;
		esac
		;;
	(jack)
		case "$id" in
			(*plug) ;;
			(*) unhandled_event "$@";;
		esac
		;;
	(video)
		case "$action" in
			(displayoff) ;;
			(brightness*) brightness "$action";;
			(*) unhandled_event "$@";;
		esac
		;;
	(*) unhandled_event "$@";;
esac
unset alsa oss amixer ossmix group action device id

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
