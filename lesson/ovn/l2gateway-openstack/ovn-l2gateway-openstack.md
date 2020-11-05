## 目标

```
underlay
   openstack ovs网络---------       -----------openstack ovs网络
                       |                 | 
                       |   -----------   |
                       ----|   gw    |----
                           ----------- 
                                |     
                                |     
     ------------------------internal------------------------
              |                                     |        
              |                                     |        
         -----------                           ------------  
         |computer1|                           |controller|  
         -----------                           ------------  

overlay topo
                -----------------------------------------------      
                |                      R1                     |      
                -----------------------------------------------      
           10.0.1.1|     10.0.2.1 |  10.0.0.254|  20.0.0.254|  
                   |              |            |            | 
                   |              |            |            |  
                ---------     ---------    ---------    --------- 
                |  ls1  |     |  ls2  |    |  lgs1 |    |  lgs2 |   
                ---------     ---------    ---------    ---------
                 |     |        |    |       |    |       |    |      
                vm1   vm2      vm3  vm4     vm5   |      vm6   |
                                                  |            |
                                       openstack subnet1    openstack subnet2
```
- 通过ovn的l2gateway将ovn虚拟网络与openstack中的ovs虚拟网络在二层打通

其中:
* vm1: 10.0.1.10
* vm2: 10.0.1.11
* vm3: 10.0.2.10
* vm4: 10.0.2.11
* vm5: 10.0.0.200
* vm6: 20.0.0.200

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/docker
./build_v2.sh
```

## 节点
1. ovn节点
ip地址为192.168.209.190

2. hv1节点
ip地址为192.168.209.191

3. gw节点
ip地址为192.168.209.192
在此节点上需要配置openstack的l2gateway

## run container
1. ovn
```
./start_host.sh
```

2. hv1
```
./start_host.sh
```

3. gw
```
./start_gw_host.sh
```

## 创建拓扑
1. ovn
```
# docker exec -it vtep5700 /root/ovn_lab/create_topo_ovn.sh
```

2. hv1
```
# docker exec -it vtep5700 /root/ovn_lab/create_topo_hv1.sh
```

3. gw
```
# docker exec -it vtep5700 /root/ovn_lab/create_topo_gw.sh
```

## 将openstack网络中暴露出来的端口添加到ovn的网络中
```
# ovs-vsctl add-port br-ext1 veth-2-br
# ovs-vsctl add-port br-ext2 veth2-2-br
```

## 测试
以下的测试都是在hv1主机上执行的

1. 进入容器
```
# docker exec -it vtep5700 bash
```

2. vm5 ping openstack的网关10.0.0.1
```
# ip netns exec vm5 ping 10.0.0.1 -c 2
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=1.17 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=64 time=1.20 ms

--- 10.0.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 1.173/1.188/1.204/0.037 ms
```

3. vm5 ping openstack中的10.0.0.2
```
# ip netns exec vm5 ping 10.0.0.2 -c 2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=3.85 ms
64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=1.58 ms

--- 10.0.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 1.583/2.717/3.852/1.135 ms
```

4. vm6 ping openstack中的20.0.0.2
```
# ip netns exec vm6 ping 20.0.0.2 -c 2
PING 20.0.0.2 (20.0.0.2) 56(84) bytes of data.
64 bytes from 20.0.0.2: icmp_seq=1 ttl=64 time=3.62 ms
64 bytes from 20.0.0.2: icmp_seq=2 ttl=64 time=1.44 ms

--- 20.0.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 1.444/2.533/3.622/1.089 ms

```