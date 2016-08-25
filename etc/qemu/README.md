Reference
---------

[Networking](http://www.linux-kvm.org/page/Networking)
[QEMU-Networking](https://en.wikibooks.org/wiki/QEMU/Networking)

Concept
-------

[virtual networking](http://wiki.libvirt.org/page/VirtualNetworking)

Usage
-----

Setup a virtual (private) network which can be used with [IPtables][2] and DHCP;
which means private network are isolated from each other; and then,
routing is necessary like real LAN network similar to VMware network
*vmnet[0-8]*:

- Adding DNS server for each subnet using [dnsmasq][5] DHCP and DNS serer:

  + add `name_servers=172.16.x.1 `for persistent configuration in `/etc/resolvconf.conf`;
  + add 172.16.x.1 to /etc/resolv.conf to not have to restart [dnsmasq][5];
 *x* is usually *1i* *i* the virtual network number e.g. 10 for vnet0.

  Use [dnsmasq][5] as a DHCP server for virtual network which have access to
outside world; or ISC [dhcpd][4] for private network by supplying
`--dhcp=dnsmask|dhcpd` command line argument; and then
add _172.16.10.1_ if _vnet0_ is configured to run a DNS and DHCP server.


- And then setting up iptables rules for internal interfaces and NAT
is required as well. See, [~/bin/ipr](bin/ipr) for a complete statefull firewall
setup, e.g. `~/bin/ipr -e eth0 -d -i vnet1,vnet2,vnet3` for exmaple.

- And finaly use `ether=/etc/qemu/vnet$i/ether.conf` hardware MAC address to provide
`mac=$ether_$j` to qemu for persistent network and unique hardware address.
Need hardware address for persistent network? `qemu-vlan --br=vnet$i -n4 [--vde] --macaddr`
would generate hardware address (`--vde` multiply  by 32, default factor is 8)
to generate that configuration file.
Of course, the main configuration file--`/etc/qemu/$br/$br.conf`--can be used to
configure the virtual LAN; or extra DHCP server options can be added to
`${ether%/*}/dhcp.conf` for [dnsmasq][5] or `${ether%/*}/dhcpd.conf` for [dhcpcd][3].
See [vnet1/vnet1.conf](vnet1/vnet1.conf) and [vnet1/ether.conf](vnet1/ether.conf)
for a pratical example.

- Ports redirection for (non bridged) virtual network can be done using
iptables's **DNAT** and **SNAT** targets. **PREROUTING** and **POSTROUTING** chains are supported
for VMs providing web services. Just set up **{PRE,POST}ROUTING_RULES** in the
configuration file. The format is the following:

**PREROUTING_RULSES**="interface,proto,port,address:port[/4|6] interface,proto,..."
**POSTROUTING_RULSES**="interface,proto,port,address:port[/4|6] interface,proto,..."

    interface   : external network interface to use for external traffic
    proto       : network protocol to use for redirect (tcp, udp,...)
    port        : incoming port on the host machine to use
    address:port: network address and port of the guest to send traffic to
    /4 or /6    : redirect IPv4 or IPv6 traffic (default to IPv4)

which are translated to the following rules for example:

    $iptables -A PREROUTING  -t nat -d 192.168.x.y --dport 8080  -j DNAT --to-destination 172.16.u.v:80
    $iptables -A POSTROUTING -t nat -s 172.16.u.v  --sport 80    -j SNAT --to-source   192.168.x.y:8080

Examples
--------

#### NAT virtual network

    % /etc/qemu/qemu-vlan --br=vnet3 -n4 --dhcp=dnsmasq --start

To setup a virtual LAN with dnsmasq as DHCP and DNS server (4 interfaces)
VMs will not be reachable from the outside world unless *[DS]SNAT* routing
is used to redirect ports to VMs for particular services; or else, use a
bridged virtual LAN by appending `--if=eth0` argument... and then switch
dnsmasq for a DHCP client (dhclient or dhcpcd) instead of a server.

#### host-only private network

    % /etc/qemu/qemu-vlan --br=vnet2 -n8 --dhcp=dhcpd --start

To setup a private LAN with ISC [dhcpd][4] as DHCP server (8 interfaces)
with no access to outside world; and then use:

    `-netdev tap,id=vnet2_1,ifname=vnet2_1,script=no,downscript=no'

**WARNING: DO NOT USE** `-netdev tap,...,fd=$(</sys/class/net/vnet2_1/iflink)`
because it deos not work at all as normal user or root; use the previous
construct instead.

**NOTE:** No privileged users cannot safely use the first variant without an issue
because qemu would fail to open `/dev/net/tun`; the second form is problematic
because the tap device is not connected to the right NIC.
So, make sure to use `-device ....,netde=vnet2_1 -netdev ...,id=vnet2_1,...` or
similar settings when necessary.

**SOLUTION: RUN VMs as SUPERUSER!!**

#### bridged network

    % /etc/qemu/qemu-vlan --br=vnet2 -n8 --if=eth0 --start

For a bridged virtual LAN (no need for DHCP server for a bridged setup... however
a DHCP client can be used to configure the bridge)
and then use: `-netdev bridge,br=vnet2,id=vnet2_4`.
See `/etc/sysctl.d/10-disable-firewall-on-bridge.conf` if each guest provide
a firewall.

#### NAT network with VDE switches

    % /etc/qemu/qemu-vlan --br=vnet3 -n4 --vde --dhcp=dnsmasq --start

To setup a virtual LAN with a [VDE][1] switch with a DHCP/DNS server 128 VMs
can be connected to vitual LAN with defaults settings; and then use:

    -netdev vde,id=vnet3_2,sock=/var/run/vnet3_2.vde,group=qemu,mode=660

VDE connection sockets are created like `/var/run/vnet3_$i.vde` for each instance
or per tap device; so using any instance is easy and can be scripted.

#### qemu-if{up,down} helper

    % /etc/qemu/qemu-if(up|down) tap$i

Or else, this script can be setuid and called as *qemu-if{up,down}* and called
with a tap interface name with the default switch (bridge) set to vnet3.
The switched would be created if it does not exist, so just append
`script=/etc/qemu/qemu-ifup,downscript=/etc/qemu/qemu-ifdown` argument.

**WARNING:** `-netdev tap,...,script=/etc/qemu/qemu-ifup,downscript=/etc/qemu/qemu-ifdown`
is not that usable because the tap may not be connected to the right NIC!!!

**WARNING:** Do not forget to use as many `-device e1000,mac=$ether_2,netdev=vnet2_2`
as necessary for each NIC, first. Second, append a hardware MAC address for
each NIC; hardware address can be generated by passing `--macaddr` instead of
`--(start|stop)`, and then source `/etc/qemu/$br/ether.conf`--br being vnet[0-9]?.

Or else, use VDE switches instead which can be used by unprivileged users!
`-device virtio-net,mac=$ether_2,id=vnet3_2 -netdev vde,...`

Just do not forget to append `--vde` argument to attach VDE switches to tap
network devices. And this has the advantage to multiply the possible network
port to x32 (unless **VDE_SWITCH_ARGS** is configured otherwise in the configuration
`/etc/qemu/vnet3/vnet3.conf` file, for this example with `VDE_SWITCH_ARGS=-n64`).
However `qemu-vlan --br=vnet3 --dhcp=dnsmasq --vde -n4` would provide 32x4=128
dynamicaly allocated IP address by DHCP server, up to 128+94, 30 are rserved
for static address. Either, set up **DNSMASQ_ARGS** in the configuration with
`--dhcp-host=ARG`, or use `/etc/qemu/vnet3/dhcp.host` host file instead.

**WARING:** Another issue will rise when using DHCP client localy to configure internal
interface which can grab an interface opened by qemu.

**SOLUTION:** issue `ifconfig vnet3_$j 0.0.0.0 up` in the host to allow the guest
to configure the interface with `dhclient|dhcpcd IFACE` in the guest.

And finaly, use `--stop` argument instead of the `--start` to shutdown a virtual LAN.
 
Requirements
------------

ip ([iproute2][6]), ifconfig, sed, md5sum, ([vde][1], [dhcpd][3], [dnsmasq][5], [dhcpcd][3])

[1]: http://vde.sourceforge.net/
[2]: http://www.netfilter.org/projects/iptables/
[3]: http://roy.marples.name/projects/dhcpcd/
[4]: http://www.isc.org/products/DHCP
[5]: http://www.thekelleys.org.uk/dnsmasq/doc.html
[6]: https://wiki.linuxfoundation.org/networking/iproute2

