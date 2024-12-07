#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2024 OpenWrt.org

# 更新 Smartdns GFWlist 规则
# 配置
GFW_LIST="gfwlist.txt"

CONFIG_FOLDER="/etc/smartdns/domain-set"
GFWLIST_CONFIG_FILE="gfwlist.conf"
GFWLIST_OUTPUT_FILE="$CONFIG_FOLDER/$GFWLIST_CONFIG_FILE"

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/gfwlist.XXXXXX)

# 获取 GFW 列表数据
function fetch_gfwlist_data() {
  echo "Fetching GFW lists..."
  cd "$TMP_DIR" || exit 1

  # 并行下载
  # curl -sSl https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt | \
  curl -sSl https://fastly.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt | \
    base64 -d | sort -u | sed '/^$\|@@/d' | sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | \
    sed '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' | grep '^[0-9a-zA-Z\.-]\+$' | \
    grep '\.' | sed 's#^\.\+##' | sort -u > temp_gfwlist1 &

  curl -sSl https://fastly.jsdelivr.net/gh/YW5vbnltb3Vz/domain-list-community@release/gfwlist.txt | \
    base64 -d | sort -u | sed '/^$\|@@/d' | sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | \
    sed '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' | grep '^[0-9a-zA-Z\.-]\+$' | \
    grep '\.' | sed 's#^\.\+##' | sort -u > temp_gfwlist2 &

  #curl -sSl https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf | \
  curl -sSl https://fastly.jsdelivr.net/gh/hq450/fancyss/rules/gfwlist.conf | \
    sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > temp_gfwlist3 &

  #curl -sSl https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt | \
  curl -sSl https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt | \
    sed "/^$/d;s/\r//g;s/^[ ]*$//g;/^#/d;/regexp:/d;s/full://g" > temp_gfwlist4 &

  #curl -sSl https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt > temp_gfwlist4 &
  curl -sSl https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt > temp_gfwlist5 &

  #curl -sS https://raw.githubusercontent.com/ixmu/smartdns-conf/refs/heads/main/script/cust_gfwdomain.conf > temp_gfwlist5 &
  curl -sSl https://fastly.jsdelivr.net/gh/ixmu/smartdns-conf/script/cust_gfwdomain.conf > temp_gfwlist6 &

  # 等待所有后台进程完成
  wait

  echo "Download successful, updating..."
  cd "$CUR_DIR" || exit 1
}

# 确保存放config的文件夹存在
mkdir -p "$CONFIG_FOLDER"

# 生成最终的GFW列表
function gen_gfwlist() {
  echo "Generating GFW list..."
  cd "$TMP_DIR" || exit 1

  cat /dev/null > $CONFIG_FOLDER/proxy-domain-list.conf

  # 合并所有临时文件，清理并保存到输出文件
  cat temp_gfwlist1 temp_gfwlist2 temp_gfwlist3 temp_gfwlist4 temp_gfwlist5 temp_gfwlist6 | \
    sort -u | sed 's/^\s*//g; s/\s*$//g' > "$GFW_LIST"

  # 删除空行并输出到最终配置
  sed -e '/^$/d' "$GFW_LIST" > "$GFWLIST_OUTPUT_FILE"

  # 添加到proxy-domain-list.conf
  cat "$GFWLIST_OUTPUT_FILE" >> "$CONFIG_FOLDER/proxy-domain-list.conf"
  cd "$CUR_DIR" || exit 1

  echo "GFW list generated at $GFWLIST_OUTPUT_FILE"
}

# 清理临时文件
function clean_gfwlist_up() {
  echo "Cleaning up..."
  rm -rf "$TMP_DIR"
  rm -f "$GFWLIST_OUTPUT_FILE"
  echo "[gfwlist]: OK."
}

# 执行函数
fetch_gfwlist_data
gen_gfwlist
clean_gfwlist_up

# 更新 Smartdns IPV4 白名单
# 配置
FILE_IPV4="tmp/whitelist.txt"
NAME_IPV4="$(basename "$FILE_IPV4")"

CLANG_LIST="clang.txt"

CONFIG_FOLDER="/etc/smartdns"
WHITELIST_CONFIG_FILE="whitelist-chnroute.conf"

WHITELIST_OUTPUT_FILE="$CONFIG_FOLDER/$WHITELIST_CONFIG_FILE"

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/whitelist.XXXXXX)

# 获取 IPv4 白名单数据
function fetch_whitelist_data() {
  echo "Fetching Whitelist IPv4 Data..."
  cd "$TMP_DIR" || exit 1

  # 获取不同的IP列表
  #qqwry=$(curl -kLfsm 5 https://raw.githubusercontent.com/metowolf/iplist/master/data/special/china.txt)
  qqwry=$(curl -kLfsm 5 https://fastly.jsdelivr.net/gh/metowolf/iplist/data/special/china.txt)
  #ipipnet=$(curl -kLfsm 5 https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt)
  ipipnet=$(curl -kLfsm 5 https://fastly.jsdelivr.net/gh/17mon/china_ip_list/china_ip_list.txt)
  clang=$(curl -kLfsm 5 https://ispip.clang.cn/all_cn.txt)
  clangcidr=$(curl -kLfsm 5 https://ispip.clang.cn/all_cn_cidr.txt)
  operatorIP=$(curl -kLfsm 5 https://fastly.jsdelivr.net/gh/gaoyifan/china-operator-ip@ip-lists/china.txt)

  # 组合和处理IP列表，删除空行和重复项
  iplist="${qqwry}\n${ipipnet}\n${clang}\n${clangcidr}\n${operatorIP}"
  echo -e "$iplist" | sort -u | sed -e '/^$/d' > "$CLANG_LIST"

  # 等待所有后台进程完成
  wait

  echo "Download successful, updating..."
  cd "$CUR_DIR" || exit 1
}

# 确保存放config的文件夹存在
mkdir -p "$CONFIG_FOLDER"

# 预填充白名单配置文件
cat > "$WHITELIST_OUTPUT_FILE" <<EOF
# Add IP whitelist which you want to filtering from some DNS server here.
# The example below filtering ip from the result of DNS server which is configured with -whitelist-ip.
# whitelist-ip [ip/subnet]
# whitelist-ip 254.0.0.1/16
EOF

# 生成 IPv4 白名单
function gen_ipv4_whitelist() {
  echo "Generating Whitelist IPv4..."
  cd "$TMP_DIR" || exit 1

  # 聚合IP范围和进程
  aggregate -q < "$CLANG_LIST" > "$NAME_IPV4"

  # 添加到白名单配置文件中
  while read -r line; do
    echo "whitelist-ip $line" >> "$WHITELIST_OUTPUT_FILE"
  done < "$NAME_IPV4"

  # 将结果写入最终的配置文件
  cp "$WHITELIST_OUTPUT_FILE" "$CONFIG_FOLDER/whitelist-ip.conf"

  cd "$CUR_DIR" || exit 1
  echo "Whitelist generation completed."
}

# 清理临时文件
function clean_whitelist_up() {
  echo "Cleaning up..."
  rm -rf "$TMP_DIR"
  rm -f "$WHITELIST_OUTPUT_FILE"
  echo "[whitelist]: OK."
}

# 执行函数
fetch_whitelist_data
gen_ipv4_whitelist
clean_whitelist_up

# 更新 Smartdns IPV4 黑名单
INPUT_FILE="IP_List.txt"
BLACKLIST_IPV4="Blacklist-IPv4.txt"
OUTPUT_FILE="Blacklist-IPv4.conf"

CONFIG_FOLDER="/etc/smartdns"
BLACKLIST_OUTPUT_FILE="$CONFIG_FOLDER/$OUTPUT_FILE"

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/blacklist.XXXXXX)

# 获取 IPv4 黑名单数据
function fetch_blacklist_ipv4() {
    echo "Fetching BlackList IPv4 Data..."
    cd "$TMP_DIR" || exit 1

    # 获取IP列表
    BLACKLIST=$(curl -kLfsm 5 "https://fastly.jsdelivr.net/gh/LittleJake/ip-blacklist/ustc_blacklist_ip.txt") 

    # 删除空行和无效行并输出到最终列表
    echo -e "$BLACKLIST" | sed -e '/^$/d' > "$INPUT_FILE"

    # 等待所有后台进程完成
    wait

    echo "Download successful, updating..."
    cd "$CUR_DIR" || exit 1
}

# 确保存放config的文件夹存在
mkdir -p "$CONFIG_FOLDER"

# 预填充黑名单配置文件
cat > "$BLACKLIST_OUTPUT_FILE" <<EOF
# Add IP blacklist which you want to filtering from some DNS server here.
# The example below filtering ip from the result of DNS server which is configured with -blacklist-ip.
# blacklist-ip [ip/subnet]
# blacklist-ip 254.0.0.1/16
EOF

# 生成 IPv4 黑名单
function gen_blacklist_ipv4() {
    echo "Generating BlackList IPv4..."
    cd "$TMP_DIR" || exit 1
# 处理每一行
while IFS= read -r ip; do
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
		if [[ $ip =~ / ]]; then
           # 如果有子网，直接添加 blacklist-ip 前缀
           echo "blacklist-ip $ip" >> "$OUTPUT_FILE"
		else
           # 如果没有子网，添加 /32 和 blacklist-ip 前缀
           echo "blacklist-ip $ip/32" >> "$OUTPUT_FILE"
		fi
    fi
done < "$INPUT_FILE"

# 从文件中删除额外的空白字符
# tr -s ' ' < "$OUTPUT_FILE" > clean_output.txt

# 排序 IP 地址并还原格式
awk '
{
    if ($1 == "blacklist-ip") {
        ip_cidr = $2
        split(ip_cidr, parts, "/")
        ip = parts[1]
        cidr = parts[2] ? parts[2] : 32
        # 将IP转换为单个数字进行排序
        n = 0
        split(ip, octets, ".")
        for (i = 1; i <= 4; i++) {
            n = n * 256 + octets[i]
        }
        # 输出IP号和CIDR以便排序
        print n, ip, cidr
    }
}' "$OUTPUT_FILE" | sort -n | awk '{print "blacklist-ip " $2 "/" $3}' > $BLACKLIST_IPV4

    # 将排序后的IP地址添加到黑名单文件中
    cat "$BLACKLIST_IPV4" >> "$BLACKLIST_OUTPUT_FILE"

    cp "$BLACKLIST_OUTPUT_FILE" "$CONFIG_FOLDER/blacklist-ip.conf"

    cd "$CUR_DIR" || exit 1
    echo "BlackList IPv4 Generation Completed."
}

# 清理临时文件
function clean_blacklist_ipv4_up() {
    echo "Cleaning Blacklist IPv4 Up..."
    rm -rf "$TMP_DIR"
    rm -f "$BLACKLIST_OUTPUT_FILE"
    echo "[blacklist]: OK."
}

# 执行函数
fetch_blacklist_ipv4
gen_blacklist_ipv4
clean_blacklist_ipv4_up

# chmod 644 $WHITELIST_OUTPUT_FILE $BLACKLIST_OUTPUT_FILE

# 更新 Smartdns China List 规则
# 配置
CHINA_LIST="chinalist.txt"

CONFIG_FOLDER="/etc/smartdns/domain-set"
CHINALIST_CONFIG_FILE="chinaList.conf"
# CHINALIST_OUTPUT_FILE="$CONFIG_FOLDER/$CHINALIST_CONFIG_FILE"

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/chinalist.XXXXXX)
 
# 获取中国域名列表数据
function fetch_chinalist_data() {
  echo "Fetching China domain list data..."
  cd "$TMP_DIR" || exit 1

  # 获取不同的IP列表
  # accelerated_domains=$(curl -kLfsm 5 https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf)
  accelerated_domains=$(curl -kLfsm 5 https://fastly.jsdelivr.net/gh/felixonmars/dnsmasq-china-list/accelerated-domains.china.conf)
  #curl -sSl https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt | \
  direct_list=$(curl -kLfsm 5 https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt)
  
  # 提取域名并输出到临时文件
  echo -e "$direct_list" | \
    sed "/^$/d;s/\r//g;s/^[ ]*$//g;/^#/d;/regexp:/d;s/full://g" > temp_direct_domains

  # 等待所有后台进程完成
  wait

  echo "Download successful, updating..."
  cd "$CUR_DIR" || exit 1
}

# 确保存放config的文件夹存在
mkdir -p "$CONFIG_FOLDER"

# 生成中国域名列表
function gen_chinalist() {
  echo "Generating China domain list..."
  cd "$TMP_DIR" || exit 1

  # 通过组合、排序和清理域名生成列表
  direct_domains=$(cat temp_direct_domains)
  domain_list="${accelerated_domains}\n${direct_domains}"
  
  # 提取域名、删除空行和无效行并输出到最终列表
  echo -e "$domain_list" | \
    sort | uniq | \
    sed -e 's/#.*//g' -e '/^$/d' -e 's/server=\///g' -e 's/\/114.114.114.114//g' | \
	sort -u > "$CHINALIST_CONFIG_FILE"

  # 将最终列表附加到输出配置中
  mv "$CHINALIST_CONFIG_FILE" "$CONFIG_FOLDER/direct-domain-list.conf"
  # mv "$CHINALIST_OUTPUT_FILE" "$CONFIG_FOLDER/direct-domain-list.conf"

  cd "$CUR_DIR" || exit 1
  echo "China domain list generation completed."
}

# 清理临时文件
function clean_chinalist_up() {
  echo "Cleaning up..."
  rm -rf "$TMP_DIR"
  rm -f "$CHINALIST_OUTPUT_FILE"
  echo "[chinalist]: OK."
}

# 执行函数
fetch_chinalist_data
gen_chinalist
clean_chinalist_up

/etc/init.d/smartdns restart
