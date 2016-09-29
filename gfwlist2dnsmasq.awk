#!/usr/bin/awk -f

# Add domain name to global variable domains.
function add(domain) {
	domain_count = domain_count + 1
	domains[domain_count] = domain
}

# Extract domain name from non-regex line
function extract(line, original_line) {
	sub(/.*:\/\//, "", line) # remove everything till ://, such as http:// https://
	sub(/\/.*/, "", line)    # remove everything from /
	sub(/:.*/, "", line)     # remove everything from :
	sub(/\*/, "", line)      # remove *
	sub(/^\./, "", line)     # remove leading dot

	if (match(line, /([a-zA-Z0-9\-]+\.)+[a-zA-Z0-9\-]+/)) {
		add(line)
	} else {
		print "[WARN] <NR>" NR "</NR><original>" original_line "</original><extracted>" line "</extracted>" | "cat >&2"
	}
}

# Extract domain name from regex line
function extract_regex(line, original_line) {

	# Expand the lines like (aa|bb|cc) into multiple records
	pos = match(line, /\([a-zA-Z0-9\.\|]+\)/)
	if (pos != 0) {
		in_bracket = substr(line, RSTART + 1, RLENGTH - 2)
		n = split(in_bracket, arr, "|")
		for (i = 1; i <= n; i++) {
			expanded_line = line
			sub(/\([a-zA-Z0-9\.\|]+\)/, arr[i], expanded_line)
			extract_regex(expanded_line, original_line)
		}
	} else {
		sub(/.*:\\\/\\\//, "", line)    # remove everything till :\/\/ in regex, :// in plain text, such as http:// https://
		gsub(/\([^\)]+\)\*?/, "", line) # remove (...)*? such as ([^\/]+\.)
		gsub(/\[.*\]\+/, "", line)      # remove [...]
		sub(/\\\/.*/, "", line)         # remove everything from \/ in regex, / in plaint text
		gsub(/\\\./, ".", line)         # replace \. to .
		extract(line, original_line)
	}
}

BEGIN {
	"date \"+%Y-%m-%d %H:%M:%S\"" | getline now
	print "# gfw list ipset rules for dnsmasq"
	print "# updated on " now
	print "#"

	if (host == "") {
		host = "127.0.0.1"
	}
	if (port == "") {
		port = 5353
	}
}
{
	original_line = $0

	if (/^$/ || /^#/ || /^\!/ || /^\[/ || /^@@/) {
		# Empty line

		# #
		# comments in user_rule.txt

		# !
		# comments
		# see https://adblockplus.org/en/filters#comments

		# [
		# comments

		# @@
		# whitelist
		# see https://adblockplus.org/en/filters#whitelist
	} else if (/^\|\|/) {
		# ||
		# https://adblockplus.org/en/filters#anchors
		sub(/^\|\|/, "") # remove leading ||
		extract($0, original_line)
	} else if (/^\|/) {
		# |
		# https://adblockplus.org/en/filters#anchors
		sub(/^\|/, "") # removing leading |
		extract($0, original_line)
	} else if (/^\/.*\/$/) {
		# /.../
		# https://adblockplus.org/en/filters#regexps
		sub(/^\//, "") # remove leading /
		sub(/\/$/, "") # remove tailing /
		extract_regex($0, original_line)
	} else if (/^\./) {
		# start with dot
		extract($0, original_line)
	} else {
		extract($0, original_line)
	}
}
END {
	for (i = 1; i <= domain_count; i++) {
		printf "server=/.%s/%s#%d\n", domains[i], host, port | "sort | uniq"
	}
}
