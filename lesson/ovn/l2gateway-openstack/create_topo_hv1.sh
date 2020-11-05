#!/bin/bash -x

/usr/share/openvswitch/scripts/ovs-ctl start --system-id=random
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.209.190:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.209.191

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller


function add_vm2() {
    ip netns add vm2
    ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
    ip link set vm2 netns vm2
    ip netns exec vm2 ip link set vm2 address 00:00:10:00:01:0b
    ip netns exec vm2 ip addr add 10.0.1.11/24 dev vm2
    ip netns exec vm2 ip link set vm2 up
    ip netns exec vm2 ip route add default via 10.0.1.1
    ovs-vsctl set Interface vm2 external_ids:iface-id=vm2
}

function add_vm4() {
    ip netns add vm4
    ovs-vsctl add-port br-int vm4 -- set interface vm4 type=internal
    ip link set vm4 netns vm4
    ip netns exec vm4 ip link set vm4 address 00:00:10:00:02:0b
    ip netns exec vm4 ip addr add 10.0.2.11/24 dev vm4
    ip netns exec vm4 ip link set vm4 up
    ip netns exec vm4 ip route add default via 10.0.2.1
    ovs-vsctl set Interface vm4 external_ids:iface-id=vm4
}

function add_vm5() {
    ip netns add vm5 
    ovs-vsctl add-port br-int vm5 -- set interface vm5 type=internal
    ip link set vm5 netns vm5 
    ip netns exec vm5 ip link set vm5 address 00:00:10:00:00:c8
    ip netns exec vm5 ip addr add 10.0.0.200/24 dev vm5
    ip netns exec vm5 ip link set vm5 up
    ip netns exec vm5 ip route add default via 10.0.0.254
    ovs-vsctl set Interface vm5 external_ids:iface-id=vm5
}

function add_vm6() {
    ip netns add vm6
    ovs-vsctl add-port br-int vm6 -- set interface vm6 type=internal
    ip link set vm6 netns vm6
    ip netns exec vm6 ip link set vm6 address 00:00:20:00:00:c8
    ip netns exec vm6 ip addr add 20.0.0.200/24 dev vm6
    ip netns exec vm6 ip link set vm6 up
    ip netns exec vm6 ip route add default via 20.0.0.254
    ovs-vsctl set Interface vm6 external_ids:iface-id=vm6
}

add_vm2
add_vm4
add_vm5
add_vm6