/system identity set name=R01.LND

/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

# Loopback
/interface bridge add name=lo protocol-mode=none
/ip address add address=10.255.0.2/32 interface=lo comment=loopback

/ip address
add address=10.0.0.2/30 interface=ether2 comment="LND<->NY"
add address=10.0.0.5/30 interface=ether3 comment="LND<->HKI"

# OSPF
/routing ospf instance set [find default=yes] router-id=10.255.0.2
/routing ospf network
add network=10.255.0.2/32 area=backbone
add network=10.0.0.0/30 area=backbone
add network=10.0.0.4/30 area=backbone

# MPLS LDP
/mpls ldp set enabled=yes lsr-id=10.255.0.2 transport-address=10.255.0.2
/mpls ldp interface
add interface=ether2
add interface=ether3
