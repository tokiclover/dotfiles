#!/bin/zsh
# $Id: ~/.scripts/kvm.zsh , 2012/05/05 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -c|-cmd" -cdrom /dev/cdrom"   append extra kvm options to cmdline
  -n|-net eth0                  use external/internal iface for bridging
  -r|-route 196.168.1.0         use 'ip' as network route
  -g|-gw 196.168.1.1            use 'ip' as network gateway
  -b|-br-if br0                 use br0 interface for bridging
  -I|-br-ip 196.168.1.120       use 'ip' for br-if interface
  -N|-br-netmask 255.255.255.0  use 'netmask' for br-if interface
  -t|-tap tap0                  use 'iface' interface for tun
  -m|-mem 1024                  use max '1024' memory instead of 2048
  -u|-usage                     print this help/usage and exit
EOF
exit $?
}
error() { print -P "%B%F{red}*%b%f $@" }
die()   { error "%F{yellow}%1x:%U${(%):-%I}%u:%f $@"; exit 1 }
zmodload zsh/zutil
zparseopts -E -D -K -A opts c+: cmd+: g:: gw:: n: net: b:: br-if:: t:: tap:: \
	m: mem: I:: br-netmask:: br-ip:: r:: route:: u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
export PATH=$PATH:/usr/sbin:/sbin
:	${opts[-tap]:=${opts[-t]}}
if [[ -n ${opts[-net]} ]] || [[ -n ${opts[-n]} ]] {
:	${opts[-net]:=${opts[-n]}}
:	${opts[-br-if]:=${opts[-b]:-br0}}
	if [[ -n ${opts[-br-if]} ]] {
:		${opts[-br-ip]:=${opts[-I]:-192.168.1.120}}
:		${opts[-br-netmast]:-${opts[-N]:-255.255.255.0}}
	}
:	${opts[-route]:=${opts[-r]:-192.168.1.0}}
:	${opts[-gw]:=${opts[-g]:-192.168.1.1}}
	brctl addbr ${opts[-br-if]} || die
	brctl addif ${opts[-br-if]} ${opts[-net]} || die
	ifconfig ${opts[-br-if]} ${opts[-br-ip]} netmask ${opts[-br-netmask]} up || die
	route add -net ${opts[-root]} netmask ${opts[-br-ip]} ${opts[-br-if]} || die
	route add default gw ${opts[-gw]} ${opts[-br-if]} || die
	modprobe tun &> /dev/null
	tunctl -b -g kvm || die
	ifconfig ${opts[-tap]} up || die
	brctl addif ${opts[-br-if]} ${opts[-tap]} || die
	iptables -I INPUT -i ${opts[-br-if]} -j ACCEPT || die
}
export SDL_VIDEO_X11_DGAMOUSE=0
if [[ ${$(uname -p)[(w)1]} =~ Intel ]] { opts[-mod]=-intel
} elif [[ ${$(uname -p)[(w)1]} =~ AMD ]] { opts[-mod]=-amd }
modprobe -a kvm{,${opts[-mod]}} &> /dev/null
qemu-kvm ${opts[-tap]:+-net nic -net tap,ifname=${opts[-tap]},script=no} -vga std \
	-m ${opts[-mem]:-2048} -usbdevice tablet -boot d ${=opts[-cmd]} ${=opts[-c]}
unset -v opts
