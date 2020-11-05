#!/bin/bash -x

#/usr/share/openvswitch/scripts/ovs-ctl start 
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int1 -- set Bridge br-int1 fail-mode=secure
ovs-vsctl br-set-external-id br-int1 bridge-id br-int1

ovs-vsctl set open . external-ids:ovn-bridge=br-int1
ovs-vsctl set open . external-ids:system-id=gw
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.209.190:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.209.192

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl --may-exist add-br br-ext1 
ovs-vsctl br-set-external-id br-ext1 bridge-id br-ext1

ovs-vsctl add-port br-ext1 bm1 -- set interface bm1 type=internal
ip link set bm1 address 02:ac:10:ff:01:03
ip netns add bm1
ip link set bm1 netns bm1
ip netns exec bm1 ip link set bm1 up
ip netns exec bm1 ip address add 10.0.0.253/24 dev bm1


ovs-vsctl --may-exist add-br br-ext2
ovs-vsctl br-set-external-id br-ext2 bridge-id br-ext2

ovs-vsctl add-port br-ext2 bm2 -- set interface bm2 type=internal
ip link set bm2 address 02:ac:10:ff:01:04
ip netns add bm2
ip link set bm2 netns bm2
ip netns exec bm2 ip link set bm2 up
ip netns exec bm2 ip address add 20.0.0.253/24 dev bm2

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext1:br-ext1,ext2:br-ext2
