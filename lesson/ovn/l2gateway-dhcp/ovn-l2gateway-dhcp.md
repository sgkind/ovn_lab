## 目标

```
underlay
ext physical network---------       -----------ext physical network
                       |                 | 
                       |   -----------   |
                       ----|   gw    |----
                           ----------- 
                                |     
                                |     
     ------------------------internal------------------------
              |                 |               |
              |                 |               | 
         -----------       ------------    -----------
         |computer1|       |controller|    |computer1|
         -----------       ------------    -----------

overlay topo
                 internet
                    |
         --------------------------  
         |                        |
         |    external-switch     |
         |                        |
         --------------------------
                    |               
                    |10.20.0.100       
                ---------      
                |   R1  |      
                ---------       
        192.168.1.1|  |192.168.2.1   
             ------    ------       
            |                |       
        -----------      -----------    
        | internal|      | internal|    
        | switch1 |      | switch2 |    
        -----------      -----------    
         |   |   |        |   |   |      
        vm1  |  vm3      vm2  |  vm4     
             |                |
             |l2gateway       |l2gateway
        -----------ext1  ----------ext2
          |      |         |     |
          |      |         |     |
         bm1    bm2       bm3   bm4
```
- 在通过l2gateway打通物理网络和ovn虚拟网络的基础上，实现物理网络中的主机可以通过ovn的dhcp server动态获取ip地址

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/docker
./build_v2.sh
```


## run container

```
cd ../lesson/ovn/l2gateway
./start_compose.sh
```

## 创建拓扑
```
./start.sh
```

## 测试
1. 进入ovn-gw容器
```
docker exec -it ovn-gw bash
```

2. bm1通过dhcp获取ip地址
```
# ip netns exec bm1 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
5: bm1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:03 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::ac:10ff:feff:103/64 scope link 
       valid_lft forever preferred_lft forever
# ip netns exec bm1 dhclient bm1
# ip netns exec bm1 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
5: bm1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:03 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.5/24 brd 192.168.1.255 scope global dynamic bm1
       valid_lft 360048sec preferred_lft 360048sec
    inet6 fe80::ac:10ff:feff:103/64 scope link 
       valid_lft forever preferred_lft forever
# ip netns exec bm1 ping 192.168.1.1 -c 2
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=254 time=0.612 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=254 time=0.308 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 30ms
rtt min/avg/max/mdev = 0.308/0.460/0.612/0.152 ms
```

3. bm2通过dhcp获取ip地址
```
bash-4.4# ip netns exec bm2 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
6: bm2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:04 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::ac:10ff:feff:104/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm2 pkill dhclient
bash-4.4# ip netns exec bm2 dhclient bm2
bash-4.4# ip netns exec bm2 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
6: bm2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:04 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.6/24 brd 192.168.1.255 scope global dynamic bm2
       valid_lft 360053sec preferred_lft 360053sec
    inet6 fe80::ac:10ff:feff:104/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm2 ping 192.168.1.1 -c 2
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=254 time=0.525 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=254 time=0.297 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 62ms
rtt min/avg/max/mdev = 0.297/0.411/0.525/0.114 ms
```

4. bm3通过dhcp获取ip地址
```
bash-4.4# ip netns exec bm3 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
8: bm3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:05 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::ac:10ff:feff:105/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm3 pkill dhclient
bash-4.4# ip netns exec bm3 dhclient bm3
bash-4.4# ip netns exec bm3 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
8: bm3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:05 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.5/24 brd 192.168.2.255 scope global dynamic bm3
       valid_lft 360056sec preferred_lft 360056sec
    inet6 fe80::ac:10ff:feff:105/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm3 ping 192.168.2.1 -c 2
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=254 time=0.532 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=254 time=0.298 ms

--- 192.168.2.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 57ms
rtt min/avg/max/mdev = 0.298/0.415/0.532/0.117 ms
```

5. bm4通过dhcp获取ip地址
```
bash-4.4# ip netns exec bm4 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
9: bm4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:06 brd ff:ff:ff:ff:ff:ff
    inet6 fe80::ac:10ff:feff:106/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm4 pkill dhclient
bash-4.4# ip netns exec bm4 dhclient bm4
bash-4.4# ip netns exec bm4 ip a
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
9: bm4: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether 02:ac:10:ff:01:06 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.6/24 brd 192.168.2.255 scope global dynamic bm4
       valid_lft 360055sec preferred_lft 360055sec
    inet6 fe80::ac:10ff:feff:106/64 scope link 
       valid_lft forever preferred_lft forever
bash-4.4# ip netns exec bm4 ping 192.168.2.1 -c 2
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=254 time=0.398 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=254 time=0.257 ms

--- 192.168.2.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 57ms
rtt min/avg/max/mdev = 0.257/0.327/0.398/0.072 ms
```