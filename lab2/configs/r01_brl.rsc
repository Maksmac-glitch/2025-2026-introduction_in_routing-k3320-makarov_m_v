/system identity set name=R01.BRL
/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

/ip address
add address=172.16.0.2/30 interface=ether2 comment="WAN to MSK (MSK-BRL)"
add address=172.16.0.5/30 interface=ether3 comment="WAN to FRT (BRL-FRT)"
add address=10.30.30.1/24 interface=ether4 comment="LAN BRL (to PC3)"

/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes

/ip pool
add name=pool_brl ranges=10.30.30.100-10.30.30.200

/ip dhcp-server network
add address=10.30.30.0/24 gateway=10.30.30.1 dns-server=1.1.1.1,8.8.8.8

/ip dhcp-server
add name=dhcp_brl interface=ether4 address-pool=pool_brl disabled=no

/ip route
add dst-address=10.10.10.0/24 gateway=172.16.0.1 comment="to MSK LAN via MSK-BRL link"
add dst-address=10.20.20.0/24 gateway=172.16.0.6 comment="to FRT LAN via BRL-FRT link"
