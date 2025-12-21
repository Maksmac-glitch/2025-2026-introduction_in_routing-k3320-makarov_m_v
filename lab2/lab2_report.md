University: [ITMO University](https://itmo.ru/ru/)
Faculty: [FICT](https://fict.itmo.ru/)
Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
Year: 2025
Group: K3320
Author: Makarov Maksim Vyacheslavovich
Lab: Lab2
Date of create: 20.12.2025
Date of finished: 

---

# Лабораторная работа №2
## Эмуляция распределенной корпоративной сети, настройка статической маршрутизации между филиалами

## 1. Цель работы
Ознакомиться с принципами планирования IP адресов, настройке статической маршрутизации и сетевыми функциями устройств.

- Спланировать IP-адресацию для трёх офисов.
- Развернуть топологию в ContainerLab.
- Настроить IP адреса на роутерах.
- Поднять DHCP в каждом офисе.
- Настроить статическую маршрутизацию между офисами.
- Настроить имена устройств, сменить логины и пароли.
- Пропинговать.

## 2. Описание результата
Была сделана связка из 3 офисов:
- Москва (MSK),
- Франкфурт (FRT),
- Берлин (BRL).

В каждом офисе есть:
- роутер,
- компьютер сотрудника (PC).

Роутеры офисов соединены корпоративной сетью (WAN), поэтому офисы могут обмениваться данными.
Чтобы компьютеры получали IP адреса - в каждом офисе включен DHCP.
Чтобы офисы видели друг друга - на каждом роутере прописаны статические маршруты.

## 3. Топология
Файлы:
- `lab2.clab.yaml` - ContainerLab
- `lab2_topology.drawio` - схема
- `configs/` - конфигурации RouterOS и скрипты для PC

Устройства:
- R01.MSK, R01.FRT, R01.BRL - RouterOS CHR
- PC1 (MSK), PC2 (FRT), PC3 (BRL) - Linux containers

Соединения (WAN):
- MSK <-> BRL
- BRL <-> FRT
- MSK <-> FRT

LAN:
- MSK <-> PC1
- FRT <-> PC2
- BRL <-> PC3

## 4. План
### 4.1 LAN сети офисов
| Офис | Подсеть | Шлюз | DHCP диапазон |
| MSK | 10.10.10.0/24 | 10.10.10.1 | 10.10.10.100–10.10.10.200 |
| FRT | 10.20.20.0/24 | 10.20.20.1 | 10.20.20.100–10.20.20.200 |
| BRL | 10.30.30.0/24 | 10.30.30.1 | 10.30.30.100–10.30.30.200 |

### 4.2 WAN 
| Линк | Подсеть | Сторона A | Сторона B |
| MSK–BRL | 172.16.0.0/30 | MSK: 172.16.0.1 | BRL: 172.16.0.2 |
| BRL–FRT | 172.16.0.4/30 | BRL: 172.16.0.5 | FRT: 172.16.0.6 |
| MSK–FRT | 172.16.0.8/30 | MSK: 172.16.0.9 | FRT: 172.16.0.10 |

## 5. Развёртывание ContainerLab
### 5.1 Deploy
```bash
cd lab2
sudo containerlab deploy -t lab2.clab.yaml
sudo containerlab inspect -t lab2.clab.yaml
```

Вывод:

```bash

╭───────────────────┬───────────────────────────────────────────┬───────────┬────────────────╮
│        Name       │                 Kind/Image                │   State   │ IPv4/6 Address │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-pc1     │ linux                                     │ running   │ 172.20.30.21   │
│                   │ ghcr.io/srl-labs/network-multitool:latest │           │ N/A            │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-pc2     │ linux                                     │ running   │ 172.20.30.22   │
│                   │ ghcr.io/srl-labs/network-multitool:latest │           │ N/A            │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-pc3     │ linux                                     │ running   │ 172.20.30.23   │
│                   │ ghcr.io/srl-labs/network-multitool:latest │           │ N/A            │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-r01_brl │ mikrotik_ros                              │ running   │ 172.20.30.13   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-r01_frt │ mikrotik_ros                              │ running   │ 172.20.30.12   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
├───────────────────┼───────────────────────────────────────────┼───────────┼────────────────┤
│ clab-lab2-r01_msk │ mikrotik_ros                              │ running   │ 172.20.30.11   │
│                   │ vrnetlab/mikrotik_routeros:6.47.9         │ (healthy) │ N/A            │
╰───────────────────┴───────────────────────────────────────────┴───────────┴────────────────╯
```

Mgmt сеть для доступа:
- 172.20.30.0/24, устройства получают mgmt-ip из YAML.

## 6. Настройка RouterOS (IP, DHCP, статические маршруты)
Конфигурации лежат в `lab2/configs/`:
- `r01_msk.rsc`
- `r01_frt.rsc`
- `r01_brl.rsc`

Импорт (пример для MSK):
```bash
scp configs/r01_msk.rsc admin@172.20.30.11:r01_msk.rsc
ssh admin@172.20.30.11
/import file-name=r01_msk.rsc
```

Аналогично:
- FRT mgmt: 172.20.30.12
- BRL mgmt: 172.20.30.13

Проверка на роутерах:
```routeros
/ip address print
/ip dhcp-server print
/ip route print
/system identity print
/user print
```
Вывод MSK:
```bash
[admin@R01.MSK] > /ip address print
Flags: X - disabled, I - invalid, D - dynamic 
 #   ADDRESS            NETWORK         INTERFACE                                                                  
 0   172.31.255.30/30   172.31.255.28   ether1                                                                     
 1   ;;; WAN to BRL (MSK-BRL)
     172.16.0.1/30      172.16.0.0      ether2                                                                     
 2   ;;; WAN to FRT (MSK-FRT)
     172.16.0.9/30      172.16.0.8      ether3                                                                     
 3   ;;; LAN MSK (to PC1)
     10.10.10.1/24      10.10.10.0      ether4                                                                     
[admin@R01.MSK] > /ip dhcp-server print
Flags: D - dynamic, X - disabled, I - invalid 
 #    NAME                  INTERFACE                RELAY           ADDRESS-POOL                LEASE-TIME ADD-ARP
 0    dhcp_msk              ether4                                   pool_msk                    10m       
[admin@R01.MSK] > /ip route print
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 ADC  10.10.10.0/24      10.10.10.1      ether4                    0
 1 A S  ;;; to FRT LAN via MSK-FRT link
        10.20.20.0/24                      172.16.0.10               1
 2 A S  ;;; to BRL LAN via MSK-BRL link
        10.30.30.0/24                      172.16.0.2                1
 3 ADC  172.16.0.0/30      172.16.0.1      ether2                    0
 4 ADC  172.16.0.8/30      172.16.0.9      ether3                    0
 5 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
[admin@R01.MSK] > /system identity print
  name: R01.MSK
[admin@R01.MSK] > /user print
Flags: X - disabled 
 #   NAME                               GROUP                               ADDRESS            LAST-LOGGED-IN      
 0   ;;; system default user
     admin                              full                                                   dec/21/2025 02:14:42
 1   admin2                             full                               

```

Вывод FRT:
```bash
[admin@R01.FRT] > /ip address print
Flags: X - disabled, I - invalid, D - dynamic 
 #   ADDRESS            NETWORK         INTERFACE                                                                  
 0   172.31.255.30/30   172.31.255.28   ether1                                                                     
 1   ;;; WAN to BRL (BRL-FRT)
     172.16.0.6/30      172.16.0.4      ether2                                                                     
 2   ;;; WAN to MSK (MSK-FRT)
     172.16.0.10/30     172.16.0.8      ether3                                                                     
 3   ;;; LAN FRT (to PC2)
     10.20.20.1/24      10.20.20.0      ether4                                                                     
[admin@R01.FRT] > /ip dhcp-server print
Flags: D - dynamic, X - disabled, I - invalid 
 #    NAME                  INTERFACE                RELAY           ADDRESS-POOL                LEASE-TIME ADD-ARP
 0    dhcp_frt              ether4                                   pool_frt                    10m       
[admin@R01.FRT] > /ip route print
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 A S  ;;; to MSK LAN via MSK-FRT link
        10.10.10.0/24                      172.16.0.9                1
 1 ADC  10.20.20.0/24      10.20.20.1      ether4                    0
 2 A S  ;;; to BRL LAN via BRL-FRT link
        10.30.30.0/24                      172.16.0.5                1
 3 ADC  172.16.0.4/30      172.16.0.6      ether2                    0
 4 ADC  172.16.0.8/30      172.16.0.10     ether3                    0
 5 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
[admin@R01.FRT] > /system identity print
  name: R01.FRT
[admin@R01.FRT] > /user print
Flags: X - disabled 
 #   NAME                               GROUP                               ADDRESS            LAST-LOGGED-IN      
 0   ;;; system default user
     admin                              full                                                   dec/21/2025 02:17:22
 1   admin2                             full                               

```

Вывод BRL:
```bash
[admin@R01.BRL] > /ip address print
Flags: X - disabled, I - invalid, D - dynamic 
 #   ADDRESS            NETWORK         INTERFACE                                                                  
 0   172.31.255.30/30   172.31.255.28   ether1                                                                     
 1   ;;; WAN to MSK (MSK-BRL)
     172.16.0.2/30      172.16.0.0      ether2                                                                     
 2   ;;; WAN to FRT (BRL-FRT)
     172.16.0.5/30      172.16.0.4      ether3                                                                     
 3   ;;; LAN BRL (to PC3)
     10.30.30.1/24      10.30.30.0      ether4                                                                     
[admin@R01.BRL] > /ip dhcp-server print
Flags: D - dynamic, X - disabled, I - invalid 
 #    NAME                  INTERFACE                RELAY           ADDRESS-POOL                LEASE-TIME ADD-ARP
 0    dhcp_brl              ether4                                   pool_brl                    10m       
[admin@R01.BRL] > /ip route print
Flags: X - disabled, A - active, D - dynamic, C - connect, S - static, r - rip, b - bgp, o - ospf, m - mme, 
B - blackhole, U - unreachable, P - prohibit 
 #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
 0 A S  ;;; to MSK LAN via MSK-BRL link
        10.10.10.0/24                      172.16.0.1                1
 1 A S  ;;; to FRT LAN via BRL-FRT link
        10.20.20.0/24                      172.16.0.6                1
 2 ADC  10.30.30.0/24      10.30.30.1      ether4                    0
 3 ADC  172.16.0.0/30      172.16.0.2      ether2                    0
 4 ADC  172.16.0.4/30      172.16.0.5      ether3                    0
 5 ADC  172.31.255.28/30   172.31.255.30   ether1                    0
[admin@R01.BRL] > /system identity print
  name: R01.BRL
[admin@R01.BRL] > /user print
Flags: X - disabled 
 #   NAME                               GROUP                               ADDRESS            LAST-LOGGED-IN      
 0   ;;; system default user
     admin                              full                                                   dec/21/2025 02:21:44
 1   admin2                             full                               


```

## 7. DHCP на PC1/PC2/PC3
Скрипты:
- `pc1_dhcp.sh`, `pc2_dhcp.sh`, `pc3_dhcp.sh`

Применение (пример для PC1):
```bash
docker cp configs/pc1_dhcp.sh clab-lab2-pc1:/pc1_dhcp.sh
docker exec -it clab-lab2-pc1 sh /pc1_dhcp.sh
```

Вывод PC1:
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker cp configs/pc1_dhcp.sh clab-lab2-pc1:/pc1_dhcp.sh
docker exec -it clab-lab2-pc1 sh /pc1_dhcp.sh
Successfully copied 2.05kB to clab-lab2-pc1:/pc1_dhcp.sh
+ ip link set eth1 up
+ dhclient -v eth1
/pc1_dhcp.sh: line 4: dhclient: not found
+ udhcpc -i eth1
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 10.10.10.200, server 10.10.10.1
udhcpc: lease of 10.10.10.200 obtained from 10.10.10.1, lease time 600
mv: can't rename '/etc/resolv.conf.59': Resource busy
+ ip route del default dev eth0
+ ip -4 a show eth1
29: eth1@if28: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default  link-netnsid 1
    inet 10.10.10.200/24 scope global eth1
       valid_lft forever preferred_lft forever
+ ip r
default via 10.10.10.1 dev eth1 metric 229 
10.10.10.0/24 dev eth1 proto kernel scope link src 10.10.10.200 
172.20.30.0/24 dev eth0 proto kernel scope link src 172.20.30.21
```

Вывод PC2:
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker exec -it clab-lab2-pc2 sh /pc2_dhcp.sh
+ ip link set eth1 up
+ dhclient -v eth1
/pc2_dhcp.sh: line 4: dhclient: not found
+ udhcpc -i eth1
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 10.20.20.200, server 10.20.20.1
udhcpc: lease of 10.20.20.200 obtained from 10.20.20.1, lease time 600
mv: can't rename '/etc/resolv.conf.129': Resource busy
+ ip route del default dev eth0
+ true
+ ip -4 a show eth1
21: eth1@if20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default  link-netnsid 1
    inet 10.20.20.200/24 scope global eth1
       valid_lft forever preferred_lft forever
+ ip r
default via 10.20.20.1 dev eth1 metric 221 
10.20.20.0/24 dev eth1 proto kernel scope link src 10.20.20.200 
172.20.30.0/24 dev eth0 proto kernel scope link src 172.20.30.22 

```

Вывод PC3:
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker cp configs/pc3_dhcp.sh clab-lab2-pc3:/pc3_dhcp.sh
docker exec -it clab-lab2-pc3 sh /pc3_dhcp.sh
Successfully copied 2.05kB to clab-lab2-pc3:/pc3_dhcp.sh
+ ip link set eth1 up
+ dhclient -v eth1
/pc3_dhcp.sh: line 4: dhclient: not found
+ udhcpc -i eth1
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 10.30.30.200, server 10.30.30.1
udhcpc: lease of 10.30.30.200 obtained from 10.30.30.1, lease time 600
mv: can't rename '/etc/resolv.conf.117': Resource busy
+ ip route del default dev eth0
+ true
+ ip -4 a show eth1
31: eth1@if30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9500 qdisc noqueue state UP group default  link-netnsid 1
    inet 10.30.30.200/24 scope global eth1
       valid_lft forever preferred_lft forever
+ ip r
default via 10.30.30.1 dev eth1 metric 231 
10.30.30.0/24 dev eth1 proto kernel scope link src 10.30.30.200 
172.20.30.0/24 dev eth0 proto kernel scope link src 172.20.30.23 
```

В скриптах удаляется default route через mgmt (eth0), чтобы основной трафик шёл через офисный роутер (eth1).

## 8. ping
### 8.1 Локально до шлюза
**PC1 -> шлюз MSK**
```bash
docker exec -it clab-lab2-pc1 ping -c 4 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.442 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.763 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.701 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.710 ms

--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3079ms
rtt min/avg/max/mdev = 0.442/0.654/0.763/0.124 ms

```

**PC2 -> шлюз FRT**
```bash
docker exec -it clab-lab2-pc2 ping -c 4 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.
64 bytes from 10.20.20.1: icmp_seq=1 ttl=64 time=0.474 ms
64 bytes from 10.20.20.1: icmp_seq=2 ttl=64 time=0.820 ms
64 bytes from 10.20.20.1: icmp_seq=3 ttl=64 time=0.937 ms
64 bytes from 10.20.20.1: icmp_seq=4 ttl=64 time=0.780 ms

--- 10.20.20.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3036ms
rtt min/avg/max/mdev = 0.474/0.752/0.937/0.170 ms

```

**PC3 -> шлюз BRL**
```bash
docker exec -it clab-lab2-pc3 ping -c 4 10.30.30.1
PING 10.30.30.1 (10.30.30.1) 56(84) bytes of data.
64 bytes from 10.30.30.1: icmp_seq=1 ttl=64 time=0.446 ms
64 bytes from 10.30.30.1: icmp_seq=2 ttl=64 time=0.807 ms
64 bytes from 10.30.30.1: icmp_seq=3 ttl=64 time=0.735 ms
64 bytes from 10.30.30.1: icmp_seq=4 ttl=64 time=0.795 ms

--- 10.30.30.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3105ms
rtt min/avg/max/mdev = 0.446/0.695/0.807/0.146 ms

```

### 8.2 Межофисная связность
**MSK (PC1) -> FRT (PC2) и BRL (PC3)**
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker exec -it clab-lab2-pc1 ping -c 4 10.20.20.200
docker exec -it clab-lab2-pc1 ping -c 4 10.30.30.200
PING 10.20.20.200 (10.20.20.200) 56(84) bytes of data.
64 bytes from 10.20.20.200: icmp_seq=1 ttl=62 time=1.97 ms
64 bytes from 10.20.20.200: icmp_seq=2 ttl=62 time=2.62 ms
64 bytes from 10.20.20.200: icmp_seq=3 ttl=62 time=2.70 ms
64 bytes from 10.20.20.200: icmp_seq=4 ttl=62 time=2.14 ms

--- 10.20.20.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.968/2.358/2.700/0.310 ms
PING 10.30.30.200 (10.30.30.200) 56(84) bytes of data.
64 bytes from 10.30.30.200: icmp_seq=1 ttl=62 time=1.24 ms
64 bytes from 10.30.30.200: icmp_seq=2 ttl=62 time=2.47 ms
64 bytes from 10.30.30.200: icmp_seq=3 ttl=62 time=2.44 ms
64 bytes from 10.30.30.200: icmp_seq=4 ttl=62 time=2.56 ms

--- 10.30.30.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.242/2.178/2.559/0.542 ms

```

**FRT (PC2) -> MSK (PC1) и BRL (PC3)**
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker exec -it clab-lab2-pc2 ping -c 4 10.10.10.200
docker exec -it clab-lab2-pc2 ping -c 4 10.30.30.200
PING 10.10.10.200 (10.10.10.200) 56(84) bytes of data.
64 bytes from 10.10.10.200: icmp_seq=1 ttl=62 time=1.14 ms
64 bytes from 10.10.10.200: icmp_seq=2 ttl=62 time=2.47 ms
64 bytes from 10.10.10.200: icmp_seq=3 ttl=62 time=2.21 ms
64 bytes from 10.10.10.200: icmp_seq=4 ttl=62 time=2.60 ms

--- 10.10.10.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.144/2.107/2.603/0.573 ms
PING 10.30.30.200 (10.30.30.200) 56(84) bytes of data.
64 bytes from 10.30.30.200: icmp_seq=1 ttl=62 time=1.17 ms
64 bytes from 10.30.30.200: icmp_seq=2 ttl=62 time=2.00 ms
64 bytes from 10.30.30.200: icmp_seq=3 ttl=62 time=1.81 ms
64 bytes from 10.30.30.200: icmp_seq=4 ttl=62 time=2.18 ms

--- 10.30.30.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.171/1.790/2.181/0.380 ms

```

**BRL (PC3) -> MSK (PC1) и FRT (PC2)**
```bash
deltra@Deltrabuntu:~/intro_in_routing/lab2$ docker exec -it clab-lab2-pc3 ping -c 4 10.10.10.200
docker exec -it clab-lab2-pc3 ping -c 4 10.20.20.200
PING 10.10.10.200 (10.10.10.200) 56(84) bytes of data.
64 bytes from 10.10.10.200: icmp_seq=1 ttl=62 time=1.21 ms
64 bytes from 10.10.10.200: icmp_seq=2 ttl=62 time=2.45 ms
64 bytes from 10.10.10.200: icmp_seq=3 ttl=62 time=2.47 ms
64 bytes from 10.10.10.200: icmp_seq=4 ttl=62 time=2.28 ms

--- 10.10.10.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 1.209/2.101/2.470/0.520 ms
PING 10.20.20.200 (10.20.20.200) 56(84) bytes of data.
64 bytes from 10.20.20.200: icmp_seq=1 ttl=62 time=0.953 ms
64 bytes from 10.20.20.200: icmp_seq=2 ttl=62 time=2.48 ms
64 bytes from 10.20.20.200: icmp_seq=3 ttl=62 time=2.46 ms
64 bytes from 10.20.20.200: icmp_seq=4 ttl=62 time=2.48 ms

--- 10.20.20.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 0.953/2.093/2.483/0.658 ms

```

## 9. Итоги
- Развернута сеть из 3 офисов в ContainerLab.
- Настроены LAN сети офисов и DHCP на каждом роутере.
- Настроены статические маршруты между офисами.
- Клиенты получили IP по DHCP и могут пинговать устройства в других офисах.

