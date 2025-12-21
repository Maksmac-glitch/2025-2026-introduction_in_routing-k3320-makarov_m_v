/system identity set name=R01.SPB

/user set admin password=Admin123!
/user add name=admin2 group=full password=Admin321!

# Loopback
/interface bridge add name=lo protocol-mode=none
/ip address add address=10.255.0.4/32 interface=lo comment=loopback

/ip address
add address=10.0.0.10/30 interface=ether2 comment="SPB<->HKI"
add address=10.0.0.13/30 interface=ether3 comment="SPB<->MSK"

# OSPF
/routing ospf instance set [find default=yes] router-id=10.255.0.4
/routing ospf network
add network=10.255.0.4/32 area=backbone
add network=10.0.0.8/30 area=backbone
add network=10.0.0.12/30 area=backbone

# MPLS LDP
/mpls ldp set enabled=yes lsr-id=10.255.0.4 transport-address=10.255.0.4
/mpls ldp interface
add interface=ether2
add interface=ether3

# EoMPLS VPLS
/interface vpls
add name=vpls_to_ny remote-peer=10.255.0.1 vpls-id=100:1 pw-type=raw-ethernet use-control-word=no disabled=no
/interface bridge add name=br_eompls protocol-mode=none
/interface bridge port
add bridge=br_eompls interface=ether4
add bridge=br_eompls interface=vpls_to_ny
