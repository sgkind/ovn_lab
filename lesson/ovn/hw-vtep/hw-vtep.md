## 目标
```
underlay

---------------------192.168.200.0/19-------------------------
            |                                   |
            |192.168.200.70                     |192.168.200.71
       -----------                         -----------
       |         |                         |         |
       | host-ovn|                         | host-hv1|
       |         |                         |         |
       -----------                         -----------
            |                                   |
            |192.168.110.3                      |192.168.110.4
---------------------192.168.110.0/24-------------------------- 
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
# cd ovn_lab/lesson/ovn/hw-vtep
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
# cd ovn_lab/lesson/ovn/hw-vtep
# ./start_host.sh
# docker exec -it vtep5700 bash
# start_ovs.sh
# start_ovn_controller.sh
# cd root/ovn_lab
# ./create_topo_host_hv1.sh
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