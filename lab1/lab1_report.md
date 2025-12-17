University: [ITMO University](https://itmo.ru/ru/)
Faculty: [FICT](https://fict.itmo.ru/)
Course: [Introduction in routing](https://github.com/itmo-ict-faculty/introduction-in-routing)
Year: 2025
Group: K3320
Author: makarov maksim vyacheslavovich
Lab: Lab1
Date of create: 17.12.2025
Date of finished: 

---

# Лабораторная работа №1
## Установка ContainerLab и развертывание тестовой сети связи

## 1. Цель работы
Ознакомиться с инструментом ContainerLab и методами работы с ним, изучить работу VLAN и IP-адресации:
- установить Docker/ContainerLab;
- развернуть тестовую трёхуровневую сеть;
- настроить 2 VLAN и DHCP на центральном роутере;
- проверить связность.

## 2. Объяснение, что было сделано
Была поднята сетевая система в компьютере: несколько виртуальных устройств (роутер, коммутаторы и два ПК), которые соединены между собой.
Потом сеть была разделена на две независимые группы:
- в первой группе находится PC1;
- во второй группе находится PC2.

Каждой группе была выдана своя подсеть, а на роутере включёнDHCP), чтобы ПК получали IP автоматически.
После этого было проверено, что:
1) PC1 видит свой шлюз (роутер),
2) PC2 видит свой шлюз,
3) PC1 и PC2 могут общаться друг с другом через роутер.

## 3. Топология и адресация
### 3.1 Топология
Файлы:
- `lab1.clab.yaml` - топология ContainerLab
- `lab1_topology.drawio` - схема 

Сеть (трёхуровневая):
- R01.TEST (RouterOS CHR)
  - SW01.L3.01.TEST
    - SW02.L3.01.TEST -> PC1
    - SW02.L3.02.TEST -> PC2

### 3.2 VLAN и IP-план
| VLAN | Назначение | Подсеть | Шлюз (RouterOS) | DHCP range |
| 10 | PC1 | 10.10.10.0/24 | 10.10.10.1 | 10.10.10.100–10.10.10.200 |
| 20 | PC2 | 10.20.20.0/24 | 10.20.20.1 | 10.20.20.100–10.20.20.200 |

### 3.3 Mgmt-сеть ContainerLab
ContainerLab создаёт отдельную управляющую сеть (mgmt), чтобы можно было заходить по SSH в контейнеры.

- mgmt subnet: `172.20.20.0/24`
- mgmt IP:
  - R01: 172.20.20.11
  - SW01: 172.20.20.12
  - SW02_01: 172.20.20.13
  - SW02_02: 172.20.20.14
  - PC1: 172.20.20.15
  - PC2: 172.20.20.16

## 4. Окружение
- Ubuntu 24.04 
- Docker 29.1.3
- ContainerLab 0.72.0
- RouterOS CHR 6.47.9

## 5. Развёртывание сети в ContainerLab
### 5.1 Установка ContainerLab
```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version
```

### 5.2 Развёртывание топологии
```bash
cd lab1
sudo containerlab deploy -t lab1.clab.yaml
sudo containerlab inspect -t lab1.clab.yaml
```

## 6. Настройка VLAN на Linux-коммутаторах
Конфигурации выполнялись через Linux bridge с включённым `vlan_filtering`.
Скрипты лежат в `lab1/configs/`:
- `sw01.sh`
- `sw02_01.sh`
- `sw02_02.sh`

Применение:
```bash
docker cp configs/sw01.sh    clab-lab1-sw01:/sw01.sh
docker cp configs/sw02_01.sh clab-lab1-sw02_01:/sw02_01.sh
docker cp configs/sw02_02.sh clab-lab1-sw02_02:/sw02_02.sh

docker exec -it clab-lab1-sw01 sh /sw01.sh
docker exec -it clab-lab1-sw02_01 sh /sw02_01.sh
docker exec -it clab-lab1-sw02_02 sh /sw02_02.sh
```

Логика портов:
- SW01: trunk к R01 и к двум нижним коммутаторам (VLAN 10/20 tagged).
- SW02_01: trunk uplink, access downlink VLAN10 (untagged, PVID 10).
- SW02_02: trunk uplink, access downlink VLAN20 (untagged, PVID 20).

## 7. Настройка RouterOS (VLAN + DHCP)
Конфигурация: `configs/routeros.rsc`.

Импорт:
```bash
scp configs/routeros.rsc admin@172.20.20.11:routeros.rsc
ssh admin@172.20.20.11
/import file-name=routeros.rsc
```

Проверка:
```routeros
/ip dhcp-server print
/ip address print
/interface vlan print
```

## 8. DHCP на PC1/PC2
Скрипты:
- `configs/pc1_dhcp.sh`
- `configs/pc2_dhcp.sh`

Запуск:
```bash
docker cp configs/pc1_dhcp.sh clab-lab1-pc1:/pc1_dhcp.sh
docker cp configs/pc2_dhcp.sh clab-lab1-pc2:/pc2_dhcp.sh
docker exec -it clab-lab1-pc1 sh /pc1_dhcp.sh
docker exec -it clab-lab1-pc2 sh /pc2_dhcp.sh
```

Получено по DHCP:
- PC1: `10.10.10.200/24`
- PC2: `10.20.20.200/24`

## 9. Проверка связности (ping)
### 9.1 До шлюзов
```bash
docker exec -it clab-lab1-pc1 ping -c 4 10.10.10.1

PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.425 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.642 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=0.635 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=0.597 ms

--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3110ms
rtt min/avg/max/mdev = 0.425/0.574/0.642/0.088 ms

docker exec -it clab-lab1-pc2 ping -c 4 10.20.20.1

PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.
64 bytes from 10.20.20.1: icmp_seq=1 ttl=64 time=0.392 ms
64 bytes from 10.20.20.1: icmp_seq=2 ttl=64 time=0.497 ms
64 bytes from 10.20.20.1: icmp_seq=3 ttl=64 time=0.556 ms
64 bytes from 10.20.20.1: icmp_seq=4 ttl=64 time=0.660 ms

--- 10.20.20.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3060ms
rtt min/avg/max/mdev = 0.392/0.526/0.660/0.097 ms

```

### 9.2 Межвлан
Из-за наличия mgmt-интерфейса (eth0) у контейнеров, добавлены маршруты (см. скрипты pc1/pc2), после чего:

Пинг:
```bash
docker exec -it clab-lab1-pc1 ping -c 4 10.20.20.200
```
Вывод:

```PING 10.20.20.200 (10.20.20.200) 56(84) bytes of data.
64 bytes from 10.20.20.200: icmp_seq=1 ttl=63 time=0.537 ms
64 bytes from 10.20.20.200: icmp_seq=2 ttl=63 time=0.865 ms
64 bytes from 10.20.20.200: icmp_seq=3 ttl=63 time=1.04 ms
64 bytes from 10.20.20.200: icmp_seq=4 ttl=63 time=1.05 ms

--- 10.20.20.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3034ms
rtt min/avg/max/mdev = 0.537/0.873/1.052/0.207 ms

```
Пинг:

```docker exec -it clab-lab1-pc2 ping -c 4 10.10.10.200

```
Вывод:

```PING 10.10.10.200 (10.10.10.200) 56(84) bytes of data.
64 bytes from 10.10.10.200: icmp_seq=1 ttl=63 time=0.285 ms
64 bytes from 10.10.10.200: icmp_seq=2 ttl=63 time=0.946 ms
64 bytes from 10.10.10.200: icmp_seq=3 ttl=63 time=1.26 ms
64 bytes from 10.10.10.200: icmp_seq=4 ttl=63 time=1.37 ms

--- 10.10.10.200 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3013ms
rtt min/avg/max/mdev = 0.285/0.964/1.373/0.422 ms

```


## Итоги

- Развернуты устройства и связи трёхуровневой сети в ContainerLab.
- Настроены VLAN 10 и VLAN 20 на Linux bridge.
- На RouterOS настроены VLAN интерфейсы и 2 DHCP сервера.
- PC1/PC2 получили IP по DHCP и успешно пингуют шлюзы и друг друга.
