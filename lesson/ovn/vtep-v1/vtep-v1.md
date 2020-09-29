## 目标
```
topo
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
- bare metal的mac地址为: 02:ac:10:ff:01:03 ip地址为: 10.0.0.3
- vtep为软件模拟的vtep

## build image
```
# cd ovn_lab/docker
# docker build -t ovn_lab:v1 .
```

## run container
```
# cd ovn_lab/lesson/ovn/vtep-v1
# ./start_compose.sh
```

## 构建host-ovn
```
# docker exec -it host-ovn bash
# start_ovs.sh
# start_ovn_northd.sh
# start_ovn_controller.sh
# cd root/ovn_lab
# ./create_topo_host_ovn.sh
```

## 构建host-hv1
```
# docker exec -it host-hv1 bash
# start_ovs.sh
# start_ovn_controller.sh
# cd root/ovn_lab
# ./create_topo_host_hv1.sh
```

## 构建host-vtep
```
# docker exec -it host-vtep bash
# start_ovs.sh
# cd root/ovn_lab
# ./create_topo_host_vtep.sh
```

## 测试
在host-vtep中
1. bare metal ping vm1
```
ip netns exec gateway ping 10.0.0.1 -c 3
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=6.44 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=64 time=0.103 ms
64 bytes from 10.0.0.1: icmp_seq=3 ttl=64 time=0.234 ms

--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 0.103/2.260/6.443/2.958 ms
```

2. bare metal ping vm3
```
ip netns exec gateway ping 10.0.0.4 -c 3
PING 10.0.0.4 (10.0.0.4) 56(84) bytes of data.
64 bytes from 10.0.0.4: icmp_seq=1 ttl=64 time=4.77 ms
64 bytes from 10.0.0.4: icmp_seq=2 ttl=64 time=0.104 ms
64 bytes from 10.0.0.4: icmp_seq=3 ttl=64 time=0.284 ms

--- 10.0.0.4 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2001ms
rtt min/avg/max/mdev = 0.104/1.719/4.770/2.158 ms
```

3. bare metal ping vm4
```
ip netns exec gateway ping 10.0.1.2 -c 3
PING 10.0.1.2 (10.0.1.2) 56(84) bytes of data.
64 bytes from 10.0.1.2: icmp_seq=1 ttl=63 time=10.4 ms
64 bytes from 10.0.1.2: icmp_seq=2 ttl=63 time=0.255 ms
64 bytes from 10.0.1.2: icmp_seq=3 ttl=63 time=0.144 ms

--- 10.0.1.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 0.144/3.607/10.424/4.820 ms
```

4. bare metal ping vm5
```
ip netns exec gateway ping 10.0.1.3 -c 3
PING 10.0.1.3 (10.0.1.3) 56(84) bytes of data.
64 bytes from 10.0.1.3: icmp_seq=1 ttl=63 time=11.4 ms
64 bytes from 10.0.1.3: icmp_seq=2 ttl=63 time=0.507 ms
64 bytes from 10.0.1.3: icmp_seq=3 ttl=63 time=0.314 ms

--- 10.0.1.3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.314/4.103/11.490/5.224 ms
```

注：
本实验中router1不是分布式的，是固定的。