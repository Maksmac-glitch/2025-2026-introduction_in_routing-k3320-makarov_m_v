University: [ITMO University](https://itmo.ru/ru/)
Faculty: [FICT](https://fict.itmo.ru/)
Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
Year: 2025
Group: K3320
Author: Makarov Maksim Vyacheslavovich
Lab: Lab3
Date of create: 21.12.2025
Date of finished: 

# Лабораторная работа №3 - OSPF + MPLS + EoMPLS (VPLS)

## 1. Цель работы

Изучить протоколы OSPF и MPLS, механизмы организации EoMPLS. 

Поднять в ContainerLab IP/MPLS сеть компании RogaIKopita Games, настроить:
- IP-адресацию между роутерами
- OSPF
- MPLS и LDP
- EoMPLS между офисом New York (SGI Prism) и офисом Saint-Petersburg (PC1)

---

## 2. Топология
Схема: `lab3.drawio`

Устройства:
- 6 роутеров MikroTik: R01.NY, R01.LND, R01.HKI, R01.SPB, R01.MSK, R01.LBN
- 2 linux-контейнера: `sgi_prism` и `pc1_spb`

---

## 3. План

### 3.1. Loopback (/32) — для Router-ID OSPF и LSR-ID MPLS
- R01.NY  : 10.255.0.1/32
- R01.LND : 10.255.0.2/32
- R01.HKI : 10.255.0.3/32
- R01.SPB : 10.255.0.4/32
- R01.MSK : 10.255.0.5/32
- R01.LBN : 10.255.0.6/32

### 3.2. P2P линк-сети (/30)
- NY—LND   : 10.0.0.0/30  (NY=10.0.0.1, LND=10.0.0.2)
- LND—HKI  : 10.0.0.4/30  (LND=10.0.0.5, HKI=10.0.0.6)
- HKI—SPB  : 10.0.0.8/30  (HKI=10.0.0.9, SPB=10.0.0.10)
- SPB—MSK  : 10.0.0.12/30 (SPB=10.0.0.13, MSK=10.0.0.14)
- MSK—LBN  : 10.0.0.16/30 (MSK=10.0.0.17, LBN=10.0.0.18)
- LBN—NY   : 10.0.0.20/30 (LBN=10.0.0.21, NY=10.0.0.22)
- HKI—LBN  : 10.0.0.24/30 (HKI=10.0.0.25, LBN=10.0.0.26)

### 3.3. L2-сеть для EoMPLS (на linux-контейнерах)
- 192.168.100.10/24 — SGI Prism
- 192.168.100.20/24 — PC1 (SPB)

---

## 4. Развертывание сети в ContainerLab

### 4.1. Деплой
```bash
cd /home/deltra/intro_in_routing/lab3
sudo containerlab deploy -t lab3.clab.yaml
sudo containerlab inspect -t lab3.clab.yaml
```

Вывод:
```bash
╭─────────────────────┬───────────────────────────────────────────┬───────────┬────────────────╮
│         Name        │                 Kind/Image                │   State   │ IPv4/6 Address │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-pc1_spb   │ linux                                     │ running   │ 172.20.40.22   │
│                     │ ghcr.io/srl-labs/network-multitool:latest │           │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_hki   │ mikrotik_ros                              │ running   │ 172.20.40.13   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_lbn   │ mikrotik_ros                              │ running   │ 172.20.40.16   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_lnd   │ mikrotik_ros                              │ running   │ 172.20.40.12   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_msk   │ mikrotik_ros                              │ running   │ 172.20.40.15   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_ny    │ mikrotik_ros                              │ running   │ 172.20.40.11   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-r01_spb   │ mikrotik_ros                              │ running   │ 172.20.40.14   │
│                     │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├─────────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab3-sgi_prism │ linux                                     │ running   │ 172.20.40.21   │
│                     │ ghcr.io/srl-labs/network-multitool:latest │           │ N/A            │
╰─────────────────────┴───────────────────────────────────────────┴───────────┴────────────────╯

```

---

## 5. Настройка роутеров (RouterOS)

Пример R01.NY (IP: 172.20.40.11):
```bash
scp -o StrictHostKeyChecking=no configs/r01_ny.rsc admin@172.20.40.11:r01_ny.rsc
ssh -o StrictHostKeyChecking=no admin@172.20.40.11
/import file-name=r01_ny.rsc
```

---

## 6. Настройка контейнеров SGI Prism и PC1 (статическая адресация)

```bash
docker cp configs/sgi_static.sh clab-lab3-sgi_prism:/sgi_static.sh
docker exec -it clab-lab3-sgi_prism sh /sgi_static.sh

docker cp configs/pc1_static.sh clab-lab3-pc1_spb:/pc1_static.sh
docker exec -it clab-lab3-pc1_spb sh /pc1_static.sh
```

---

## 7. Проверки

### 7.1. OSPF: соседства
На любом роутере:
```routeros
/routing ospf neighbor print
/ip route print where ospf
```
NY:
```bash
[admin@R01.NY] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.6 address=10.0.0.21 
   interface=ether3 priority=1 dr-address=10.0.0.22 
   backup-dr-address=10.0.0.21 state="Full" state-changes=5 
   ls-retransmits=0 ls-requests=0 db-summaries=0 adjacency=32m38s 

 1 instance=default router-id=10.255.0.2 address=10.0.0.2 
   interface=ether2 priority=1 dr-address=10.0.0.1 
   backup-dr-address=10.0.0.2 state="Full" state-changes=5 
   ls-retransmits=0 ls-requests=0 db-summaries=0 adjacency=36m57s 
[admin@R01.NY] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, 
C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.4/30                        10.0.0.2                110
 1 ADo  10.0.0.8/30                        10.0.0.2                110
                                           10.0.0.21         
 2 ADo  10.0.0.12/30                       10.0.0.21               110
 3 ADo  10.0.0.16/30                       10.0.0.21               110
 4 ADo  10.0.0.24/30                       10.0.0.21               110
 5 ADo  10.255.0.2/32                      10.0.0.2                110
 6 ADo  10.255.0.3/32                      10.0.0.2                110
                                           10.0.0.21         
 7 ADo  10.255.0.4/32                      10.0.0.2                110
                                           10.0.0.21         
 8 ADo  10.255.0.5/32                      10.0.0.21               110
 9 ADo  10.255.0.6/32                      10.0.0.21               110

```

LND:
```bash
[admin@R01.LND] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.3 address=10.0.0.6 
   interface=ether3 priority=1 dr-address=10.0.0.5 
   backup-dr-address=10.0.0.6 state="Full" state-changes=5 
   ls-retransmits=0 ls-requests=0 db-summaries=0 adjacency=37m58s 

 1 instance=default router-id=10.255.0.1 address=10.0.0.1 
   interface=ether2 priority=1 dr-address=10.0.0.1 
   backup-dr-address=10.0.0.2 state="Full" state-changes=5 
   ls-retransmits=0 ls-requests=0 db-summaries=0 adjacency=39m17s 
[admin@R01.LND] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, 
C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.8/30                        10.0.0.6                110
 1 ADo  10.0.0.12/30                       10.0.0.6                110
 2 ADo  10.0.0.16/30                       10.0.0.1                110
                                           10.0.0.6          
 3 ADo  10.0.0.20/30                       10.0.0.1                110
 4 ADo  10.0.0.24/30                       10.0.0.6                110
 5 ADo  10.255.0.1/32                      10.0.0.1                110
 6 ADo  10.255.0.3/32                      10.0.0.6                110
 7 ADo  10.255.0.4/32                      10.0.0.6                110
 8 ADo  10.255.0.5/32                      10.0.0.1                110
                                           10.0.0.6          
 9 ADo  10.255.0.6/32                      10.0.0.1                110
                                           10.0.0.6         

```

HKI:
```bash
[admin@R01.HKI] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.6 address=10.0.0.26 interface=ether4 priority=1 dr-address=10.0.0.25 
   backup-dr-address=10.0.0.26 state="Full" state-changes=4 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=39m53s 

 1 instance=default router-id=10.255.0.4 address=10.0.0.10 interface=ether3 priority=1 dr-address=10.0.0.9 
   backup-dr-address=10.0.0.10 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=41m53s 

 2 instance=default router-id=10.255.0.2 address=10.0.0.5 interface=ether2 priority=1 dr-address=10.0.0.5 
   backup-dr-address=10.0.0.6 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=42m55s 
[admin@R01.HKI] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.0/30                        10.0.0.5                110
 1 ADo  10.0.0.12/30                       10.0.0.10               110
 2 ADo  10.0.0.16/30                       10.0.0.26               110
 3 ADo  10.0.0.20/30                       10.0.0.26               110
 4 ADo  10.255.0.1/32                      10.0.0.5                110
                                           10.0.0.26         
 5 ADo  10.255.0.2/32                      10.0.0.5                110
 6 ADo  10.255.0.4/32                      10.0.0.10               110
 7 ADo  10.255.0.5/32                      10.0.0.10               110
                                           10.0.0.26         
 8 ADo  10.255.0.6/32                      10.0.0.26               110

```

SPB:
```bash
[admin@R01.SPB] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.5 address=10.0.0.14 interface=ether3 priority=1 dr-address=10.0.0.13 
   backup-dr-address=10.0.0.14 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=43m35s 

 1 instance=default router-id=10.255.0.3 address=10.0.0.9 interface=ether2 priority=1 dr-address=10.0.0.9 
   backup-dr-address=10.0.0.10 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=44m34s 
[admin@R01.SPB] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.0/30                        10.0.0.9                110
 1 ADo  10.0.0.4/30                        10.0.0.9                110
 2 ADo  10.0.0.16/30                       10.0.0.14               110
 3 ADo  10.0.0.20/30                       10.0.0.9                110
                                           10.0.0.14         
 4 ADo  10.0.0.24/30                       10.0.0.9                110
 5 ADo  10.255.0.1/32                      10.0.0.9                110
                                           10.0.0.14         
 6 ADo  10.255.0.2/32                      10.0.0.9                110
 7 ADo  10.255.0.3/32                      10.0.0.9                110
 8 ADo  10.255.0.5/32                      10.0.0.14               110
 9 ADo  10.255.0.6/32                      10.0.0.9                110
                                           10.0.0.14         

```

MSK:
```bash
[admin@R01.MSK] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.6 address=10.0.0.18 interface=ether3 priority=1 dr-address=10.0.0.17 
   backup-dr-address=10.0.0.18 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=44m52s 

 1 instance=default router-id=10.255.0.4 address=10.0.0.13 interface=ether2 priority=1 dr-address=10.0.0.13 
   backup-dr-address=10.0.0.14 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=45m58s 
[admin@R01.MSK] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.0/30                        10.0.0.18               110
 1 ADo  10.0.0.4/30                        10.0.0.13               110
                                           10.0.0.18         
 2 ADo  10.0.0.8/30                        10.0.0.13               110
 3 ADo  10.0.0.20/30                       10.0.0.18               110
 4 ADo  10.0.0.24/30                       10.0.0.18               110
 5 ADo  10.255.0.1/32                      10.0.0.18               110
 6 ADo  10.255.0.2/32                      10.0.0.13               110
                                           10.0.0.18         
 7 ADo  10.255.0.3/32                      10.0.0.13               110
                                           10.0.0.18         
 8 ADo  10.255.0.4/32                      10.0.0.13               110
 9 ADo  10.255.0.6/32                      10.0.0.18               110

```

LBN:
```bash
[admin@R01.LBN] > /routing ospf neighbor print
 0 instance=default router-id=10.255.0.5 address=10.0.0.17 interface=ether2 priority=1 dr-address=10.0.0.17 
   backup-dr-address=10.0.0.18 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=47m18s 

 1 instance=default router-id=10.255.0.3 address=10.0.0.25 interface=ether4 priority=1 dr-address=10.0.0.25 
   backup-dr-address=10.0.0.26 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=47m22s 

 2 instance=default router-id=10.255.0.1 address=10.0.0.22 interface=ether3 priority=1 dr-address=10.0.0.22 
   backup-dr-address=10.0.0.21 state="Full" state-changes=5 ls-retransmits=0 ls-requests=0 db-summaries=0 
   adjacency=47m23s 
[admin@R01.LBN] > /ip route print where ospf
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADo  10.0.0.0/30                        10.0.0.22               110
 1 ADo  10.0.0.4/30                        10.0.0.25               110
 2 ADo  10.0.0.8/30                        10.0.0.25               110
 3 ADo  10.0.0.12/30                       10.0.0.17               110
 4 ADo  10.255.0.1/32                      10.0.0.22               110
 5 ADo  10.255.0.2/32                      10.0.0.22               110
                                           10.0.0.25         
 6 ADo  10.255.0.3/32                      10.0.0.25               110
 7 ADo  10.255.0.4/32                      10.0.0.25               110
                                           10.0.0.17         
 8 ADo  10.255.0.5/32                      10.0.0.17               110


```

### 7.2. MPLS/LDP: соседи и таблица меток
```routeros
/mpls ldp neighbor print
/mpls forwarding-table print
```
NY:
```bash
[admin@R01.NY] > /mpls ldp neighbor print
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DOTV 10.255.0.4      10.255.0.1      10.255.0.4:0               yes           10.0.0.10      
                                                                                 10.0.0.13      
                                                                                 10.255.0.4     
 1 DO   10.255.0.2      10.255.0.1      10.255.0.2:0               no            10.0.0.2       
                                                                                 10.0.0.5       
                                                                                 10.255.0.2     
                                                                                 172.31.255.30  
 2 DO   10.255.0.6      10.255.0.1      10.255.0.6:0               no            10.0.0.18      
                                                                                 10.0.0.21      
                                                                                 10.0.0.26      
                                                                                 10.255.0.6     
[admin@R01.NY] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                                      10.255.0.2/32                  ether2             10.0.0.2       
 2  L 17                                      10.0.0.4/30                    ether2             10.0.0.2       
 3  L 18                  18                  10.0.0.8/30                    ether2             10.0.0.2       
 4  L 19                                      10.0.0.24/30                   ether3             10.0.0.21      
 5  L 20                  20                  10.255.0.3/32                  ether2             10.0.0.2       
 6  L 21                  19                  10.0.0.12/30                   ether3             10.0.0.21      
 7  L 22                  22                  10.255.0.4/32                  ether2             10.0.0.2       
 8  V 23                                      vpls_to_spb                   
 9  L 24                                      10.0.0.16/30                   ether3             10.0.0.21      
10  L 25                  17                  10.255.0.5/32                  ether3             10.0.0.21      
11  L 26                                      10.255.0.6/32                  ether3             10.0.0.21      

```

LND:
```bash
[admin@R01.LND] > /mpls ldp neighbor print    
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DO   10.255.0.1      10.255.0.2      10.255.0.1:0               no            10.0.0.1       
                                                                                 10.0.0.22      
                                                                                 10.255.0.1     
                                                                                 172.31.255.30  
 1 DO   10.255.0.3      10.255.0.2      10.255.0.3:0               no            10.0.0.6       
                                                                                 10.0.0.9       
                                                                                 10.0.0.25      
                                                                                 10.255.0.3     
[admin@R01.LND] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                                      10.255.0.1/32                  ether2             10.0.0.1       
 2  L 17                                      10.0.0.20/30                   ether2             10.0.0.1       
 3  L 18                                      10.0.0.8/30                    ether3             10.0.0.6       
 4  L 19                                      10.0.0.24/30                   ether3             10.0.0.6       
 5  L 20                                      10.255.0.3/32                  ether3             10.0.0.6       
 6  L 21                  20                  10.0.0.12/30                   ether3             10.0.0.6       
 7  L 22                  21                  10.255.0.4/32                  ether3             10.0.0.6       
 8  L 23                  24                  10.0.0.16/30                   ether2             10.0.0.1       
 9  L 24                  25                  10.255.0.5/32                  ether2             10.0.0.1       
10  L 25                  26                  10.255.0.6/32                  ether2             10.0.0.1       

```

HKI:
```bash
[admin@R01.HKI] > /mpls ldp neighbor print
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DO   10.255.0.2      10.255.0.3      10.255.0.2:0               no            10.0.0.2       
                                                                                 10.0.0.5       
                                                                                 10.255.0.2     
                                                                                 172.31.255.30  
 1 DO   10.255.0.4      10.255.0.3      10.255.0.4:0               no            10.0.0.10      
                                                                                 10.0.0.13      
                                                                                 10.255.0.4     
 2 DO   10.255.0.6      10.255.0.3      10.255.0.6:0               no            10.0.0.18      
                                                                                 10.0.0.21      
                                                                                 10.0.0.26      
                                                                                 10.255.0.6     
[admin@R01.HKI] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                                      10.0.0.20/30                   ether4             10.0.0.26      
 2  L 17                                      10.0.0.0/30                    ether2             10.0.0.5       
 3  L 18                                      10.255.0.2/32                  ether2             10.0.0.5       
 4  L 19                  16                  10.255.0.1/32                  ether2             10.0.0.5       
 5  L 20                                      10.0.0.12/30                   ether3             10.0.0.10      
 6  L 21                                      10.255.0.4/32                  ether3             10.0.0.10      
 7  L 22                                      10.0.0.16/30                   ether4             10.0.0.26      
 8  L 23                  25                  10.255.0.5/32                  ether3             10.0.0.10      
 9  L 24                                      10.255.0.6/32                  ether4             10.0.0.26
```

SBP:
```bash
[admin@R01.SPB] > /mpls ldp neighbor print
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DO   10.255.0.3      10.255.0.4      10.255.0.3:0               no            10.0.0.6       
                                                                                 10.0.0.9       
                                                                                 10.0.0.25      
                                                                                 10.255.0.3     
                                                                                 172.31.255.30  
 1 DOTV 10.255.0.1      10.255.0.4      10.255.0.1:0               yes           10.0.0.1       
                                                                                 10.0.0.22      
                                                                                 10.255.0.1     
 2 DO   10.255.0.5      10.255.0.4      10.255.0.5:0               no            10.0.0.14      
                                                                                 10.0.0.17      
                                                                                 10.255.0.5     
[admin@R01.SPB] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                                      10.0.0.24/30                   ether2             10.0.0.9       
 2  L 17                  17                  10.0.0.0/30                    ether2             10.0.0.9       
 3  L 18                  18                  10.255.0.2/32                  ether2             10.0.0.9       
 4  L 19                                      10.0.0.4/30                    ether2             10.0.0.9       
 5  L 20                                      10.255.0.3/32                  ether2             10.0.0.9       
 6  L 21                  19                  10.255.0.1/32                  ether2             10.0.0.9       
 7  L 22                  16                  10.0.0.20/30                   ether2             10.0.0.9       
 8  V 23                                      vpls_to_ny                    
 9  L 24                                      10.0.0.16/30                   ether3             10.0.0.14      
10  L 25                                      10.255.0.5/32                  ether3             10.0.0.14      
11  L 26                  24                  10.255.0.6/32                  ether2             10.0.0.9  
```

MSK:
```bash
[admin@R01.MSK] > /mpls ldp neighbor print
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DO   10.255.0.4      10.255.0.5      10.255.0.4:0               no            10.0.0.10      
                                                                                 10.0.0.13      
                                                                                 10.255.0.4     
                                                                                 172.31.255.30  
 1 DO   10.255.0.6      10.255.0.5      10.255.0.6:0               no            10.0.0.18      
                                                                                 10.0.0.21      
                                                                                 10.0.0.26      
                                                                                 10.255.0.6     
[admin@R01.MSK] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                                      10.0.0.20/30                   ether3             10.0.0.18      
 2  L 17                  18                  10.255.0.2/32                  ether2             10.0.0.13      
 3  L 18                                      10.0.0.24/30                   ether3             10.0.0.18      
 4  L 19                  18                  10.0.0.0/30                    ether3             10.0.0.18      
 5  L 20                  20                  10.255.0.1/32                  ether3             10.0.0.18      
 6  L 21                                      10.255.0.4/32                  ether2             10.0.0.13      
 7  L 22                  19                  10.0.0.4/30                    ether2             10.0.0.13      
 8  L 23                  20                  10.255.0.3/32                  ether2             10.0.0.13      
 9  L 24                                      10.0.0.8/30                    ether2             10.0.0.13      
10  L 25                                      10.255.0.6/32                  ether3             10.0.0.18  
```

LBN:
```bash
[admin@R01.LBN] > /mpls ldp neighbor print
Flags: X - disabled, D - dynamic, O - operational, T - sending-targeted-hello, V - vpls 
 #      TRANSPORT       LOCAL-TRANSPORT PEER                       SEND-TARGETED ADDRESSES      
 0 DO   10.255.0.1      10.255.0.6      10.255.0.1:0               no            10.0.0.1       
                                                                                 10.0.0.22      
                                                                                 10.255.0.1     
                                                                                 172.31.255.30  
 1 DO   10.255.0.3      10.255.0.6      10.255.0.3:0               no            10.0.0.6       
                                                                                 10.0.0.9       
                                                                                 10.0.0.25      
                                                                                 10.255.0.3     
 2 DO   10.255.0.5      10.255.0.6      10.255.0.5:0               no            10.0.0.14      
                                                                                 10.0.0.17      
                                                                                 10.255.0.5     
[admin@R01.LBN] > /mpls forwarding-table print
Flags: H - hw-offload, L - ldp, V - vpls, T - traffic-eng 
 #    IN-LABEL            OUT-LABELS          DESTINATION                    INTERFACE          NEXTHOP        
 0    expl-null          
 1  L 16                  16                  10.255.0.2/32                  ether3             10.0.0.22      
 2  L 17                                      10.255.0.5/32                  ether2             10.0.0.17      
 3  L 18                                      10.0.0.0/30                    ether3             10.0.0.22      
 4  L 19                                      10.0.0.12/30                   ether2             10.0.0.17      
 5  L 20                                      10.255.0.1/32                  ether3             10.0.0.22      
 6  L 21                  21                  10.255.0.4/32                  ether4             10.0.0.25      
 7  L 22                                      10.0.0.4/30                    ether4             10.0.0.25      
 8  L 23                                      10.255.0.3/32                  ether4             10.0.0.25      
 9  L 24                                      10.0.0.8/30                    ether4             10.0.0.25   
```

### 7.3. EoMPLS

NY:
```routeros
[admin@R01.NY] > /interface vpls print detail
Flags: X - disabled, R - running, D - dynamic, B - bgp-signaled, C - cisco-bgp-signaled 
 0 R   name="vpls_to_spb" mtu=1500 l2mtu=1500 mac-address=02:A3:8E:49:8E:0C arp=enabled arp-timeout=auto 
       disable-running-check=no remote-peer=10.255.0.4 vpls-id=100:1 cisco-style=no cisco-style-id=0 
       advertised-l2mtu=1500 pw-type=raw-ethernet use-control-word=no 
[admin@R01.NY] > /interface bridge print
Flags: X - disabled, R - running 
 0 R name="br_eompls" mtu=auto actual-mtu=1500 l2mtu=1500 arp=enabled arp-timeout=auto 
     mac-address=AA:C1:AB:F7:84:A1 protocol-mode=none fast-forward=yes igmp-snooping=no auto-mac=yes 
     ageing-time=5m vlan-filtering=no dhcp-snooping=no 

 1 R name="lo" mtu=auto actual-mtu=1500 l2mtu=65535 arp=enabled arp-timeout=auto mac-address=82:D7:14:AE:FC:34 
     protocol-mode=none fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m vlan-filtering=no 
     dhcp-snooping=no 
[admin@R01.NY] > /interface bridge port print
Flags: X - disabled, I - inactive, D - dynamic, H - hw-offload 
 #     INTERFACE                BRIDGE               HW  PVID PRIORITY  PATH-COST INTERNAL-PATH-COST    HORIZON
 0     ether4                   br_eompls            yes    1     0x80         10                 10       none
 1     vpls_to_spb              br_eompls                   1     0x80         10                 10       none

```

SPB:
```routeros
[admin@R01.SPB] > /interface vpls print detail
Flags: X - disabled, R - running, D - dynamic, B - bgp-signaled, C - cisco-bgp-signaled 
 0 R   name="vpls_to_ny" mtu=1500 l2mtu=1500 mac-address=02:02:4B:C0:C2:9D arp=enabled arp-timeout=auto 
       disable-running-check=no remote-peer=10.255.0.1 vpls-id=100:1 cisco-style=no cisco-style-id=0 
       advertised-l2mtu=1500 pw-type=raw-ethernet use-control-word=no 
[admin@R01.SPB] > /interface bridge print
Flags: X - disabled, R - running 
 0 R name="br_eompls" mtu=auto actual-mtu=1500 l2mtu=1500 arp=enabled arp-timeout=auto 
     mac-address=AA:C1:AB:71:AD:BD protocol-mode=none fast-forward=yes igmp-snooping=no auto-mac=yes 
     ageing-time=5m vlan-filtering=no dhcp-snooping=no 

 1 R name="lo" mtu=auto actual-mtu=1500 l2mtu=65535 arp=enabled arp-timeout=auto mac-address=32:6D:AD:DC:22:35 
     protocol-mode=none fast-forward=yes igmp-snooping=no auto-mac=yes ageing-time=5m vlan-filtering=no 
     dhcp-snooping=no 
[admin@R01.SPB] > /interface bridge port print
Flags: X - disabled, I - inactive, D - dynamic, H - hw-offload 
 #     INTERFACE                BRIDGE               HW  PVID PRIORITY  PATH-COST INTERNAL-PATH-COST    HORIZON
 0     ether4                   br_eompls            yes    1     0x80         10                 10       none
 1     vpls_to_ny               br_eompls                   1     0x80         10                 10       none

```

### 7.4. Пинг EoMPLS (между SGI и PC1)
```bash
docker exec -it clab-lab3-sgi_prism ping -c 4 192.168.100.20
docker exec -it clab-lab3-pc1_spb ping -c 4 192.168.100.10
```

Вывод:
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab3$ docker exec -it clab-lab3-sgi_prism ping -c 4 192.168.100.20
PING 192.168.100.20 (192.168.100.20) 56(84) bytes of data.
64 bytes from 192.168.100.20: icmp_seq=1 ttl=64 time=2.28 ms
64 bytes from 192.168.100.20: icmp_seq=2 ttl=64 time=3.88 ms
64 bytes from 192.168.100.20: icmp_seq=3 ttl=64 time=4.78 ms
64 bytes from 192.168.100.20: icmp_seq=4 ttl=64 time=3.75 ms

--- 192.168.100.20 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 2.278/3.671/4.779/0.897 ms

deltra@Deltrabuntu:~/intro_in_routing/lab3$ docker exec -it clab-lab3-pc1_spb ping -c 4 192.168.100.10
PING 192.168.100.10 (192.168.100.10) 56(84) bytes of data.
64 bytes from 192.168.100.10: icmp_seq=1 ttl=64 time=1.69 ms
64 bytes from 192.168.100.10: icmp_seq=2 ttl=64 time=4.20 ms
64 bytes from 192.168.100.10: icmp_seq=3 ttl=64 time=3.71 ms
64 bytes from 192.168.100.10: icmp_seq=4 ttl=64 time=3.84 ms

--- 192.168.100.10 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3006ms
rtt min/avg/max/mdev = 1.694/3.361/4.202/0.979 ms

```

---

## 8. Вывод
1) В Docker была сделана модель сети из 6 роутеров.
2) На каждом линке были выданы IP-адреса, чтобы роутеры могли общаться.
3) Включён OSPF - чтобы роутеры могли знать пути друг к другу, без ручных маршрутов.
4) Включён MPLS + LDP - роутеры начали пересылать трафик по меткам.
5) Поверх MPLS сделана EoMPLS.
6) Для SGI Prism и PC1 выданы адреса из одной сети и проверено, что они пингуются.
