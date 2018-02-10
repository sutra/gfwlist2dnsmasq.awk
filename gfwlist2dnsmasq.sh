#!/bin/sh
gfwlist="/tmp/gfwlist.txt"
gfwlist_url="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
gfwlist_dnsmasq_conf="/usr/local/etc/dnsmasq.d/gfwlist.conf"
host="127.0.0.1"
port="5353"
ipset="gfwlist"
noipset=""
format=""
user_rule=""
skip_domain="/dev/null"

usage() {
cat << EOF
Usage: $0 [-i <url>] [-o <file>] [-h <host>] [-p <port>] [-s <ipset>] [-S] [-f format] [[-u <file>]...] [-k <file>] [-h]
	-i <url>
		URL of gfwlist.txt,
		default is https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt
	-o <file>
		Write generated dnsmasq configuration file to <file>,
		default is /usr/local/etc/dnsmasq.d/gfwlist.conf.
	-h <host>
		The host of DNS server, default is 127.0.0.1.
	-p <port>
		The port of DNS server, default is 5353.
	-s <ipset>
		The ipset of the output, default is gfwlist.
	-S
		Do not print the ipset line to the output.
	-f
		The output format for each line,
		default is server=/.%domain/%host#%port\nipset=/.%domain/gfwlist\n
	-u <file>
		User rule file.
	-k <file>
		Skip domain file.
	-h
		Display this help.
EOF
}

while getopts ":i:o:h:p:s:Sf:u:k:" o; do
	case "${o}" in
		i)
			gfwlist_url="${OPTARG}"
			;;
		o)
			gfwlist_dnsmasq_conf="${OPTARG}"
			;;
		h)
			host="${OPTARG}"
			;;
		p)
			port="${OPTARG}"
			;;
		s)
			ipset="${OPTARG}"
			;;
		S)
			noipset="noipset"
			;;
		f)
			format="${OPTARG}"
			;;
		u)
			if [ -z "${OPTARG}" -o ! -r "${OPTARG}" ]; then
				echo "\"${OPTARG}\" does not exist."
				usage
				exit 1
			fi
			user_rule="${user_rule} ${OPTARG}"
			;;
		k)
			if [ -z "${OPTARG}" -o ! -r "${OPTARG}" ]; then
				echo "\"${OPTARG}\" does not exist."
				usage
				exit 1
			fi
			skip_domain="${OPTARG}"
			;;
		h)
			usage
			exit
			;;
		*)
			usage
			exit
			;;
	esac
done
shift $((OPTIND-1))

tmp_gfwlist_dnsmasq_conf="/tmp/gfwlist.conf.`cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`"

curl -sf -o "${gfwlist}" \
	"${gfwlist_url}" \
	&& base64 -d "${gfwlist}" \
	| awk -f $(cd "$(dirname "$0")"; pwd)/gfwlist2domainlist.awk \
		- ${user_rule} \
	| grep -F -v -f "${skip_domain}" \
	| awk -f $(cd "$(dirname "$0")"; pwd)/domainlist2dnsmasq.awk \
		-v "host=${host}" \
		-v "port=${port}" \
		-v "ipset=${ipset}" \
		-v "noipset=${noipset}" \
		-v "format=${format}" \
		- \
	> "${tmp_gfwlist_dnsmasq_conf}" 2>/dev/null \
	&& \
	(
		diff -I '^#.*' "${gfwlist_dnsmasq_conf}" "${tmp_gfwlist_dnsmasq_conf}" || \
			(cp "${tmp_gfwlist_dnsmasq_conf}" "${gfwlist_dnsmasq_conf}" && service dnsmasq restart)
	)

rm -f "${tmp_gfwlist_dnsmasq_conf}"
