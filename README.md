# Convert gfwlist into dnsmasq configuration file.


## How to use:

```sh
#!/bin/sh
curl -sf -o /tmp/gfwlist.txt \
	https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt \
	&& base64 -d /tmp/gfwlist.txt \
	| awk -f $(cd "$(dirname "$0")"; pwd)/gfwlist2domainlist.awk \
		- /path/to/user_rule.txt \
	| grep -F -v -f /path/to/skip_domain.txt \
	| awk -f $(cd "$(dirname "$0")"; pwd)/domainlist2dnsmasq.awk \
		-v 'host=127.0.0.1' -v 'port=5353' -v 'ipset=gfwlist' - \
	> /etc/dnsmasq.d/gfwlist.conf 2>/dev/null \
	&& service dnsmasq restart
```

Supported variables passing by -v parameter:

	host: the host of DNS server, default is 127.0.0.1
	port: the port of DNS server, default is 5353
	ipset: the ipset of the output, default is gfwlist
	noipset: do not print the ipset line to the output
	format: the output format for each line,
		default is server=/.%domain/%host#%port\nipset=/.%domain/gfwlist\n"


user_rule.txt example:
```
# comment line
! comment line as well
example.net
```