## 目标
```
underlay

---------------------192.168.200.0/19-----------------------------
        |                     |                   |
        |192.168.200.70       |192.168.200.71     |192.168.200.75
   -----------           -----------         -----------              |
   |         |           |         |         |         |10.10.0.100   |
   | host-ovn|           | host-hv1|         |host-gw1 |--------------|
   |         |           |         |         |         |              |
   -----------           -----------         -----------              |10.10.0.1/24
        |                     |                   |
        |192.168.110.3        |192.168.110.4      |192.168.110.6
---------------------192.168.110.0/24-----------------------------
                             |
                             |
                    ---------------------
                    |       5700        |
                    ---------------------
                             |
                             |10.0.0.3
                        --------------
                        | bare metal |
                        --------------

topo

                       10.10.0.0/24
                            |
                --------------------------  
                |                        |
                |    external-switch     |
                |                        |
                --------------------------
                            |
                            |10.10.0.100
         ----------------------------------------  
         |                                       |
         |                   router              |
         |                                       |
         -----------------------------------------
             |10.0.0.100/24                  |10.0.1.100/24
             |                               |              
         ------------                  ------------
         |  inside  |                  |  inside1 |
         ------------                  ------------
          |   |   |                      |      |
         vm1  |   |                     vm3     |
              |   |                             |
              |  vm4                           vm5
              |                                        
          --------
          | vtep |
          --------
              |
          bare metal
```
- vm1位于host-ovn上，mac地址为: 02:ac:10:ff:01:30 ip地址为: 10.0.0.1
- vm3位于host-hv1上, mac地址为: 02:ac:10:ff:01:32 ip地址为: 10.0.0.4
- vm4位于host-ovn上，mac地址为: 02:ac:10:ff:01:33 ip地址为: 10.0.1.2
- vm5位于host-hv1上，mac地址为: 02:ac:10:ff:01:34 ip地址为: 10.0.1.3
- bare metal的mac地址为: 6c:b3:11:1c:cc:58 ip地址为: 10.0.0.3
- vtep为5700交换机

## build image
```
# cd ovn_lab/docker
# docker build -t ovn_lab:v1 .
```

## 5700交换机

### vlan设置(config模式)
添加vlan
```
vlan database
vlan 20
vlan 200
exit
```
为vlan 200设置ip address

```
interface vlan 200
ip address 192.168.110.1/24
exit
```

### 端口设置(config模式)
* 31端口
```
interface ethernet 1/35
switchport allowed vlan add 200 tagged
switchport native vlan 200
exit
```
* 33端口
```
interface ethernet 1/33
switchport allowed vlan add 20 tagged
switchport native vlan 20
exit
```

* 35端口
```
interface ethernet 1/35
switchport allowed vlan add 200 tagged
switchport native vlan 200
exit
```

* 39端口
```
interface ethernet 1/39
switchport allowed vlan add 200 tagged
switchport native vlan 200
```


### 启动vtep-db(linux shell模式)
1. 删除之前的vtep database
```
rm /usr/local/etc/openvswitch/vtep.db
```

2. 根据ovsschema重建vtep database
```
ovsdb-tool create /usr/local/etc/openvswitch/vtep.db /usr/local/share/openvswitch/vtep.ovsschema
```

3. 启动vtep-db
```
/etc/rc.vtep
```

## host-ovn
1. 设置ip
```
# cd /etc/sysconfig/network-scripts
# cat ifcfg-ens5
TYPE=Ethernet
BOOTPROTO=none
NAME=ens5
DEVICE=ens5
ONBOOT=yes
# cat ifcfg-ens5.200
PHYSDEV=ens5
VLAN=yes
TYPE=Vlan
VLAN_ID=200
BOOTPROTO=none
IPADDR=192.168.110.3
PREFIX=24
DEFROUTE=yes
NAME=ens5.200
DEVICE=ens5.200
ONBOOT=yes
```

2. 创建拓扑
```
# cd ovn_lab/lesson/ovn/hw-vtep-gateway
# ./start_host.sh
# docker exec -it vtep5700 bash
# start_ovs.sh
# start_ovn_northd.sh
# start_ovn_controller.sh
# cd root/ovn_lab
# ./create_topo_host_ovn.sh
```

## host-vtep
1. 设置ip
```
# cd /etc/sysconfig/network-scripts/
# cat ifcfg-ens4
TYPE=Ethernet
BOOTPROTO=none
NAME=ens4
DEVICE=ens4
ONBOOT=yes
# cat ifcfg-ens4.200
PHYSDEV=ens4
VLAN=yes
TYPE=Vlan
VLAN_ID=200
BOOTPROTO=none
IPADDR=192.168.110.4
PREFIX=24
DEFROUTE=yes
NAME=ens4.200
DEVICE=ens4.200
ONBOOT=yes
```

2. 创建拓扑
```
# cd ovn_lab/lesson/ovn/hw-vtep-gateway
# ./start_host.sh
# docker exec -it vtep5700 bash
# start_ovs.sh
# start_ovn_controller.sh
# cd root/ovn_lab
# ./create_topo_host_hv1.sh
```

## host-gw1
1. 设置ip
```
# cd/etc/sysconfig/network-scripts/
# cat ifcfg-ens4
TYPE=Ethernet
BOOTPROTO=none
NAME=ens4
DEVICE=ens4
ONBOOT=yes
# cat ifcfg-ens4.200
PHYSDEV=ens4
VLAN=yes
TYPE=Vlan
VLAN_ID=200
BOOTPROTO=none
IPADDR=192.168.110.6
PREFIX=24
DEFROUTE=yes
NAME=ens4.200
DEVICE=ens4.200
ONBOOT=yes
```

2. 创建拓扑
```
# cd ovn_lab/lesson/ovn/hw-vtep-gateway
# ./start_host.sh
# docker exec -it vtep5700 bash
# cd root/ovn_lab
# ./create_topo_gw1.sh
```

## 交换机设置

1. 在交换机上启动ovn-controller-vtep
```
Vty-5#linux shell
Entering Linux Shell...
# nohup ovn-controller-vtep -vconsole:info --vtep-db=tcp:192.168.110.1:6632 --ovnsb-db=tcp:192.168.200.70:6642&
```

2. 交换机配置
linux shell下配置
```
vtep-ctl add-ps br0
vtep-ctl add-port br0 swp33  
vtep-ctl set Physical_Switch br0 tunnel_ips=192.168.110.1
vtep-ctl add-ls ls0
vtep-ctl bind-ls br0 swp33 20 ls0
````

## 结果
1. host-ovn中vm1 ping 10.10.0.1
```
# ip netns exec vm1 ping 10.10.0.1 -c 3
PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.
64 bytes from 10.10.0.1: icmp_seq=1 ttl=63 time=4.41 ms
64 bytes from 10.10.0.1: icmp_seq=2 ttl=63 time=1.22 ms
64 bytes from 10.10.0.1: icmp_seq=3 ttl=63 time=1.38 ms

--- 10.10.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 1.220/2.335/4.409/1.467 ms
```

2. host-ovn中vm4 ping 10.10.0.1
```
# ip netns exec vm4 ping 10.10.0.1 -c 3
PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.
64 bytes from 10.10.0.1: icmp_seq=1 ttl=63 time=3.27 ms
64 bytes from 10.10.0.1: icmp_seq=2 ttl=63 time=1.42 ms
64 bytes from 10.10.0.1: icmp_seq=3 ttl=63 time=1.22 ms

--- 10.10.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 1.220/1.967/3.267/0.923 ms
```

3. host-hv1中vm3 ping 10.10.0.1
```
# ip netns exec vm3 ping 10.10.0.1 -c 3
PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.
64 bytes from 10.10.0.1: icmp_seq=1 ttl=63 time=1.52 ms
64 bytes from 10.10.0.1: icmp_seq=2 ttl=63 time=1.51 ms
64 bytes from 10.10.0.1: icmp_seq=3 ttl=63 time=1.53 ms

--- 10.10.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 6ms
rtt min/avg/max/mdev = 1.505/1.517/1.529/0.046 ms
```

4. host-hv1中vm5 ping 10.10.0.1 -c 3
```
# ip netns exec vm5 ping 10.10.0.1 -c 3
PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.
64 bytes from 10.10.0.1: icmp_seq=1 ttl=63 time=3.35 ms
64 bytes from 10.10.0.1: icmp_seq=2 ttl=63 time=1.51 ms
64 bytes from 10.10.0.1: icmp_seq=3 ttl=63 time=1.38 ms

--- 10.10.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 1.375/2.078/3.352/0.903 ms
```

5. bare metal ping 10.10.0.1
```
# ip route add 10.10.0.0/24 via 10.0.0.100
# ping 10.10.0.1 -c 3
PING 10.10.0.1 (10.10.0.1) 56(84) bytes of data.

--- 10.10.0.1 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2053ms
```

bare metal ping 10.10.0.1不通，查找原因：

host-ovn上抓包:
```
09:14:49.319226 70:72:cf:c7:cc:0b > 52:54:00:2b:b8:bd, ethertype 802.1Q (0x8100), length 152: vlan 200, p 0, ethertype IPv4, 192.168.110.1.23073 > 192.168.110.3.vxlan: VXLAN, flags [I] (0x08), vni 3
6c:b3:11:1c:cc:58 > 02:ac:10:ff:00:01, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 8, length 64
09:14:49.319325 52:54:00:2b:b8:bd > 52:54:00:5b:8c:62, ethertype 802.1Q (0x8100), length 160: vlan 200, p 0, ethertype IPv4, 192.168.110.3.swa-4 > 192.168.110.6.geneve: Geneve, Flags [C], vni 0x2, proto TEB (0x6558), options [8 bytes]: 00:00:01:01:05:05 > 02:42:92:de:19:29, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 8, length 64
```

host-hv1上抓包:
```
09:14:48.116999 70:72:cf:c7:cc:0b > 52:54:00:c3:d1:93, ethertype 802.1Q (0x8100), length 152: vlan 200, p 0, ethertype IPv4, 192.168.110.1.23073 > 192.168.110.4.vxlan: VXLAN, flags [I] (0x08), vni 3
6c:b3:11:1c:cc:58 > 02:ac:10:ff:00:01, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 8, length 64
09:14:48.117155 52:54:00:c3:d1:93 > 52:54:00:5b:8c:62, ethertype 802.1Q (0x8100), length 160: vlan 200, p 0, ethertype IPv4, 192.168.110.4.25378 > 192.168.110.6.geneve: Geneve, Flags [C], vni 0x2, proto TEB (0x6558), options [8 bytes]: 00:00:01:01:05:05 > 02:42:92:de:19:29, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 8, length 64
```

host-gw1上抓包:
```
09:14:47.782697 52:54:00:2b:b8:bd > 52:54:00:5b:8c:62, ethertype 802.1Q (0x8100), length 160: vlan 200, p 0, ethertype IPv4, 192.168.110.3.swa-4 > 192.168.110.6.geneve: Geneve, Flags [C], vni 0x2, proto TEB (0x6558), options [8 bytes]: 00:00:01:01:05:05 > 02:42:92:de:19:29, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 7, length 64
09:14:47.782749 52:54:00:c3:d1:93 > 52:54:00:5b:8c:62, ethertype 802.1Q (0x8100), length 160: vlan 200, p 0, ethertype IPv4, 192.168.110.4.25378 > 192.168.110.6.geneve: Geneve, Flags [C], vni 0x2, proto TEB (0x6558), options [8 bytes]: 00:00:01:01:05:05 > 02:42:92:de:19:29, ethertype IPv4 (0x0800), length 98: 10.0.0.3 > 10.10.0.1: ICMP echo request, id 3763, seq 7, length 64
09:14:47.783798 52:54:00:5b:8c:62 > 70:72:cf:c7:cc:0b, ethertype 802.1Q (0x8100), length 152: vlan 200, p 0, ethertype IPv4, 192.168.110.6.60141 > 192.168.110.1.vxlan: VXLAN, flags [I] (0x08), vni 3
02:ac:10:ff:00:01 > 6c:b3:11:1c:cc:58, ethertype IPv4 (0x0800), length 98: 10.10.0.1 > 10.0.0.3: ICMP echo reply, id 3763, seq 7, length 64
09:14:47.784002 52:54:00:5b:8c:62 > 70:72:cf:c7:cc:0b, ethertype 802.1Q (0x8100), length 152: vlan 200, p 0, ethertype IPv4, 192.168.110.6.60141 > 192.168.110.1.vxlan: VXLAN, flags [I] (0x08), vni 3
02:ac:10:ff:00:01 > 6c:b3:11:1c:cc:58, ethertype IPv4 (0x0800), length 98: 10.10.0.1 > 10.0.0.3: ICMP echo reply, id 3763, seq 7, length 64
```
