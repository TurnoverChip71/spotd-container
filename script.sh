#!/bin/bash

# Download Debian 12 template if not already downloaded
pveam update
pveam download local debian-12-standard_12.2-1_amd64.tar.zst

# Create container with ID 108
pct create 108 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst \
  --hostname monitors-spotify \
  --cores 1 \
  --memory 512 \
  --swap 512 \
  --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,type=veth \
  --rootfs local-lvm:8 \
  --features nesting=1 \
  --unprivileged 1

# Start the container
pct start 108
sleep 5

# Install dependencies inside container
pct exec 108 -- bash -c "
apt update &&
apt install -y wget curl libpulse0 pulseaudio alsa-utils ca-certificates
"

# Install spotifyd
pct exec 108 -- bash -c "
cd /usr/local/bin &&
wget https://github.com/Spotifyd/spotifyd/releases/latest/download/spotifyd-linux-x86_64.tar.gz &&
tar -xzf spotifyd-linux-x86_64.tar.gz &&
chmod +x spotifyd &&
rm spotifyd-linux-x86_64.tar.gz
"

# Create config directory
pct exec 108 -- bash -c "
mkdir -p /root/.config/spotifyd &&
cat > /root/.config/spotifyd/spotifyd.conf <<EOF
[global]
device_name = Monitors
backend = pulseaudio
bitrate = 320
volume_ctrl = softvol
EOF
"

# Final instructions
echo "✅ Done! Attach with: pct attach 108"
echo "Then run: spotifyd --no-daemon --config-path /root/.config/spotifyd/spotifyd.conf"
