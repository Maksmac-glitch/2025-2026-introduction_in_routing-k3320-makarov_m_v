/system identity set name=R01.MSK
/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

/ip address
add address=172.16.0.1/30 interface=ether2 comment="WAN to BRL (MSK-BRL)"
add address=172.16.0.9/30 interface=ether3 comment="WAN to FRT (MSK-FRT)"
add address=10.10.10.1/24 interface=ether4 comment="LAN MSK (to PC1)"

/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes

/ip pool
add name=pool_msk ranges=10.10.10.100-10.10.10.200

/ip dhcp-server network
add address=10.10.10.0/24 gateway=10.10.10.1 dns-server=1.1.1.1,8.8.8.8

/ip dhcp-server
add name=dhcp_msk interface=ether4 address-pool=pool_msk disabled=no

# Static routes to other offices
/ip route
add dst-address=10.20.20.0/24 gateway=172.16.0.10 comment="to FRT LAN via MSK-FRT link"
add dst-address=10.30.30.0/24 gateway=172.16.0.2  comment="to BRL LAN via MSK-BRL link"
