#!/bin/bash

# 输入文件包含 IP 范围
input_file="ip_black20221206.txt"

# 输出文件，每行一个 IP
output_file="expanded_ips.txt"

# 清空输出文件
> "$output_file"

# 转换 IP 为整数
ip_to_int() {
    local ip=$1
    IFS='.' read -r a b c d <<< "$ip"
    echo $((a * 256**3 + b * 256**2 + c * 256 + d))
}

# 转换整数为 IP
int_to_ip() {
    local int=$1
    echo "$((int >> 24 & 255)).$((int >> 16 & 255)).$((int >> 8 & 255)).$((int & 255))"
}

# 读取每一行并展开 IP 范围
while IFS= read -r range; do
    # 获取起始 IP 和结束 IP
    start_ip=$(echo $range | cut -d'-' -f1)
    end_ip=$(echo $range | cut -d'-' -f2)

    # 转换为整数
    start_int=$(ip_to_int "$start_ip")
    end_int=$(ip_to_int "$end_ip")

    # 遍历范围并写入输出文件
    for ((i=start_int; i<=end_int; i++)); do
        int_to_ip $i >> "$output_file"
    done
done < "$input_file"

echo "IP 范围已展开并保存到 $output_file"

