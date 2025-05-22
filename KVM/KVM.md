# Bridging KVM on a WIFI adapter

KVM said this was not possible. It's true. We need to find a workaround. It works well, I swear.

- Find the name of your wireless NIC
```BASH
ip -c address
```

- Try this :
    - You might need to install `parprouted`.
    - The IPv4 address of br-tap does not needs to be within the network you want to be bridged into.
    - Your user will need to own the tap.
    - Make sure you change the interface name to what `ip -c address` showed you.
git@github.com:beanbat/Moxie.git
    - You'll need some tricks to kinda NAT (I read somewhere on the internet that this is what VirtualBox does.

```BASH
sudo ip link add name br-tap type bridge && \
sudo ip addr add 192.168.200.100/24 dev br-tap && \
sudo ip link set br-tap up && \
sudo ip tuntap add mode tap tap0 user $(whoami) && \
sudo ip link set tap0 master br-tap && \
sudo ip link set tap0 up && \
sudo parprouted wlp0s20f3 br-tap && \
sudo iptables -A FORWARD -i br-tap -j ACCEPT && \
sudo iptables -A FORWARD -o br-tap -j ACCEPT
```

- In case you want to make this survive after a reboot, you need to save your iptables configuration.
    - install iptables-persistent if you do not have it installed already.
    - save your rules so they'll start at boot.

```BASH
sudo apt install -y iptables-persistent
```
```BASH
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```
- Depending on your desktop environement, you might want to tell the piece of software that manage your network "DON'T TOUCH MY CONFIGURATION". Here's what I use for `NetworkManager`.
    - Check if NetworkManager sees your new configuration (if we did good, it should show).
```BASH
nmcli connection show
```

- This line will tell NetworkManager "don't manage my tap". 
```BASH
echo -e "[keyfile]\nunmanaged-devices=interface-name:br-tap" | sudo tee /etc/NetworkManager/conf.d/99-ignore-br-tap.conf > /dev/null
```
- It's time to reload NetworkManager now.
- And check with `nmcli`. You should NOT see your br-tap.
```BASH
sudo systemctl restart NetworkManager
```
```BASH
nmcli connection show
```

Enjoy, bye.

> EDIT : this thing still does not survive after a f$cking reboot. Need to check later.


> POST EDIT : it can survive a reboot with a script and systemd


- You need to create a script to make it survive post reboot. 

``` BASH 
#!/usr/bin/env bash
# /usr/local/bin/kvm-wifi-bridge.sh
# Creates br-tap, tap0 and starts parprouted for a Wi-Fi → KVM bridge

set -euo pipefail

# === CONFIGURATION ===
# Name of your Wi-Fi interface (check with `ip -c addr`)
WIFI_IF="wlo1"

# Names of the bridge and tap device
BRIDGE="br-tap"
TAP="tap0"

# Dummy IP for the bridge (can be outside DHCP range)
BR_IP="192.168.200.100/24"
# ======================

# 1) Create the bridge if it doesn’t exist
ip link show dev "$BRIDGE" &>/dev/null || \
  ip link add name "$BRIDGE" type bridge

# 2) (Re)configure the IP on the bridge
ip addr flush dev "$BRIDGE"
ip addr add "$BR_IP" dev "$BRIDGE"

# 3) Bring the bridge up
ip link set dev "$BRIDGE" up

# 4) Create the tap device if it’s missing, owned by the current user
ip tuntap show | grep -q "$TAP" || \
  ip tuntap add mode tap "$TAP" user "$(whoami)"

# 5) Attach the tap to the bridge
ip link set dev "$TAP" master "$BRIDGE"
ip link set dev "$TAP" up

# 6) Launch parprouted for ARP proxy between Wi-Fi and br-tap
#    (the & prevents blocking the script)
pkill parprouted || true
/usr/sbin/parprouted "$WIFI_IF" "$BRIDGE" &>/dev/null &
``` 

- Then, make it executable
```BASH
sudo chmod +x /usr/local/bin/kvm-wifi-bridge.sh
```

- You need to use systemd to make it work after every reboot

```BASH
[Unit]
Description=KVM Wi-Fi Bridge (br-tap + tap0 + parprouted)
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/kvm-wifi-bridge.sh
ExecStop=/usr/bin/ip link delete br-tap type bridge || true

[Install]
WantedBy=multi-user.target
```

- Then, activate

```BASH
sudo systemctl daemon-reload
sudo systemctl enable kvm-wifi-bridge.service
sudo systemctl start  kvm-wifi-bridge.service
```

- You can check if everything worked 

```BASH
systemctl status kvm-wifi-bridge.service
ip -c addr show br-tap tap0
```

Enjoy :)

