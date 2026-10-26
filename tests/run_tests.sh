#!/bin/bash
#
# 本地校验：用 data/sample-access.log 跑一遍 solve.sh，逐项比对预期结果。
# 退出码 0 表示全部通过。
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE="$ROOT/data/sample-access.log"
REPORT="$(mktemp)"
trap 'rm -f "$REPORT"' EXIT

PASS=0
FAIL=0

check() {
    local desc="$1" expected="$2"
    if grep -qxF -- "$expected" "$REPORT"; then
        printf 'PASS  %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        printf 'FAIL  %s\n      期望行: %s\n' "$desc" "$expected"
        FAIL=$((FAIL + 1))
    fi
}

bash "$ROOT/solve.sh" "$SAMPLE" "$REPORT" >/dev/null

check "Top IP 小节标题"        "=== Top IP ==="
check "Top IP 为 .100 且 5 次" "192.168.1.100: 5 requests"
check "状态码小节标题"         "=== Status Code Distribution ==="
check "200 计数"               "200: 6"
check "401 计数"               "401: 1"
check "404 计数"               "404: 2"
check "500 计数"               "500: 1"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
