#!/bin/bash -x

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:system-id=hv1
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.209.70:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.3

stop_ovn_controller.sh
start_ovn_controller.sh

function add_vm2() {
  ip netns add vm2
  ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
  ip link set vm2 netns vm2
  ip netns exec vm2 ip link set vm2 address 02:ac:10:ff:01:03
  ip netns exec vm2 ip addr add 10.0.1.3/24 dev vm2
  ip netns exec vm2 ip link set vm2 up
  ip netns exec vm2 ip route add default via 10.0.1.1
  ip netns exec vm2 ip route add 10.0.0.0/24 via 10.0.1.254
  ip netns exec vm2 ip route add 192.168.10.0/24 via 10.0.1.254
  ip netns exec vm2 ip route add 192.168.20.0/24 via 10.0.1.254
  ovs-vsctl set Interface vm2 external_ids:iface-id=inside1-vm2
}

function add_vm4() {
  ip netns add vm4
  ovs-vsctl add-port br-int vm4 -- set interface vm4 type=internal
  ip link set vm4 netns vm4
  ip netns exec vm4 ip link set vm4 address 02:ac:10:ff:02:03
  ip netns exec vm4 ip addr add 10.0.2.3/24 dev vm4
  ip netns exec vm4 ip link set vm4 up
  ip netns exec vm4 ip route add default via 10.0.2.1
  ip netns exec vm4 ip route add 10.0.0.0/24 via 10.0.2.254
  ip netns exec vm4 ip route add 192.168.10.0/24 via 10.0.2.254
  ip netns exec vm4 ip route add 192.168.20.0/24 via 10.0.2.254
  ovs-vsctl set Interface vm4 external_ids:iface-id=inside2-vm4
}

function add_vm6() {
  ip netns add vm6
  ovs-vsctl add-port br-int vm6 -- set interface vm6 type=internal
  ip link set vm6 netns vm6
  ip netns exec vm6 ip link set vm6 address 02:ac:10:ff:03:03
  ip netns exec vm6 ip addr add 10.0.3.3/24 dev vm6
  ip netns exec vm6 ip link set vm6 up
  ip netns exec vm6 ip route add default via 10.0.3.1
  ip netns exec vm6 ip route add 10.0.0.0/24 via 10.0.3.254
  ip netns exec vm6 ip route add 192.168.10.0/24 via 10.0.3.254
  ip netns exec vm6 ip route add 192.168.20.0/24 via 10.0.3.254
  ovs-vsctl set Interface vm6 external_ids:iface-id=inside3-vm6
}

function add_vm8() {
  ip netns add vm8
  ovs-vsctl add-port br-int vm8 -- set interface vm8 type=internal
  ip link set vm8 netns vm8
  ip netns exec vm8 ip link set vm8 address 02:ac:10:ff:04:03
  ip netns exec vm8 ip addr add 10.0.4.3/24 dev vm8
  ip netns exec vm8 ip link set vm8 up
  ip netns exec vm8 ip route add default via 10.0.4.1
  ip netns exec vm8 ip route add 10.0.0.0/24 via 10.0.4.254
  ip netns exec vm8 ip route add 192.168.10.0/24 via 10.0.4.254
  ip netns exec vm8 ip route add 192.168.20.0/24 via 10.0.4.254
  ovs-vsctl set Interface vm8 external_ids:iface-id=inside4-vm8
}


add_vm2
add_vm4
add_vm6
add_vm8