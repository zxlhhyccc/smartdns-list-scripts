#!/bin/bash

# Define input and output file
input_file="ip_list.txt"
output_file="invalid_ips.txt"

# Ensure the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Input file not found!"
    exit 1
fi

# Clear the output file
> "$output_file"

# Function to validate IPv4 with subnet
validate_ip_with_subnet() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|3[0-2]))?$ ]]; then
        # Extract the IP part and subnet part
        local ip_part=$(echo $ip | cut -d'/' -f1)
        local subnet_part=$(echo $ip | cut -d'/' -f2)

        # Validate the IP format and range
        IFS='.' read -r -a octets <<< "$ip_part"
        if [[ ${octets[0]} -le 255 && ${octets[1]} -le 255 && ${octets[2]} -le 255 && ${octets[3]} -le 255 ]]; then
            # If subnet exists, check the range (0-32)
            if [[ -n "$subnet_part" && ($subnet_part -ge 0 && $subnet_part -le 32) ]]; then
                echo "Valid IP with subnet: $ip"
            elif [[ -z "$subnet_part" ]]; then
                # If no subnet is provided, assume /32
                echo "Valid IP with default subnet: $ip/32"
            else
                echo "Invalid subnet range: $ip"
                echo "$ip" >> "$output_file"
            fi
        else
            echo "Invalid IP format: $ip"
            echo "$ip" >> "$output_file"
        fi
    else
        echo "Invalid IP format with subnet: $ip"
        echo "$ip" >> "$output_file"
    fi
}

# Process each line in the file
while IFS= read -r ip; do
    # Remove extra spaces
    ip=$(echo "$ip" | xargs)
    # Validate the IP address with subnet
    if [[ -n "$ip" ]]; then
        validate_ip_with_subnet "$ip"
    fi
done < "$input_file"

# Display the results
echo "Invalid IPs with subnets have been saved to $output_file"

