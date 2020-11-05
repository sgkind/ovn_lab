#!/bin/bash -x

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:system-id=gw2
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.209.70:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.5

stop_ovn_controller.sh
start_ovn_controller.sh

ovs-vsctl --may-exist add-br br-ext
ovs-vsctl br-set-external-id br-ext bridge-id br-ext
ovs-vsctl br-set-external-id br-int bridge-id br-int
ovs-vsctl add-port br-ext ens11
ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext:br-ext

function add_vm11() {
  ip netns add vm11
  ovs-vsctl add-port br-int vm11 -- set interface vm11 type=internal
  ip link set vm11 netns vm11
  ip netns exec vm11 ip link set vm11 address 02:ac:10:ff:00:04
  ip netns exec vm11 ip addr add 10.0.0.4/24 dev vm11
  ip netns exec vm11 ip link set vm11 up
  ip netns exec vm11 ip route add default via 10.0.0.1
  ip netns exec vm11 ip route add 192.168.10.0/24 via 10.0.0.201
  ip netns exec vm11 ip route add 192.168.20.0/24 via 10.0.0.201
  ovs-vsctl set Interface vm11 external_ids:iface-id=inside-vm11
}

#add_vm11