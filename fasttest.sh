#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 定义域名列表
DOMAINS=(
    "learn.microsoft.com"
    "www.microsoft.com"
    "itunes.apple.com"
    "swdist.apple.com"
    "dl.google.com"
    "scholar.google.com"
    "addons.mozilla.org"
    "tiktok.com"
    "s3.amazonaws.com"
    "www.amazon.com"
    "vscode.dev"
    "cdn.discordapp.com"
    "www.tesla.com"
    "www.salesforce.com"
    "www.yahoo.co.jp"
    "www.softbank.jp"
    "www.costco.com"
    "www.homedepot.com"
)

# 创建临时文件存放结果
RESULT_FILE=$(mktemp)

# 定义一个函数，在后台运行
check_domain() {
    local domain=$1
    # Ping 3次，超时1秒
    local ping_output=$(ping -c 3 -W 1 -q "$domain" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 提取平均延迟
        local avg_latency=$(echo "$ping_output" | awk -F'/' 'END{ print $5 }')
        if [ -n "$avg_latency" ]; then
            # 写入结果到文件 (加锁防止写入冲突并不是严格必须，但在高并发下是个好习惯，这里简单处理直接追加)
            if [ "$domain" == "tiktok.com" ]; then
                echo "$avg_latency $domain (⚠️国内不可用)" >> "$RESULT_FILE"
            else
                echo "$avg_latency $domain" >> "$RESULT_FILE"
            fi
        fi
    else
        echo "9999.0 $domain (不可达)" >> "$RESULT_FILE"
    fi
}

echo -e "${YELLOW}正在并发测试 ${#DOMAINS[@]} 个域名，请稍候 (约 3秒)...${NC}"
echo "------------------------------------------------"

# 循环并在后台启动任务
for domain in "${DOMAINS[@]}"; do
    check_domain "$domain" &
done

# 等待所有后台任务完成
wait

echo -e "${YELLOW}测试完成！按延迟从低到高排序结果如下：${NC}"
echo -e "${RED}注意：请勿使用标注为 (国内不可用) 的域名！${NC}"
echo -e "延迟(ms)\t域名"
echo "------------------------------------------------"

# 排序并输出
if [ -s "$RESULT_FILE" ]; then
    sort -n "$RESULT_FILE" | awk -F' ' '{printf "%-10s\t", $1; for(i=2;i<=NF;i++) printf "%s ", $i; print ""}'
else
    echo "没有获取到任何有效数据，请检查网络。"
fi

# 删除临时文件
rm "$RESULT_FILE"
