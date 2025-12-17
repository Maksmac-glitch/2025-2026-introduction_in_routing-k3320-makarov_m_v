#!/bin/sh
set -eux

hostname SW02.L3.02.TEST || true

ip link add br0 type bridge vlan_filtering 1
ip link set br0 up

for p in eth1 eth2; do
  ip link set "$p" up
  ip link set "$p" master br0
done

bridge vlan add dev br0 vid 10 self
bridge vlan add dev br0 vid 20 self

# trunk eth1 tagged
bridge vlan add dev eth1 vid 10
bridge vlan add dev eth1 vid 20

# access eth2 untagged VLAN20 + PVID 20
bridge vlan add dev eth2 vid 20 pvid untagged

bridge vlan show
