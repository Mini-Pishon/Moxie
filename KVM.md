- Bridging KVM on a WIFI adapter

```BASH
sudo ip link add name br-tap type bridge
sudo ip addr add 192.168.200.100/24 dev br-tap
sudo ip link set br-tap up
sudo ip tuntap add mode tap tap0 user $(whoami)
sudo ip link set tap0 master br-tap
sudo ip link set tap0 up
sudo parprouted wlp0s20f3 br-tap
sudo iptables -A FORWARD -i br-tap -j ACCEPT
sudo iptables -A FORWARD -o br-tap -j ACCEPT
```
