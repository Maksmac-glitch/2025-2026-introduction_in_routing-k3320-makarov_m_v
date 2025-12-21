#!/bin/sh
set -eux
ip link set eth1 up
( dhclient -v eth1 ) || ( udhcpc -i eth1 )
ip route del default dev eth0 2>/dev/null || true

ip -4 a show eth1
ip r
