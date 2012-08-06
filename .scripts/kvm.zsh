#!/bin/zsh
# $Id: ~/.scripts/kvm.zsh, 2012/08/06 11:44:39 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS...]
  -c|-cmd" -hda /dev/sda"  append extra kvm options to cmdline
  -n|-net eth0             use external/internal iface for bridging
  -r|-route 196.168.1.0    use 'ip' as network route, else use dhcpcd
  -g|-gw 196.168.1.1       use 'ip' as network gateway, else use dhcpd
  -b|-bif br0              use br0 interface for bridging
  -i|-bip 196.168.1.120    use 'ip' for bif interface, else use dhcpd
  -N|-bmsk 255.255.255.0   use 'netmask' for bif interface, else use dhcpd
  -t|-tap tap0             use 'iface' interface for tun interface
  -m|-mem 1024             use max '1024' memory instead of 2048
  -o|-opt '--mpd --cups'   ipr cmdline options, passed directly to ipr
  -u|-usage                print this help/usage and exit
EOF
exit $?
}
error() { print -P "%B%F{red}*%b%f $@" }
die()   { error "%F{yellow}%1x:%U${(%):-%I}%u:%f $@"; exit 1 }
zmodload zsh/zutil
zparseopts -E -D -K -A opts c+: cmd+: g: gw: n: net: b: bif: t: tap: \
	m: mem: N: bmsk: i: bip: o+: opt+: r: route: u usage || usage
if [[ -n ${(k)opts[-u]} ]] || [[ -n ${(k)opts[-usage]} ]] { usage }
if [[ -z $opts[*] ]] { typeset -A opts }
export PATH=$PATH:/usr/sbin:/sbin SDL_VIDEO_X11_DGAMOUSE=0
if [[ ${$(uname -p)[(w)1]} = Intel* ]] { opts[-mod]=intel
} elif [[ ${$(uname -p)[(w)1]} = AMD* ]] { opts[-mod]=amd }
modprobe -a vmwgfx kvm{,-$opts[-mod]} tun 2>/dev/null
:	${opts[-tap]:=$opts[-t]}
:	${opts[-mem]:=${opts[-m]:-1024}}
if [[ -n $opts[-net] ]] || [[ -n $opts[-n] ]] {
:	${opts[-net]:=$opts[-n]}
:	${opts[-bif]:=${opts[-b]:-br0}}
	if [[ -n $opts[-bif] ]] {
:		${opts[-bip]:=${opts[-I]:-}}
:		${opts[-brnetmast]:-${opts[-N]:-}}
	}
:	${opts[-route]:=${opts[-r]:-}}
:	${opts[-gw]:=${opts[-g]:-}}
	brctl addbr $opts[-bif] || die
	brctl addif $opts[-bif] $opts[-net] || die
	if [[ -n $opts[-bip] ]] [[ -n $opts[-bmsk] ]] {
		ifconfig $opts[-bif] $opts[-bip] netmask $opts[-bmsk] up
		route add -net $opts[-bip] netmask $opts[-bip] $opts[-bif]
		route add default gw $opts[-gw] $opts[-bif]
	} else { ifconfig $opts[-bif] up && dhcpcd $opts[-bif] || die }
	tunctl -b -g kvm
	ifconfig $opts[-tap] up || die
	brctl addif $opts[-bif] $opts[-tap]
	ipr -4 $opts[-o] opts[-opt] -e$opts[-bif]
	iptables -I FORWARD     -m physdev --physdev-is-bridged -j ACCEPT
	iptables -I POSTROUTING -m physdev --physdev-is-bridged -j ACCEPT
}
qemu-kvm ${=opts[-tap]:+-net nic -net tap,ifname=$opts[-tap],script=no} -vga std \
	-m $opts[-mem] ${=opts[-cmd]} ${=opts[-c]} -usbdevice tablet -boot d
unset -v opts
