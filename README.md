# Convert gfwlist into dnsmasq configuration file.

## How to use:

Copy `gfwlist2domainlist.awk`, `domainlist2dnsmasq.awk`,
and `gfwlist2dnsmasq.sh` to directory `/usr/local/bin/`,
add `gfwlist2dnsmasq.sh` to `/etc/crontab` to let it run at 2:30 every day:
```
30	2	*	*	*	root	/usr/local/bin/gfwlist2dnsmasq.sh > /dev/null 2>&1
```

`user_rule.txt` example:
```
# comment line
! comment line as well
example.net
```
