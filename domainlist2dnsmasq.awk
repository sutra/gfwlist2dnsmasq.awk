#!/usr/bin/awk -f

BEGIN {
	host = host != "" ? host : "127.0.0.1"
	port = port != "" ? port : 5353
	ipset = ipset != "" ? ipset : "gfwlist"

	format = format != "" ? format : "server=/.%domain/%host#%port\n"
	if (noipset == "") {
		format = format "ipset=/.%domain/" ipset "\n"
	}

	"date \"+%Y-%m-%d %H:%M:%S\"" | getline now
	print "# gfw list ipset rules for dnsmasq"
	print "# updated on " now
	print "#"
}

{
	element = format
	gsub(/%domain/, $1, element)
	gsub(/%host/, host, element)
	gsub(/%port/, port, element)
	printf element
}
