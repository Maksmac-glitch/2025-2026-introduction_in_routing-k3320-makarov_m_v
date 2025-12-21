#!/bin/sh
set -e

# PC1 SPB
ip link set eth1 up
ip addr flush dev eth1 || true
ip addr add 192.168.100.20/24 dev eth1

echo "PC1 configured:"
ip -4 addr show eth1
ip route | sed -n '1,30p'
