#!/bin/bash

# Turns Raspberry Pi OS Bullseye into a Router
# Provides internet access (from wifi) to ethernet devices
# Also provides DHCP-server to ethernet devices
#
# IMPORTANT:
# - tested on Raspberry Pi 3B+
# - tested on Raspberry Pi OS Bullseye lite
# - make sure 'dnsmasq', 'iptables', and 'iptables-persistent' are installed
# - WiFi connection should be already established
# - ethernet cable should be already plugged in
# - don't forget to make script executable (chmod +x <file>) ;)

ip_addr="192.168.2.1"
routers="192.168.2.0"
dhcp_range_start="192.168.2.2"
dhcp_range_end="192.168.2.254"
dhcp_time="12h"
dns_server="1.1.1.1"
eth="eth0"
wlan="wlan0"

# backup of original dhcpcd.conf
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak

# append to /etc/dhcpcd.conf
sudo sh -c "echo -e 'interface $eth\n\
static ip_address=$ip_addr/24\n\
static routers=$routers' >> /etc/dhcpcd.conf"

sudo service dhcpcd restart

sudo service dnsmasq stop

# edit /etc/dnsmasq.conf
sudo sh -c "echo -e 'interface=$eth\n\
listen-address=$ip_addr\n\
bind-interfaces\n\
server=$dns_server\n\
domain-needed\n\
bogus-priv\n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time' > /etc/dnsmasq.conf"

# add iptables-persistent rules
sudo sh -c "echo -e '-t nat -A POSTROUTING -o wlan0 -j MASQUERADE\n\
-A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT\n\
-A FORWARD -i eth0 -o wlan0 -j ACCEPT' > /etc/iptables/rules.v4"

# backup of original sysctl.conf
sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak

# edit /etc/sysctl.conf
# also disables ipv6 for whole system(!)
sudo sh -c "echo 'net.ipv4.ip_forward=1\n\
net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf"

sudo sysctl -p

sudo service dnsmasq start