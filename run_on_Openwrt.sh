#!/bin/sh
# gfwlist2dnsmasq on Openwrt
# wget is more common in Openwrt
# need install 'coreutils-base64' first
# openwrt dnsmasq can only restart by /etc/init.d/dnsmasq restart
# set your custom here
HOST='127.0.0.1'
PORT=5353
IPSET='gfwlist'
wget --no-check-certificate -O /tmp/gfwlist.txt \
	https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt \
	&& base64 -d /tmp/gfwlist.txt \
	| awk -f $(cd "$(dirname "$0")"; pwd)/gfwlist2domainlist.awk \
		- /root/conf/user_rule.txt \
	| grep -F -v -f /root/conf/skip_domain.txt \
	| awk -f $(cd "$(dirname "$0")"; pwd)/domainlist2dnsmasq.awk \
		-v 'host='$HOST -v 'port='$PORT -v 'ipset='$IPSET - \
	> /etc/dnsmasq.d/gfwlist.conf 2>/dev/null \
	&& echo '[INFO] dnsmasq restarting...'&& /etc/init.d/dnsmasq restart
