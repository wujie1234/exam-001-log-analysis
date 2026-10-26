#!/bin/bash
#
# exam_001 - Web access log analysis
#
# Parses an access log in Common Log Format (Apache/Nginx default):
#
#   192.168.1.100 - - [01/Jan/2024:10:00:00 +0000] "GET /api/users HTTP/1.1" 200 1234
#   ^ client ip     ^ timestamp                     ^ request line        ^ status ^ bytes
#
# and writes a report with
#   1. the busiest client IP and its request count
#   2. the HTTP status code distribution
#
# Usage: solve.sh [log_file] [report_file]
#        defaults to /data/access.log -> /output/report.txt
#
set -euo pipefail

LOG_FILE="${1:-/data/access.log}"
REPORT="${2:-/output/report.txt}"

if [ ! -f "$LOG_FILE" ]; then
    printf 'error: log file not found: %s\n' "$LOG_FILE" >&2
    exit 1
fi

mkdir -p "$(dirname "$REPORT")"

LC_ALL=C awk '
# Extract the 3-digit status code from a single log line.
# Returns "" when the line is not a recognisable log entry (blank/garbage),
# so such lines are counted for nothing instead of skewing the statistics.
#
# Plain field splitting is unsafe: the request line may contain spaces
# ("GET /a b HTTP/1.1") or be a bare "-". Splitting on the double quotes is
# reliable -- the status code is the first token after the 2nd quote.
function status_of(line,   q, tail, f, n) {
    n = split(line, q, "\"")
    if (n >= 3) {
        tail = q[3]
        sub(/^[ \t]+/, "", tail)
        split(tail, f, /[ \t]+/)
        if (f[1] ~ /^[0-9][0-9][0-9]$/) return f[1]
    }
    # Fallback for an unquoted request field: the status is the second to
    # last column ("... status bytes").
    n = split(line, f, /[ \t]+/)
    if (n >= 2 && f[n - 1] ~ /^[0-9][0-9][0-9]$/) return f[n - 1]
    return ""
}

{
    # Only accept lines that carry the bracketed timestamp of a log entry;
    # this drops blank lines, stack traces, stray text, etc. so that junk
    # never shows up as a fake "client IP".
    if ($0 !~ /\[[^]]+\]/) next
    ip = $1
    if (ip == "" || ip == "-") next

    ip_count[ip]++                         # task 1: requests per IP
    code = status_of($0)
    if (code != "") status_count[code]++   # task 3: status distribution
}

END {
    # ---- task 2: busiest IP -------------------------------------------
    print "=== Top IP ==="
    top_ip = ""
    top_n = 0
    for (ip in ip_count) {
        c = ip_count[ip]
        # Highest count wins; ties are broken by the lexicographically
        # smallest IP so the report is byte-identical between runs
        # (awk array iteration order is unspecified).
        if (c > top_n || (c == top_n && (top_ip == "" || ip < top_ip))) {
            top_ip = ip
            top_n = c
        }
    }
    if (top_ip != "") printf "%s: %d requests\n", top_ip, top_n

    # ---- task 3: status code distribution ------------------------------
    print ""
    print "=== Status Code Distribution ==="

    k = 0
    for (code in status_count) codes[k++] = code

    # Insertion sort, numeric ascending. Avoids gawk-only asort()/PROCINFO
    # so the script also runs on mawk/busybox awk.
    for (i = 1; i < k; i++) {
        v = codes[i]
        j = i - 1
        while (j >= 0 && codes[j] + 0 > v + 0) {
            codes[j + 1] = codes[j]
            j--
        }
        codes[j + 1] = v
    }
    for (i = 0; i < k; i++) printf "%s: %d\n", codes[i], status_count[codes[i]]
}
' "$LOG_FILE" > "$REPORT"

cat "$REPORT"
printf '\nReport written to %s\n' "$REPORT"
