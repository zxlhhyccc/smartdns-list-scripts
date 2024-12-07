#!/bin/bash

# 输入文件
input_file="china_ips.txt"

# 输出文件
output_file="formatted_ips.txt"

# 清空输出文件（如果已存在）
> "$output_file"

# 遍历输入文件的每一行
while IFS= read -r line; do
    # 检查是否是有效的 IP 地址格式
    if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # 格式化行并追加到输出文件
        echo "blacklist-ip $line/32" >> "$output_file"
    else
        echo "跳过无效IP: $line"
    fi
done < "$input_file"

# 输出处理完成消息
echo "格式化完成，结果已保存到 $output_file"

