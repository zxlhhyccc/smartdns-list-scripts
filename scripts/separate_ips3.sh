#!/bin/bash

# 下载 IP 列表并保存为 ip_list.txt
curl -sSL -o ip_list.txt "https://raw.githubusercontent.com/LittleJake/ip-blacklist/refs/heads/main/all_blacklist.txt"

# 将文件转换为 Unix 格式
dos2unix ip_list.txt

# 输入文件名
input_file="ip_list.txt"

# 输出文件名
output_file="formatted_ips.txt"

# 确保下载成功
if [[ ! -s $input_file ]]; then
    echo "下载失败或文件为空，请检查 URL 是否正确。"
    exit 1
fi

# 清空输出文件
> "$output_file"

# 去除文件中的空格和无效行
sed -i '/^[[:space:]]*$/d' "$input_file"  # 删除空行

# 处理每一行
while IFS= read -r ip; do
    # 检查是否是有效的 IPv4 地址，且不包含子网
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # 检查每个八位数是否在0-255范围内
        IFS='.' read -r -a octets <<< "$ip"
        if [[ ${octets[0]} -le 255 && ${octets[1]} -le 255 && ${octets[2]} -le 255 && ${octets[3]} -le 255 ]]; then
            # 添加 blacklist-ip 前缀
            echo "blacklist-ip $ip" >> "$output_file"
        fi
    fi
done < "$input_file"

# 去除重复的 IP 地址
sort -u "$output_file" -o "$output_file"

# 对输出文件中的 IP 地址按地址大小排序（升序）
sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 "$output_file" -o "$output_file"

# 去除输出文件末尾的空格
sed -i 's/[[:space:]]*$//g' "$output_file"

echo "格式化并排序完成，结果已保存到 $output_file"

