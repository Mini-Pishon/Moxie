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
