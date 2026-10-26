#!/bin/bash
#
# 访问日志分析 —— 统计客户端 IP 的请求次数
#
# 用法: solve.sh [log_file] [report_file]
#       默认 /data/access.log -> /output/report.txt
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
{
    count[$1]++
}

END {
    print "=== Top IP ==="
    top_ip = ""
    top_n = 0
    for (ip in count) {
        if (count[ip] > top_n) {
            top_n = count[ip]
            top_ip = ip
        }
    }
    if (top_ip != "") printf "%s: %d requests\n", top_ip, top_n
}
' "$LOG_FILE" > "$REPORT"

cat "$REPORT"
printf '\nReport written to %s\n' "$REPORT"
