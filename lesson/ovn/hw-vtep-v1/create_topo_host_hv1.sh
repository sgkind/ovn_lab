#!/bin/bash -x

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.200.70:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.4

stop_ovn_controller.sh
start_ovn_controller.sh

function add_vm2() {
    ip netns add vm2
    ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
    ip link set vm2 address 02:ac:10:ff:01:31
    ip link set vm2 netns vm2
    ovs-vsctl set Interface vm2 external_ids:iface-id=inside-vm2
    ip netns exec vm2 pkill dhclient
    ip netns exec vm2 dhclient vm2
}

function add_vm4() {
    ip netns add vm4
    ovs-vsctl add-port br-int vm4 -- set interface vm4 type=internal
    ip link set vm4 address 02:ac:10:ff:01:34
    ip link set vm4 netns vm4
    ovs-vsctl set Interface vm4 external_ids:iface-id=inside2-vm4
    ip netns exec vm4 pkill dhclient
    ip netns exec vm4 dhclient vm4
}


add_vm2
add_vm4