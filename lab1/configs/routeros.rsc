/system identity set name=R01.TEST

/interface vlan
add name=vlan10 vlan-id=10 interface=ether2 comment="trunk to SW01"
add name=vlan20 vlan-id=20 interface=ether2 comment="trunk to SW01"

/ip address
add address=10.10.10.1/24 interface=vlan10 comment="GW VLAN10"
add address=10.20.20.1/24 interface=vlan20 comment="GW VLAN20"

/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes

/ip pool
add name=pool10 ranges=10.10.10.100-10.10.10.200
add name=pool20 ranges=10.20.20.100-10.20.20.200

/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1 dns-server=1.1.1.1,8.8.8.8
add address=10.20.20.0/24 gateway=10.20.20.1 dns-server=1.1.1.1,8.8.8.8

/ip dhcp-server
add name=dhcp10 interface=vlan10 address-pool=pool10 disabled=no
add name=dhcp20 interface=vlan20 address-pool=pool20 disabled=no

/user add name=netadmin group=full password=StrongPass123!
/user set admin disabled=yes
