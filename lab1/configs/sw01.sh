#!/bin/sh
set -eux

hostname SW01.L3.01.TEST || true

ip link add br0 type bridge vlan_filtering 1
ip link set br0 up

for p in eth1 eth2 eth3; do
  ip link set "$p" up
  ip link set "$p" master br0
done

# VLAN 10/20 на мосту
bridge vlan add dev br0 vid 10 self
bridge vlan add dev br0 vid 20 self

# trunk ports: eth1 (к R01), eth2/eth3 (к SW02_x) — tagged 10/20
for p in eth1 eth2 eth3; do
  bridge vlan add dev "$p" vid 10
  bridge vlan add dev "$p" vid 20
done

bridge vlan show
