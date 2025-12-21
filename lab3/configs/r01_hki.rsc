/system identity set name=R01.HKI

/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

# Loopback
/interface bridge add name=lo protocol-mode=none
/ip address add address=10.255.0.3/32 interface=lo comment=loopback

/ip address
add address=10.0.0.6/30 interface=ether2 comment="HKI<->LND"
add address=10.0.0.9/30 interface=ether3 comment="HKI<->SPB"
add address=10.0.0.25/30 interface=ether4 comment="HKI<->LBN (extra)"

# OSPF
/routing ospf instance set [find default=yes] router-id=10.255.0.3
/routing ospf network
add network=10.255.0.3/32 area=backbone
add network=10.0.0.4/30 area=backbone
add network=10.0.0.8/30 area=backbone
add network=10.0.0.24/30 area=backbone

# MPLS LDP
/mpls ldp set enabled=yes lsr-id=10.255.0.3 transport-address=10.255.0.3
/mpls ldp interface
add interface=ether2
add interface=ether3
add interface=ether4
