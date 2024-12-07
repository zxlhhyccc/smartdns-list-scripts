#!/bin/bash

# 更新 Smartdns chnroute 黑白名单
# China IP4 Download Link
# Smartdns Config File Path

INPUT_FILE="IP_List.txt"
BLACKLIST_IPV4="Blacklist-IPv4.txt"
OUTPUT_FILE="Blacklist-IPv4.conf"

CONFIG_FOLDER="/etc/smartdns"
BLACKLIST_OUTPUT_FILE="$CONFIG_FOLDER/$OUTPUT_FILE"

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/blacklist.XXXXXX)

# Function to fetch China IP route data
function fetch_blacklist_ipv4() {
    echo "Fetching BlackList IPv4 Data..."
    cd "$TMP_DIR" || exit 1

    # Fetching different IP lists
    BLACKLIST=$(curl -kLfsm 5 "https://cdn.jsdelivr.net/gh/LittleJake/ip-blacklist/ustc_blacklist_ip.txt") 

    echo -e "$BLACKLIST" > "$INPUT_FILE"

    # 删除空行和无效行
    sed -i '/^[[:space:]]*$/d' "$INPUT_FILE"

    # Wait for all background processes to finish
    wait

    echo "Download successful, updating..."
    cd "$CUR_DIR" || exit 1
}

# Ensure config folder exists
mkdir -p "$CONFIG_FOLDER"

# Pre-populate whitelist and blacklist config files
cat > "$BLACKLIST_OUTPUT_FILE" <<EOF
# Add IP blacklist which you want to filtering from some DNS server here.
# The example below filtering ip from the result of DNS server which is configured with -blacklist-ip.
# blacklist-ip [ip/subnet]
# blacklist-ip 254.0.0.1/16
EOF

# Function to generate IPv4 routes for China
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

# Remove extra whitespace from the file
# tr -s ' ' < "$OUTPUT_FILE" > clean_output.txt

# 排序 IP 地址并还原格式
awk '
{
    if ($1 == "blacklist-ip") {
        ip_cidr = $2
        split(ip_cidr, parts, "/")
        ip = parts[1]
        cidr = parts[2] ? parts[2] : 32
        # Convert the IP to a single number for sorting
        n = 0
        split(ip, octets, ".")
        for (i = 1; i <= 4; i++) {
            n = n * 256 + octets[i]
        }
        # Print the IP number along with CIDR for sorting
        print n, ip, cidr
    }
}' "$OUTPUT_FILE" | sort -n | awk '{print "blacklist-ip " $2 "/" $3}' > "$BLACKLIST_IPV4"


    # 将排序后的IP地址添加到黑名单文件中
    cat "$BLACKLIST_IPV4" >> "$BLACKLIST_OUTPUT_FILE"

    cp "$BLACKLIST_OUTPUT_FILE" "$CONFIG_FOLDER/blacklist-ip.conf"

    cd "$CUR_DIR" || exit 1
    echo "BlackList IPv4 Generation Completed."
}

function clean_blacklist_ipv4_up() {
    echo "Cleaning Blacklist IPv4 Up..."
    rm -rf "$TMP_DIR"
    rm -f "$BLACKLIST_OUTPUT_FILE"
    echo "[BlackList IPv4]: OK."
}

# Execute the functions
fetch_blacklist_ipv4
gen_blacklist_ipv4
clean_blacklist_ipv4_up
