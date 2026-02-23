#!/bin/bash

# ============ 配置区域 ============
WORK_DIR=$(pwd)
OUTPUT_FILE="${WORK_DIR}/proxy-list.txt"

PROXY_DNS="https://cloudflare-dns.com/dns-query https://dns.google/dns-query"
LIST_URL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
# ==================================

# 需要确保强制走代理的 DNS 泄漏测试网站
MUST_PROXY_DOMAINS="
ipleak.net
ipleak.org
ipv6-test.com
ipv6-test.net
test-ipv6.com
dnsleak.com
dnsleak.org
whatismyip.com
whatsmyip.net
"

echo "开始下载国外域名列表..."

curl -L -o gfw_raw.txt --connect-timeout 15 "$LIST_URL" 2>/dev/null

if [ $? -ne 0 ] || [ ! -s gfw_raw.txt ]; then
    echo "⚠️ 警告：下载失败，将只生成强制泄漏测试域名列表。"
    > gfw_raw.txt
fi

echo "下载完成，正在生成 AdGuard Home 规则文件..."

TEMP_DOMAIN_LIST=$(mktemp)

grep -vE '^(#|$)' gfw_raw.txt | while read domain; do
    domain=$(echo "$domain" | xargs)
    if [ -n "$domain" ]; then
        echo "$domain" >> "$TEMP_DOMAIN_LIST"
    fi
done

echo "" >> "$TEMP_DOMAIN_LIST"
for domain in $MUST_PROXY_DOMAINS; do
    echo "$domain" >> "$TEMP_DOMAIN_LIST"
done

sort -u "$TEMP_DOMAIN_LIST" -o "$TEMP_DOMAIN_LIST"

> "$OUTPUT_FILE"
echo "# 国外域名代理列表 - 自动生成（含 DNS 泄漏测试域名）" >> "$OUTPUT_FILE"
echo "# BY-小麒"
echo "# 更新时间: $(date)" >> "$OUTPUT_FILE"
echo "# 上游 DNS: $PROXY_DNS" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

while read domain; do
    [ -n "$domain" ] && echo "[/$domain/]$PROXY_DNS" >> "$OUTPUT_FILE"
done < "$TEMP_DOMAIN_LIST"

rm -f gfw_raw.txt "$TEMP_DOMAIN_LIST"

RULE_COUNT=$(grep -c '^\[/' "$OUTPUT_FILE")
echo "✅ 规则文件生成成功！共 $RULE_COUNT 条规则。"
echo "文件位置: $OUTPUT_FILE"
