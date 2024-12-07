#!/bin/bash

# Function to fetch IPs and pipe them to blackipv4 or a file
fetch_and_blacklist_ips() {
    url="$1"
    jq_filter="$2"
    
    # Fetch data and process IPs
    curl -s "$url" | jq -r "$jq_filter" | while read ip; do
        # Write each IP to blackipv4.sh or process as needed
        echo "$ip" >> blackipv4.sh
    done
}

fetch_and_blacklist_ips_json() {
    url="$1"
    
    # Fetch the IPs and append them to blackipv4.sh
    curl -s "$url" >> blackipv4.sh
}

# Fetch Cloudflare IPv4 addresses (plain text)
fetch_and_blacklist_ips_json "https://www.cloudflare.com/ips-v4"

# Fetch Fastly IP addresses
curl -s https://api.fastly.com/public-ip-list | jq -r '.addresses[]' >> blackipv4.sh

# Fetch IPs from whois.radb.net for multiple gas codes
for gas_code in '!gas44907' '!gas59930' '!gas62014' '!gas62041' '!gas211157'; do
    echo "$gas_code" | nc whois.radb.net 43 | tail -n +2 | head -n -1 | xargs -n1 echo | while read ip; do
        echo "$ip" >> blackipv4.sh
    done
done

# Fetch IP ranges for AWS S3 and CloudFront
fetch_and_blacklist_ips "https://ip-ranges.amazonaws.com/ip-ranges.json" '.prefixes[] | select(.service=="S3" or .service=="CLOUDFRONT") | .ip_prefix'

# Fetch Azure CDN IP addresses
curl -s https://raw.githubusercontent.com/Gelob/azure-cdn-ips/master/edgenodes-ipv4.txt >> blackipv4.sh

# Fetch GitHub web IPs
fetch_and_blacklist_ips "https://api.github.com/meta" '.web[] | select(test("[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"))' 

# Optionally, make blackipv4.sh executable
chmod +x blackipv4.sh

