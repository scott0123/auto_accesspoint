#!/bin/bash

# Redundant stops to make sure services are not running
echo "Stopping network services (if running)..."
systemctl stop hostapd
systemctl stop dnsmasq
systemctl stop dhcpcd

#Make sure no uap0 interface exists (this generates an error; we could probably use an if statement to check if it exists first)
echo "Removing uap0 interface..."
iw dev uap0 del

#Add uap0 interface (this is dependent on the wireless interface being called wlan0, which it may not be in Stretch)
echo "Adding uap0 interface..."
iw dev wlan0 interface add uap0 type __ap

#Modify iptables (these can probably be saved using iptables-persistent if desired)
echo "IPV4 forwarding: setting..."
sysctl net.ipv4.ip_forward=1
echo "Editing IP tables..."
iptables -t nat -A POSTROUTING -s 192.168.50.0/24 ! -d 192.168.50.0/24 -j MASQUERADE

# Bring up uap0 interface. Commented out line may be a possible alternative to using dhcpcd.conf to set up the IP address.
#ifconfig uap0 192.168.50.1 netmask 255.255.255.0 broadcast 192.168.50.255
ifconfig uap0 up

# Start hostapd. 10-second sleep avoids some race condition, apparently. It may not need to be that long. (?)
echo "Starting hostapd service..."
systemctl start hostapd
sleep 10

#Start dhcpcd. Again, a 5-second sleep
echo "Starting dhcpcd service..."
systemctl start dhcpcd
sleep 5

echo "Starting dnsmasq service..."
systemctl start dnsmasq
echo "auto_accesspoint DONE"
