#!/bin/bash
set -x

echo "Ussage: connect.sh interface ssid"
iface=$1
network=$2

ip link set $iface down
killall dhclient
killall -q wpa_supplicant
service network-manager stop
iw reg set GY
iwconfig $iface txpower 30
macchanger -r $iface
ip link set $iface up

echo -e 'Connecting to: ' $network
wpa_supplicant -B -i $iface -c /root/git/letmein/networks/"$network"_wpa_supplicant.conf
dhclient -r
dhclient $iface
echo -e 'Connected.'
