# AutomaticTCPDump

## Requirements

Requires tcpdump installed in the system.

## Usage
```bash
./capture.sh & # Run in background is default
./capture.sh debug # Run using debug mode
./capture.sh test # Run using test mode
```

## Description

The purpose of this script is to automatically detect potential network attacks by monitoring the number of packets passing through a network interface. If the packet rate exceeds a certain threshold, the script captures a sample of network traffic for further analysis.

The script takes optional input arguments. It can be run in debug mode by passing "debug" as an argument, which provides more detailed output. It also has a "test" mode that captures a sample of traffic regardless of the current packet rate.

The main output of this script is a packet capture file (.pcap) containing network traffic data. When a capture is made, the script uploads this file to a temporary file hosting service and can send a notification with the file link to a Discord channel.

To achieve its purpose, the script first identifies the main network interface and sets up some configuration variables. It then enters a loop where it continuously monitors the packet rate on the network interface. If the rate exceeds a predefined threshold (default is 30,000 packets per second), it triggers a packet capture using the tcpdump command.

The captured packets are saved to a file, which is then uploaded to a file hosting service. If configured, a notification with the file link is sent to a Discord channel. After capturing and uploading, the script waits for a set period before resuming its monitoring.

## Configuration

The script uses several configuration variables that can be modified to suit your needs. These variables are defined at the beginning of the script and include the packet count threshold, the capture count, the interval after capture, and the Discord webhook URL.

```bash
# Packet count threshold
threshold=30000 ## 30000 is the default
## Capture Count
capture_count=5000 ## 5000 is the default
# Interval after capture
sleep_after_capture=230 ## 230 is the default
# Discord webhook URL
discord_webhook_url="YOUR_DISCORD_WEBHOOK_URL_HERE" ## Set your Discord webhook URL here
```