#!/bin/bash

interface=$(ip route | grep default | awk '{print $5}' | head -n1)
dumpdir=/root/captures
threshold=30000
capture_count=5000
sleep_after_capture=230
discord_webhook_url="YOUR_DISCORD_WEBHOOK_URL_HERE"
debug_mode=false

debug_echo() {
    if $debug_mode; then
        echo "$@"
    fi
}

if [ "$1" = "debug" ]; then
    debug_mode=true
    debug_echo "Debug mode activated"
fi

mkdir -p "$dumpdir"

debug_echo "Detected interface: $interface"
debug_echo "Current threshold: $threshold packets/second"
debug_echo "30000 packets/second is approximately 30 Mbps for average-sized packets."

send_to_discord() {
    local message="$1"
    local file_url="$2"
    if [ -n "$discord_webhook_url" ] && [ "$discord_webhook_url" != "YOUR_DISCORD_WEBHOOK_URL_HERE" ]; then
        curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" $discord_webhook_url
        debug_echo "Message sent to Discord."
    else
        debug_echo "Discord webhook not configured. Saving link to file."
        echo "$file_url" >> "$dumpdir/upload_links.txt"
        debug_echo "Link saved to $dumpdir/upload_links.txt"
    fi
}

create_dated_folder() {
    local date_folder="$dumpdir/$(date +"%Y-%m-%d")"
    mkdir -p "$date_folder"
    echo "$date_folder"
}

test_traffic() {
    pkt_old=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    sleep 1
    pkt_new=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    pkt=$((pkt_new - pkt_old))
    debug_echo "Current traffic: $pkt packets/second"
    
    timestamp=$(date +"%Y%m%d-%H%M%S")
    dated_folder=$(create_dated_folder)
    capture_file="$dated_folder/test_dump.$timestamp.pcap"
    debug_echo "Capturing packets for testing..."
    
    sudo tcpdump -XX -nn -vv -i "$interface" -c "$capture_count" -w "$capture_file"
    
    debug_echo "Test capture completed."
    
    upload_response=$(curl -s -F "file=@$capture_file" https://tmpfiles.org/api/v1/upload)
    file_url=$(echo "$upload_response" | grep -o 'https://tmpfiles.org/[^"]*')
    
    send_to_discord "Test capture file uploaded: $file_url" "$file_url"
}

if [ "$1" = "test" ]; then
    test_traffic
    exit 0
fi

while true; do
    pkt_old=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    sleep 1
    pkt_new=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    pkt=$((pkt_new - pkt_old))
    
    if $debug_mode; then
        echo -ne "\r$pkt packets/s\033[0K"
    fi
    
    if [ $pkt -gt $threshold ]; then
        timestamp=$(date +"%Y%m%d-%H%M%S")
        dated_folder=$(create_dated_folder)
        capture_file="$dated_folder/dump.$timestamp.pcap"
        debug_echo -e "\n$(date) Under Attack. Capturing Packets..."
        
        sudo tcpdump -XX -nn -vv -i "$interface" -c "$capture_count" -w "$capture_file"
        
        debug_echo "$(date) Packets Captured."
        
        upload_response=$(curl -s -F "file=@$capture_file" https://tmpfiles.org/api/v1/upload)
        file_url=$(echo "$upload_response" | grep -o 'https://tmpfiles.org/[^"]*')
        
        send_to_discord "New capture file uploaded: $file_url" "$file_url"
        
        debug_echo "File uploaded and link processed."
        debug_echo "Sleeping for $sleep_after_capture seconds..."
        sleep "$sleep_after_capture"
        pkill -HUP -f /usr/sbin/tcpdump
    else
        sleep 1
    fi
done