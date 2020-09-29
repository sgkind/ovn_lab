#!/bin/bash -x

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

stop_ovn_controller.sh
start_ovn_controller.sh

function add_vm3() {
    ip netns add vm3
    ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
    ip link set vm3 address 02:ac:10:ff:01:32
    ip link set vm3 netns vm3
    ovs-vsctl set Interface vm3 external_ids:iface-id=inside-vm3
    ip netns exec vm3 pkill dhclient
    ip netns exec vm3 dhclient vm3
}

function add_vm5() {
    ip netns add vm5
    ovs-vsctl add-port br-int vm5 -- set interface vm5 type=internal
    ip link set vm5 address 02:ac:10:ff:01:34
    ip link set vm5 netns vm5
    ovs-vsctl set Interface vm5 external_ids:iface-id=vm5
    ip netns exec vm5 pkill dhclient
    ip netns exec vm5 dhclient vm5
}


add_vm3
add_vm5