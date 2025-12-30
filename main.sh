#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定义要测试的伪装域名列表
# 已添加 scholar.google.com 和 addons.mozilla.org
DOMAINS=(
    "learn.microsoft.com"
    "www.microsoft.com"
    "itunes.apple.com"
    "swdist.apple.com"
    "dl.google.com"
    "scholar.google.com"
    "addons.mozilla.org"
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

echo -e "${YELLOW}正在测试域名延迟，请稍候 (每个域名测试 3次)...${NC}"
echo "------------------------------------------------"

# 创建临时文件存放结果
RESULT_FILE=$(mktemp)

# 循环测试
for domain in "${DOMAINS[@]}"; do
    # 打印正在测试的提示（不换行）
    echo -ne "Testing ${domain} ... "
    
    # Ping 3次，超时时间设为1秒
    ping_output=$(ping -c 3 -W 1 -q "$domain" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 提取平均延迟 (在 Linux ping 输出中通常是第 4 行的 avg 值)
        avg_latency=$(echo "$ping_output" | awk -F'/' 'END{ print $5 }')
        
        # 如果提取到了数值
        if [ -n "$avg_latency" ]; then
            echo -e "${GREEN}${avg_latency} ms${NC}"
            echo "$avg_latency $domain" >> "$RESULT_FILE"
        else
            echo "数据解析失败"
        fi
    else
        echo "超时或不可达"
        # 为了排序方便，给不可达的域名设置一个极大的数值
        echo "9999.0 $domain (不可达)" >> "$RESULT_FILE"
    fi
done

echo "------------------------------------------------"
echo -e "${YELLOW}测试完成！按延迟从低到高排序结果如下：${NC}"
echo -e "${YELLOW}(数值越小，离你的 VPS 越近，伪装效果越好)${NC}"
echo -e "延迟(ms)\t域名"
echo "------------------------------------------------"

# 对结果文件按数字进行排序并输出
sort -n "$RESULT_FILE" | awk '{printf "%-10s\t%s\n", $1, $2}'

# 删除临时文件
rm "$RESULT_FILE"
