/system identity set name=R01.FRT
/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

/ip address
add address=172.16.0.6/30 interface=ether2 comment="WAN to BRL (BRL-FRT)"
add address=172.16.0.10/30 interface=ether3 comment="WAN to MSK (MSK-FRT)"
add address=10.20.20.1/24 interface=ether4 comment="LAN FRT (to PC2)"

/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes

/ip pool
add name=pool_frt ranges=10.20.20.100-10.20.20.200

/ip dhcp-server network
add address=10.20.20.0/24 gateway=10.20.20.1 dns-server=1.1.1.1,8.8.8.8

/ip dhcp-server
add name=dhcp_frt interface=ether4 address-pool=pool_frt disabled=no

/ip route
add dst-address=10.10.10.0/24 gateway=172.16.0.9 comment="to MSK LAN via MSK-FRT link"
add dst-address=10.30.30.0/24 gateway=172.16.0.5 comment="to BRL LAN via BRL-FRT link"
