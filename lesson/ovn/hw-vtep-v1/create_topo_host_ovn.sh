#!/bin/bash -x

function add_vm1(){
  ip netns add vm1
  ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
  ip link set vm1 address 02:ac:10:ff:01:30
  ip link set vm1 netns vm1
  ovs-vsctl set Interface vm1 external_ids:iface-id=inside-vm1
  pkill dhclient
  ip netns exec vm1 dhclient vm1
}

function add_vm3(){
  ip netns add vm3
  ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
  ip link set vm3 address 02:ac:10:ff:01:33
  ip link set vm3 netns vm3
  ovs-vsctl set Interface vm3 external_ids:iface-id=inside2-vm3
  pkill dhclient
  ip netns exec vm3 dhclient vm3
}

function add_br_int(){
  ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
  ovs-vsctl set open . external-ids:ovn-remote=tcp:127.0.0.1:6642
  ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
  ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.3
  ovn-nbctl set-connection ptcp:6641:0.0.0.0
  ovn-sbctl set-connection ptcp:6642:0.0.0.0
}

add_br_int
stop_ovn_controller.sh
start_ovn_controller.sh

LOCAL_CHASSIS=`ovn-sbctl show | grep Chassis | awk '{print $2}' | sed 's/"//g'`

#ovn-nbctl lr-add router1
ovn-nbctl create Logical_Router name=router1 #options:chassis=$LOCAL_CHASSIS
ovn-nbctl ls-add inside
ovn-nbctl lrp-add router1 router1-inside 02:ac:10:ff:00:01 10.0.0.1/24
ovn-nbctl lsp-add inside inside-router1
ovn-nbctl lsp-set-type inside-router1 router
ovn-nbctl lsp-set-addresses inside-router1 02:ac:10:ff:00:01
ovn-nbctl lsp-set-options inside-router1 router-port=router1-inside
ovn-nbctl lsp-add inside inside-vm1
ovn-nbctl lsp-set-addresses inside-vm1 "02:ac:10:ff:01:30 10.0.0.2"
ovn-nbctl lsp-set-port-security inside-vm1 "02:ac:10:ff:01:30 10.0.0.2"

ovn-nbctl lsp-add inside inside-vm2
ovn-nbctl lsp-set-addresses inside-vm2 "02:ac:10:ff:01:31 10.0.0.3"
ovn-nbctl lsp-set-port-security inside-vm2 "02:ac:10:ff:01:31 10.0.0.3"

ovn-nbctl lsp-add inside inside-vtep-gateway
ovn-nbctl lsp-set-addresses inside-vtep-gateway "6c:b3:11:1c:cc:58 10.0.0.200"
ovn-nbctl lsp-set-port-security inside-vtep-gateway "6c:b3:11:1c:cc:58 10.0.0.200"
dhcptemp=`ovn-nbctl create DHCP_Options cidr=10.0.0.0/24 options="\"server_id\"=\"10.0.0.1\" \"server_mac\"=\"02:ac:10:ff:01:29\" \"lease_time\"=\"3600\" \"router\"=\"10.0.0.1\""`

ovn-nbctl lsp-add inside inside-vtep-gateway2
ovn-nbctl lsp-set-addresses inside-vtep-gateway2 "6c:b3:11:1c:cf:fc 10.0.0.201"
ovn-nbctl lsp-set-port-security inside-vtep-gateway2 "6c:b3:11:1c:cf:fc 10.0.0.201"

ovn-nbctl lsp-set-dhcpv4-options inside-vm1 $dhcptemp
ovn-nbctl lsp-set-dhcpv4-options inside-vm2 $dhcptemp
ovn-nbctl lsp-set-dhcpv4-options inside-vtep-gateway $dhcptemp


ovn-nbctl ls-add inside2
ovn-nbctl lrp-add router1 router1-inside2 02:ac:10:ff:00:02 10.0.1.1/24
ovn-nbctl lsp-add inside2 inside2-router1
ovn-nbctl lsp-set-type inside2-router1 router
ovn-nbctl lsp-set-addresses inside2-router1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options inside2-router1 router-port=router1-inside2

ovn-nbctl lsp-add inside2 inside2-vm3
ovn-nbctl lsp-set-addresses inside2-vm3 "02:ac:10:ff:01:33 10.0.1.2"
ovn-nbctl lsp-set-port-security inside2-vm3 "02:ac:10:ff:01:33 10.0.1.2"

ovn-nbctl lsp-add inside2 inside2-vm4
ovn-nbctl lsp-set-addresses inside2-vm4 "02:ac:10:ff:01:34 10.0.1.3"
ovn-nbctl lsp-set-port-security inside2-vm4 "02:ac:10:ff:01:34 10.0.1.3"

dhcptemp1=`ovn-nbctl create DHCP_Options cidr=10.0.1.0/24 options="\"server_id\"=\"10.0.1.1\" \"server_mac\"=\"02:ac:10:ff:01:29\" \"lease_time\"=\"3600\" \"router\"=\"10.0.1.1\""`
ovn-nbctl lsp-set-dhcpv4-options inside2-vm3 $dhcptemp1
ovn-nbctl lsp-set-dhcpv4-options inside2-vm4 $dhcptemp1

ovn-nbctl lsp-add inside2 inside2-vtep-gateway2
ovn-nbctl lsp-set-addresses inside2-vtep-gateway2 "6c:b3:11:1c:cf:fd 10.0.1.201"
ovn-nbctl lsp-set-port-security inside-vtep-gateway2 "6c:b3:11:1c:cf:fd 10.0.1.201"


add_vm1
add_vm3

ovn-nbctl lsp-set-type inside-vtep-gateway vtep
ovn-nbctl lsp-set-options inside-vtep-gateway vtep-physical-switch=br0 vtep-logical-switch=ls0

#ovn-nbctl lsp-set-type inside-vtep-gateway2 vtep
#ovn-nbctl lsp-set-options inside-vtep-gateway2 vtep-physical-switch=br0 vtep-logical-switch=ls1

#ovn-nbctl lsp-set-type inside2-vtep-gateway2 vtep
#ovn-nbctl lsp-set-options inside2-vtep-gateway2 vtep-physical-switch=br0 vtep-logical-switch=ls2