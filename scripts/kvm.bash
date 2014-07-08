#!/bin/zsh
# $Id: ~/scripts/kvm.bash, 2014/07/07 11:44:37 -tclover Exp $
usage() {
  cat <<-EOF
  usage: ${(%):-%1x} [OPTIONS]
  -c, --cmd" -hda /dev/sda"  append extra kvm options to cmdline
  -n, --net eth0             use external/internal iface for bridging
  -r, --route 196.168.1.0    use 'ip' as network route, else use dhcpcd
  -g, --gw 196.168.1.1       use 'ip' as network gateway, else use dhcpd
  -b, --bif br0              use br0 interface for bridging
  -i, --bip 196.168.1.120    use 'ip' for brif interface, else use dhcpd
  -N, --bmsk 255.255.255.0   use 'netmask' for brif interface, else use dhcpd
  -t, --tap tap0             use 'iface' interface for tun interface
  -m, --mem 1024             use max '1024' memory instead of 2048
  -o, --opt '--mpd --cups'   ipr cmdline options, passed directly to ipr
  -u, --usage                print this help/usage and exit
EOF
exit $?
}
error() { echo -ne "\e[1;31m* \e[0m$@\n"; }
die()   { error "$@"; exit 1; }
opt=$(getopt -o c+:g:b:t:m::n:N:i:o+:r:u -l bif:,bip:,bmsk:,cmd+:,gw:
	  -l mem::,net:,opt+:,route:,tap:,usage -n ${0##*/} -- "$@" || usage)
eval set -- "$opt"
declare -A opts
while [[ $# > 0 ]]; do
	case $1 in
		-g|--gw) opts[-gw]="$2"; shift 2;;
		-i|--bip) opts[-bip]="$2"; shift 2;;
		-b|--bif) opts[-bif]="${2:-br0}"; shift 2;;
		-N|--bmsk) opts[-msk]="$2"; shift 2;;
		-c|--cmd) opts[-cmd]+=" $2"; shift 2;;
		-n|--net) opts[-net]="$2"; shift 2;;
		-t|--tap) opts[-tap]="${2:-tap0}"; shift 2;;
		-m|--mem) opts[-mem]="${2:-1024}"; shift 2;;
		-o|--opt) opts[-opt]+=" $2"; shift 2;;
		--) shift; break;;
		-u|--usage|*) usage;;
	esac
done
export PATH=$PATH:/usr/sbin:/sbin SDL_VIDEO_X11_DGAMOUSE=0
if [[ "$(uname -p)" =~ Intel ]]; then opts[-mod]=intel
elif [[ "$(uname -p)" =~ AMD ]]; then opts[-mod]=amd; fi
modprobe -a vmwgfx kvm{,-${opts[-mod]}} tun 2>/dev/null
if [[ -n" ${opts[-net]}" ]]; then
	brctl addbr ${opts[-bif]} || die
	brctl addif ${opts[-bif]} ${opts[-net]} || die
	if [[ -n "${opts[-bip]}" ]]; then
		ifconfig ${opts[-bif]} ${opts[-bip]} netmask ${opts[-brn]} up
		route add -net ${opts[bip]} netmask ${opts[-bip]} ${opts[-bif]}
		route add default gw ${opts[-gw]} ${opts[-bif]}
	else ifconfig ${opts[-bif]} up && dhcpcd ${opts[-bif]} || die; fi
	tunctl -b -g kvm
	ifconfig ${opts[-tap]} up || die
	brctl addif ${opts[-bif]} ${opts[-tap]}
	ipr -4 ${opts[-opt]} -e${opts[-bif]}
	iptables -I FORWARD     -m physdev --physdev-is-bridged -j ACCEPT
	iptables -I POSTROUTING -m physdev --physdev-is-bridged -j ACCEPT
fi
[ -n "${opts[-tap]}" ] && opts[-tap]="-net nic,tap,ifname=${opts[-tap]},script=no"
qemu-kvm ${opts[-tap]} -vga std -m ${opts[-mem]} ${opts[-cmd]} -usbdevice tablet -boot d
unset -v opt opts
