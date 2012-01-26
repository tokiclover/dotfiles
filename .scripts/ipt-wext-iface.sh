#!/bin/sh
# $Id: $HOME/.scripts/ipt-ext-iface.sh,v 1.1 2011/10/17 -tclover Exp $
#
# First set LC_ALL to en to avoid l10n problems when awk-ing IPs etc.
export LC_ALL="en_US.utf8"
DHCP="yes"
DHCPS="192.168.0.254"
# External interface
EXTIF=eth0
EXTWF=wlan0
# Internal interface
INTIPR="192.168.0.0/32"
# Loop device/localhost
LPDIF=lo
LPDIP=127.0.0.1
LPDMSK=255.0.0.0
LPDNET="$LPDIP/$LPDMSK"
# Text tools variables
IPT='/sbin/iptables'
IFC='/sbin/ifconfig'
GRP='/bin/grep'
SED='/bin/sed'
# Deny then accept: this keeps holes from opening up
# while we close ports and such
$IPT        -P INPUT       DROP
$IPT        -P OUTPUT      DROP
$IPT        -P FORWARD     DROP
# Flush all existing chains and erase personal chains
CHAINS=$(cat /proc/net/ip_tables_names 2>/dev/null)
for i in $CHAINS; do $IPT -t $i -F; done
for i in $CHAINS; do $IPT -t $i -X; done
echo 1 > /proc/sys/net/ipv4/tcp_syncookies
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
echo 1 > /proc/sys/net/ipv4/ip_dynaddr
# Source Address Verification
for f in /proc/sys/net/ipv4/conf/*/rp_filter; do echo 1 > $f; done
# Disable IP source routing and ICMP redirects
for f in /proc/sys/net/ipv4/conf/*/accept_source_route; do echo 0 > $f; done
for f in /proc/sys/net/ipv4/conf/*/accept_redirects;    do echo 0 > $f; done
echo 1 > /proc/sys/net/ipv4/ip_forward
# Setting up external interface environment variables
EXTIF="$($IFC $EXTIF|$GRP addr:|$SED 's/.*addr:\([^ ]*\) .*/\1/')"
EXTBC="$($IFC $EXTIF|$GRP Bcast:|$SED 's/.*Bcast:\([^ ]*\) .*/\1/')"
EXTWP="$($IFC $EXTWF|$GRP addr:|$SED 's/.*addr:\([^ ]*\) .*/\1/')"
EXTWB="$($IFC $EXTWF|$GRP Bcast:|$SED 's/.*Bcast:\([^ ]*\) .*/\1/')"
EXTMSK="$($IFC $EXTIF|$GRP Mask:|$SED 's/.*Mask:\([^ ]*\)/\1/')"
EXTNET="$EXTIP/$EXTMSK"
EXTWMK="$($IFC $EXTWP|$GRP Mask:|$SED 's/.*Mask:\([^ ]*\)/\1/')"
EXTWNT="$EXTWP/$EXTWMK"
echo "EXTWP=$EXTWP EXTBCW=$EXTWB EXTWMK=$EXTWMK EXTWNT=$EXTWNT"
echo "EXTIP=$EXTIP EXTBCF=$EXTBC EXTMSK=$EXTMSK EXTNET=$EXTNET"
# We are now going to create a few custom chains that will result in
# logging of dropped packets. This will enable us to avoid having to
# enter a log command prior to every drop we wish to log. The
# first will be first log drops the other will log rejects.
# Do not complain if chain already exists (so restart is clean)
$IPT -N DROPl   2> /dev/null
$IPT -A DROPl   -j LOG --log-prefix 'IPT-Dl:'
$IPT -A DROPl   -j DROP
$IPT -N REJECTl 2> /dev/null
$IPT -A REJECTl -j LOG --log-prefix 'IPT-Rl:'
$IPT -A REJECTl -j REJECT
# We will log and drop bad tcp packets stated NEW but without a SYN packet after being called by BADTCP filter
$IPT -N BADTCPl 2> /dev/null
$IPT -A BADTCPl -j LOG --log-prefix 'IPT-BTl:'
$IPT -A BADTCPl -j DROP
# We will drop or rejetc bad tcp packets stated NEW but without a SYN packet
$IPT -N BADTCP
$IPT -A BADTCP  -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j REJECT --reject-with tcp-reset
$IPT -A BADTCP  -p tcp ! --syn -m state --state NEW -j BADTCPl
# Now we are going to filter bad tcp right at the bat
$IPT -A INPUT   -p tcp -j BADTCP
$IPT -A OUTPUT  -p tcp -j BADTCP
# Now we are going to accept all traffic from our loopback device
# if the IP matches any of our interfaces.
$IPT -A INPUT   -i $LPDIF -s   $LPDIP   -j ACCEPT
$IPT -A INPUT   -i $LPDIF -s   $EXTIP   -j ACCEPT
$IPT -A INPUT   -i $LPDIF -s   $EXTWP   -j ACCEPT
# Blocking Broadcasts
$IPT -A INPUT   -i $EXTIF  -d   $EXTBC   -j DROPl
$IPT -A OUTPUT  -o $EXTIF  -d   $EXTBC   -j DROPl
$IPT -A FORWARD -o $EXTIF  -d   $EXTBC   -j DROPl
$IPT -A INPUT   -i $EXTWF  -d   $EXTWB   -j DROPl
$IPT -A OUTPUT  -o $EXTWF  -d   $EXTWB   -j DROPl
$IPT -A FORWARD -o $EXTWF  -d   $EXTWB   -j DROPl
# Block WAN access to internal network
# This also stops nefarious crackers from using our network as a
# launching point to attack other people
# iptables translation:
# "if input going into our external interface does not originate from our isp assigned
# ip address, drop it like a hot potato
$IPT -A INPUT   -i $EXTIF ! -d $EXTIP  -j DROPl
$IPT -A INPUT   -i $EXTWF ! -d $EXTWP  -j DROPl
# An additional Egress check
$IPT -A OUTPUT  ! -o $EXTIF -s $EXTNET -j DROPl
$IPT -A OUTPUT  ! -o $EXTWF -s $EXTWNT -j DROPl
# Block outbound ICMP (except for PING)
$IPT -A OUTPUT  -o $EXTIF -p icmp ! --icmp-type 8 -j DROPl
$IPT -A FORWARD -o $EXTWF -p icmp ! --icmp-type 8 -j DROPl
# COMmon ports:
# 0 is tcpmux; SGI had vulnerability, 1 is common attack
# 13 is daytime
# 98 is Linuxconf
# 111 is sunrpc (portmap)
# 137:139, 445 is Microsoft
# SNMP: 161,2
# Squid flotilla: 3128, 8000, 8008, 8080
# 1214 is Morpheus or KaZaA
# 2049 is NFS
# 3049 is very virulent Linux Trojan, mistakable for NFS
# Common attacks: 1999, 4329, 6346
# Common Trojans 12345 65535
COMBLOCK="0:1 13 98 111 137:139 161:162 445 1214 1999 2049 3049 4329 6346 3128 8000 8008 8080 12345 65535"
# TCP ports:
# 98 is Linuxconf
# 512-515 is rexec, rlogin, rsh, printer(lpd)
#   [very serious vulnerabilities; attacks continue daily]
# 1080 is Socks proxy server
# 6000 is X (NOTE X over SSH is secure and runs on TCP 22)
# Block 6112 (Sun's/HP's CDE)
TCPBLOCK="$COMBLOCK 98 512:515 1080 6000:6009 6112"
# UDP ports:
# 161:162 is SNMP
# 520=RIP, 9000 is Sangoma
# 517:518 are talk and ntalk (more annoying than anything)
UDPBLOCK="$COMBLOCK 161:162 520 123 517:518 1427 9000"
echo -n "FW: Blocking attacks to TCP port "
for i in $TCPBLOCK;
do
  echo -n "$i "
  $IPT -A INPUT   -p tcp --dport $i  -j DROPl
  $IPT -A OUTPUT  -p tcp --dport $i  -j DROPl
  $IPT -A FORWARD -p tcp --dport $i  -j DROPl
done
echo ""
echo -n "FW: Blocking attacks to UDP port "
for i in $UDPBLOCK;
do
  echo -n "$i "
  $IPT -A INPUT   -p udp --dport $i  -j DROPl
  $IPT -A OUTPUT  -p udp --dport $i  -j DROPl
  $IPT -A FORWARD -p udp --dport $i  -j DROPl
done
echo ""
# We are going to open udp-ports for DHCP server
if [ $DHCP == "yes" ]; then
$IPT -A INPUT -p udp -s $DHCPS --sport 67:68 --dport 67:68 -j ACCEPT
fi
# Opening up ftp connection tracking
#MODULES="ip_nat_ftp ip_conntrack_ftp"
#for i in $MODULES;
#do
# echo "Inserting module $i"
# modprobe $i
#done
# Defining some common chat clients. Remove these from your accepted list for better security.
# ICQ and AOL are 5190
# MSN is 1863
# Y! is 5050
# Jabber is 5222
# Y! and Jabber ports not added by author and therefore left out of the script
IRC='ircd'
#MSN=1863
#ICQ=5190
NFS='sunrpc'
# We have to sync!!
PORTAGE='rsync'
OpenPGP_HTTP_Keyserver=11371
# All services ports are read from /etc/services
TCPSERV="domain ssh http https ftp ftp-data mail pop3 pop3s imap3 imaps imap2 \
         time $PORTAGE $IRC $MSN $ICQ $OpenPGP_HTTP_Keyserver"
UDPSERV="domain time"
echo -n "FW: Allowing inside systems to use service:"
for i in $TCPSERV;
do
  echo -n "$i "
  $IPT -A OUTPUT  -o $EXTIF  -p tcp -s $EXTIP   --dport $i --syn -m state --state NEW -j ACCEPT
  $IPT -A OUTPUT  -o $EXTIF  -p tcp -s $EXTWP   --dport $i --syn -m state --state NEW -j ACCEPT
done
echo ""
echo -n "FW: Allowing inside systems to use service:"
for i in $UDPSERV;
do
  echo -n "$i "
  $IPT -A OUTPUT  -o $EXTIF  -p udp -s $EXTIP   --dport $i -m state --state NEW -j ACCEPT
  $IPT -A OUTPUT  -o $EXTWF  -p udp -s $EXTWP   --dport $i -m state --state NEW -j ACCEPT
done
echo ""
# Allow to ping out
$IPT -A OUTPUT  -o $EXTIF  -p icmp -s $EXTIP   --icmp-type 8 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT  -o $EXTWF  -p icmp -s $EXTWP   --icmp-type 8 -m state --state NEW -j ACCEPT
# turning off DHT tracking for rTorrent
echo "FW: disabling tracking on 50555-udp-port PREROUTING and OUTPUT"
$IPT -t raw -A PREROUTING       -p udp -s $EXTIP --dport 50555 -j NOTRACK
$IPT -t raw -A OUTPUT -o $EXTIF -p udp -s $EXTIP --sport 50555 -j NOTRACK
$IPT -t raw -A PREROUTING       -p udp -s $EXTWP --dport 50555 -j NOTRACK
$IPT -t raw -A OUTPUT -o $EXTWF -p udp -s $EXTWP --sport 50555 -j NOTRACK
# CUPS tcp/udp port 631
echo "Opening Input/Output UPD/TCP over 127.0.0.1:631 for CUPS"
$IPT -A INPUT  -p tcp --dport 631 -i $LPDIP --syn -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 631 -o $LPDIP --syn -m state --state NEW -j ACCEPT
# MPD 6600
echo "Opening Input/Output UPD/TCP over 127.0.0.1:6600 for MPD"
$IPT -A INPUT  -p tcp --dport 6600 -i $LPDIF --syn -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p tcp --dport 6600 -o $LPDIF --syn -m state --state NEW -j ACCEPT
# Torrents ports
echo "Opening 50550:50555 port for rTorrent"
$IPT -A INPUT -p tcp --dport 50550:50555 -i $EXTIP --syn -m state --state NEW -j ACCEPT
$IPT -A INPUT -p udp --dport 50555       -i $EXTIP       -m state --state NEW -j ACCEPT
$IPT -A INPUT -p tcp --dport 50550:50555 -i $EXTWP --syn -m state --state NEW -j ACCEPT
$IPT -A INPUT -p udp --dport 50555       -i $EXTWP       -m state --state NEW -j ACCEPT
# NAT I/O F 
$IPT -t nat -A PREROUTING  -j ACCEPT
$IPT -t nat -A POSTROUTING -j ACCEPT
$IPT -t nat -A OUTPUT -j ACCEPT
$IPT -A INPUT -p tcp --dport auth --syn -m state --state NEW -j ACCEPT
# Accept everything estabished... right away at the bat
$IPT -A INPUT   -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
# We are going to accept all traffic from our LAN
$IPT -A INPUT    -s 192.168.0.0/24 -j ACCEPT
$IPT -A FORWARD  -s 192.168.0.0/24 -j ACCEPT
$IPT -A OUTPUT   -s 192.168.0.0/24 -j ACCEPT
# Block and log what me may have forgot
$IPT -A INPUT   -j DROPl
$IPT -A OUTPUT  -j REJECTl
$IPT -A FORWARD -j DROPl
