#!/bin/sh
set -e

# SGI Prism EoMPLS
ip link set eth1 up
ip addr flush dev eth1 || true
ip addr add 192.168.100.10/24 dev eth1

echo "SGI Prism configured:"
ip -4 addr show eth1
ip route | sed -n '1,30p'
