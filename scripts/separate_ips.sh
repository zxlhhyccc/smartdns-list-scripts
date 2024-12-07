#!/bin/bash

# 下载 IP 列表并保存为 ip_list.txt
curl -sSL -o ip_list.txt "https://cdn.jsdelivr.net/gh/LittleJake/ip-blacklist/ustc_blacklist_ip.txt"

input_file="ip_list.txt"
output_file="formatted_ips.txt"

if [[ ! -s $input_file ]]; then
    echo "下载失败或文件为空，请检查 URL 是否正确。"
    exit 1
fi

# 清空输出文件
> "$output_file"

# 删除空行和无效行
sed -i '/^[[:space:]]*$/d' "$input_file"

# 处理每一行
while IFS= read -r ip; do
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
	if [[ $ip =~ / ]]; then
           # 如果有子网，直接添加 blacklist-ip 前缀
           echo "blacklist-ip $ip" >> "$output_file"
	else
           # 如果没有子网，添加 /32 和 blacklist-ip 前缀
           echo "blacklist-ip $ip/32" >> "$output_file"
	fi
    fi
done < "$input_file"

# 排序 IP 地址并还原格式
awk '
BEGIN { FS="[ ./]"; OFS="" }
{
    # Extract and pad the IP and CIDR
    cidr = ($6 == "" ? 32 : $6)
    printf "%03d.%03d.%03d.%03d/%02d %s\n", $2, $3, $4, $5, cidr, $0
}' "$output_file" | sort | awk '
{
    # Extract original IP and blacklist-ip prefix
    match($0, /blacklist-ip.*/, arr)
    print arr[0]
}' > sorted_output.txt

# 替换原文件为排序结果
mv sorted_output.txt "$output_file"

echo "格式化并按整体排序完成，结果已保存到 $output_file"
exit 0

