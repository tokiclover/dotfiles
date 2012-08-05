#!/bin/zsh
# $Id: ~/.scripts/kvm.zsh, 2012/08/05 22:42:35 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -c|-cmd" -cdrom /dev/cdrom"   append extra kvm options to cmdline
  -n|-net eth0                  use external/internal iface for bridging
  -r|-route 196.168.1.0         use 'ip' as network route, else use dhcpcd
  -g|-gw 196.168.1.1            use 'ip' as network gateway, else use dhcpd
  -b|-brif br0                  use br0 interface for bridging
  -i|-brip 196.168.1.120        use 'ip' for brif interface, else use dhcpd
  -n|-brnetmask 255.255.255.0   use 'netmask' for brif interface, else use dhcpd
  -t|-tap tap0                  use 'iface' interface for tun interface
  -m|-mem 1024                  use max '1024' memory instead of 2048
  -u|-usage                     print this help/usage and exit
EOF
exit $?
}
error() { print -P "%B%F{red}*%b%f $@" }
die()   { error "%F{yellow}%1x:%U${(%):-%I}%u:%f $@"; exit 1 }
zmodload zsh/zutil
zparseopts -E -D -K -A opts c+: cmd+: g:: gw:: n: net: b:: brif:: t:: tap:: \
	m: mem: n:: brnetmask:: brip:: r:: route:: u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z ${opts[*]} ]] { typeset -A opts }
export PATH=$PATH:/usr/sbin:/sbin SDL_VIDEO_X11_DGAMOUSE=0
if [[ ${$(uname -p)[(w)1]} = Intel* ]] { opts[-mod]=-intel
} elif [[ ${$(uname -p)[(w)1]} = AMD* ]] { opts[-mod]=-amd }
modprobe -a vmwgfx kvm{,${opts[-mod]}} tun 2>/dev/null
:	${opts[-tap]:=${opts[-t]}}
:	${opts[-mem]:=${opts[-m]:-1024}}
if [[ -n ${opts[-net]} ]] || [[ -n ${opts[-n]} ]] {
:	${opts[-net]:=${opts[-n]}}
:	${opts[-brif]:=${opts[-b]:-br0}}
	if [[ -n ${opts[-brif]} ]] {
:		${opts[-brip]:=${opts[-I]:-}}
:		${opts[-brnetmast]:-${opts[-N]:-}}
	}
:	${opts[-route]:=${opts[-r]:-}}
:	${opts[-gw]:=${opts[-g]:-}}
	brctl addbr ${opts[-brif]} || die
	brctl addif ${opts[-brif]} ${opts[-net]} || die
	if [[ -n ${opts[-brip]} ]] {
		ifconfig ${opts[-brif]} ${opts[-brip]} netmask ${opts[-brnetmask]} up
		route add -net ${opts[-root]} netmask ${opts[-brip]} ${opts[-brif]}
		route add default gw ${opts[-gw]} ${opts[-brif]}
	} else { ifconfig ${opts[-brif]} up && dhcpcd ${opts[-brif]} || die }
	tunctl -b -g kvm
	ifconfig ${opts[-tap]} up || die
	brctl addif ${opts[-brif]} ${opts[-tap]}
	iptables -I FORWARD     -m physdev --physdev-is-bridged -j ACCEPT
	iptables -I POSTROUTING -m physdev --physdev-is-bridged -j ACCEPT
}
qemu-kvm ${=opts[-tap]:+-net nic -net tap,ifname=${opts[-tap]},script=no} -vga std \
	-m ${opts[-mem]} ${=opts[-cmd]} ${=opts[-c]} -usbdevice tablet -boot d
unset -v opts
