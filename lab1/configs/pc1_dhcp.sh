#!/bin/sh
set -eux
ip link set eth1 up
( dhclient -v eth1 ) || ( udhcpc -i eth1 )
ip route add 10.20.20.0/24 via 10.10.10.1 dev eth1 2>/dev/null || true
ip -4 a show eth1
ip r
