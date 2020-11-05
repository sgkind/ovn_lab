#!/bin/bash -x

function add_vm1(){
  ip netns add vm1
  ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
  ip link set vm1 netns vm1
  ip netns exec vm1 ip link set vm1 address 02:ac:10:ff:01:02
  ip netns exec vm1 ip addr add 10.0.1.2/24 dev vm1
  ip netns exec vm1 ip link set vm1 up
  ip netns exec vm1 ip route add default via 10.0.1.1
  ip netns exec vm1 ip route add 10.0.0.0/24 via 10.0.1.254
  ip netns exec vm1 ip route add 192.168.10.0/24 via 10.0.1.254
  ip netns exec vm1 ip route add 192.168.20.0/24 via 10.0.1.254
  ovs-vsctl set Interface vm1 external_ids:iface-id=inside1-vm1
}

function add_vm3(){
  ip netns add vm3
  ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
  ip link set vm3 netns vm3
  ip netns exec vm3 ip link set vm3 address 02:ac:10:ff:02:02
  ip netns exec vm3 ip addr add 10.0.2.2/24 dev vm3
  ip netns exec vm3 ip link set vm3 up
  ip netns exec vm3 ip route add default via 10.0.2.1
  ip netns exec vm3 ip route add 10.0.0.0/24 via 10.0.2.254
  ip netns exec vm3 ip route add 192.168.10.0/24 via 10.0.2.254
  ip netns exec vm3 ip route add 192.168.20.0/24 via 10.0.2.254
  ovs-vsctl set Interface vm3 external_ids:iface-id=inside2-vm3
}

function add_vm5() {
  ip netns add vm5
  ovs-vsctl add-port br-int vm5 -- set interface vm5 type=internal
  ip link set vm5 netns vm5
  ip netns exec vm5 ip link set vm5 address 02:ac:10:ff:03:02
  ip netns exec vm5 ip addr add 10.0.3.2/24 dev vm5
  ip netns exec vm5 ip link set vm5 up
  ip netns exec vm5 ip route add default via 10.0.3.1
  ip netns exec vm5 ip route add 10.0.0.0/24 via 10.0.3.254
  ip netns exec vm5 ip route add 192.168.10.0/24 via 10.0.3.254
  ip netns exec vm5 ip route add 192.168.20.0/24 via 10.0.3.254
  ovs-vsctl set Interface vm5 external_ids:iface-id=inside3-vm5
}

function add_vm7() {
  ip netns add vm7
  ovs-vsctl add-port br-int vm7 -- set interface vm7 type=internal
  ip link set vm7 netns vm7
  ip netns exec vm7 ip link set vm7 address 02:ac:10:ff:04:02
  ip netns exec vm7 ip addr add 10.0.4.2/24 dev vm7
  ip netns exec vm7 ip link set vm7 up
  ip netns exec vm7 ip route add default via 10.0.4.1
  ip netns exec vm7 ip route add 10.0.0.0/24 via 10.0.4.254
  ip netns exec vm7 ip route add 192.168.10.0/24 via 10.0.4.254
  ip netns exec vm7 ip route add 192.168.20.0/24 via 10.0.4.254
  ovs-vsctl set Interface vm7 external_ids:iface-id=inside4-vm7
}

function add_br_int(){
  ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
  ovs-vsctl set open . external-ids:system-id=ovn
  ovs-vsctl set open . external-ids:ovn-remote=tcp:127.0.0.1:6642
  ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
  ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.2
  ovn-nbctl set-connection ptcp:6641:0.0.0.0
  ovn-sbctl set-connection ptcp:6642:0.0.0.0
}

add_br_int
stop_ovn_controller.sh
start_ovn_controller.sh

# 添加router_bm和router1
ovn-nbctl ls-add external
ovn-nbctl lsp-add external external-localnet
ovn-nbctl lsp-set-addresses external-localnet unknown
ovn-nbctl lsp-set-type external-localnet localnet
ovn-nbctl lsp-set-options external-localnet network_name=ext

ovn-nbctl create Logical_Router name=router1
ovn-nbctl lrp-add router1 external-port1 f0:00:00:00:00:01 192.168.209.74/19
ovn-nbctl lsp-add external router1-external-port \
          -- lsp-set-options router1-external-port router-port=external-port1 \
          -- lsp-set-type router1-external-port router  \
          -- lsp-set-addresses router1-external-port router

ovn-nbctl create Logical_Router name=router2
ovn-nbctl lrp-add router2 external-port2 f0:00:00:00:00:02 192.168.209.76/19
ovn-nbctl lsp-add external router2-external-port \
          -- lsp-set-options router2-external-port router-port=external-port2 \
          -- lsp-set-type router2-external-port router \
          -- lsp-set-addresses router2-external-port router

#ovn-nbctl lr-add router_bm 
ovn-nbctl create Logical_Router name=router_bm options:chassis=hv1

# 添加inside1
ovn-nbctl ls-add inside1

ovn-nbctl lrp-add router1 router1-inside1 02:ac:10:ff:01:01 10.0.1.1/24
ovn-nbctl lsp-add inside1 inside1-router1
ovn-nbctl lsp-set-type inside1-router1 router
ovn-nbctl lsp-set-addresses inside1-router1 "02:ac:10:ff:01:01 10.0.1.1"
ovn-nbctl lsp-set-options inside1-router1 router-port=router1-inside1

ovn-nbctl lrp-add router_bm bm-inside1 02:ac:10:ff:01:fe 10.0.1.254/24
ovn-nbctl lsp-add inside1 inside1-bm 
ovn-nbctl lsp-set-type inside1-bm router
ovn-nbctl lsp-set-addresses inside1-bm "02:ac:10:ff:01:fe 10.0.1.254/24"
ovn-nbctl lsp-set-options inside1-bm router-port=bm-inside1

ovn-nbctl lsp-add inside1 inside1-vm1
ovn-nbctl lsp-set-addresses inside1-vm1 "02:ac:10:ff:01:02 10.0.1.2"
ovn-nbctl lsp-set-port-security inside1-vm1 "02:ac:10:ff:01:02 10.0.1.2"

ovn-nbctl lsp-add inside1 inside1-vm2
ovn-nbctl lsp-set-addresses inside1-vm2 "02:ac:10:ff:01:03 10.0.1.3"
ovn-nbctl lsp-set-port-security inside1-vm2 "02:ac:10:ff:01:03 10.0.1.3"

# 添加inside2
ovn-nbctl ls-add inside2

ovn-nbctl lrp-add router1 router1-inside2 02:ac:10:ff:02:01 10.0.2.1/24
ovn-nbctl lsp-add inside2 inside2-router1
ovn-nbctl lsp-set-type inside2-router1 router
ovn-nbctl lsp-set-addresses inside2-router1 "02:ac:10:ff:02:01 10.0.2.1"
ovn-nbctl lsp-set-options inside2-router1 router-port=router1-inside2

ovn-nbctl lrp-add router_bm bm-inside2 02:ac:10:ff:02:fe 10.0.2.254/24
ovn-nbctl lsp-add inside2 inside2-bm
ovn-nbctl lsp-set-type inside2-bm router
ovn-nbctl lsp-set-addresses inside2-bm "02:ac:10:ff:02:fe 10.0.2.254/24"
ovn-nbctl lsp-set-options inside2-bm router-port=bm-inside2

ovn-nbctl lsp-add inside2 inside2-vm3
ovn-nbctl lsp-set-addresses inside2-vm3 "02:ac:10:ff:02:02 10.0.2.2"
ovn-nbctl lsp-set-port-security inside2-vm3 "02:ac:10:ff:02:02 10.0.2.2"

ovn-nbctl lsp-add inside2 inside2-vm4
ovn-nbctl lsp-set-addresses inside2-vm4 "02:ac:10:ff:02:03 10.0.2.3"
ovn-nbctl lsp-set-port-security inside2-vm4 "02:ac:10:ff:02:03 10.0.2.3"


ovn-nbctl ha-chassis-group-add hagrp1
ovn-nbctl ha-chassis-group-add-chassis hagrp1 gw1 30
ovn-nbctl ha-chassis-group-add-chassis hagrp1 gw2 50
ovn-nbctl set Logical_Router_Port external-port1 ha-chassis-group=`ovn-nbctl --bare --columns _uuid find ha_chassis_group name=hagrp1`
ovn-nbctl lr-nat-add router1 snat 192.168.209.74 10.0.1.0/24
ovn-nbctl lr-nat-add router1 snat 192.168.209.74 10.0.2.0/24
ovn-nbctl lr-route-add router1 "0.0.0.0/0" 192.168.209.74
ovn-nbctl lr-route-add router1 "192.168.10.0/24" 10.0.1.254
ovn-nbctl lr-route-add router1 "192.168.20.0/24" 10.0.1.254


# 添加inside3
ovn-nbctl ls-add inside3

ovn-nbctl lrp-add router2 router2-inside3 02:ac:10:ff:03:01 10.0.3.1/24
ovn-nbctl lsp-add inside3 inside3-router2
ovn-nbctl lsp-set-type inside3-router2 router
ovn-nbctl lsp-set-addresses inside3-router2 "02:ac:10:ff:03:01 10.0.3.1/24"
ovn-nbctl lsp-set-options inside3-router2 router-port=router2-inside3

ovn-nbctl lrp-add router_bm bm-inside3 02:ac:10:ff:03:fe 10.0.3.254/24
ovn-nbctl lsp-add inside3 inside3-bm
ovn-nbctl lsp-set-type inside3-bm router
ovn-nbctl lsp-set-addresses inside3-bm "02:ac:10:ff:03:fe 10.0.3.254/24"
ovn-nbctl lsp-set-options inside3-bm router-port=bm-inside3

ovn-nbctl lsp-add inside3 inside3-vm5
ovn-nbctl lsp-set-addresses inside3-vm5 "02:ac:10:ff:03:02 10.0.3.2/24"
ovn-nbctl lsp-set-port-security inside3-vm5 "02:ac:10:ff:03:02 10.0.3.2/24"

ovn-nbctl lsp-add inside3 inside3-vm6
ovn-nbctl lsp-set-addresses inside3-vm6 "02:ac:10:ff:03:03 10.0.3.3/24"
ovn-nbctl lsp-set-port-security inside3-vm6 "02:ac:10:ff:03:03 10.0.3.3/24"


# 添加inside4
ovn-nbctl ls-add inside4

ovn-nbctl lrp-add router2 router2-inside4 02:ac:10:ff:04:01 10.0.4.1/24
ovn-nbctl lsp-add inside4 inside4-router2
ovn-nbctl lsp-set-type inside4-router2 router
ovn-nbctl lsp-set-addresses inside4-router2 "02:ac:10:ff:04:01 10.0.4.1/24"
ovn-nbctl lsp-set-options inside4-router2 router-port=router2-inside4

ovn-nbctl lrp-add router_bm bm-inside4 02:ac:10:ff:04:fe 10.0.4.254/24
ovn-nbctl lsp-add inside4 inside4-bm
ovn-nbctl lsp-set-type inside4-bm router
ovn-nbctl lsp-set-addresses inside4-bm "02:ac:10:ff:04:fe 10.0.4.254/24"
ovn-nbctl lsp-set-options inside4-bm router-port=bm-inside4

ovn-nbctl lsp-add inside4 inside4-vm7
ovn-nbctl lsp-set-addresses inside4-vm7 "02:ac:10:ff:04:02 10.0.4.2/24"
ovn-nbctl lsp-set-port-security inside4-vm7 "02:ac:10:ff:04:02 10.0.4.2/24"

ovn-nbctl lsp-add inside4 inside4-vm8
ovn-nbctl lsp-set-addresses inside4-vm8 "02:ac:10:ff:04:03 10.0.4.3/24"
ovn-nbctl lsp-set-port-security inside4-vm8 "02:ac:10:ff:04:03 10.0.4.3/24"

#ovn-nbctl ha-chassis-group-add hagrp2
#ovn-nbctl ha-chassis-group-add-chassis hagrp2 gw1 50
#ovn-nbctl ha-chassis-group-add-chassis hagrp2 gw2 30
ovn-nbctl set Logical_Router_Port external-port2 ha-chassis-group=`ovn-nbctl --bare --columns _uuid find ha_chassis_group name=hagrp1`
ovn-nbctl lr-nat-add router2 snat 192.168.209.76 10.0.3.0/24
ovn-nbctl lr-nat-add router2 snat 192.168.209.76 10.0.4.0/24
ovn-nbctl lr-route-add router2 "0.0.0.0/0" 192.168.209.76


# 添加inside_bm
ovn-nbctl ls-add inside_bm

ovn-nbctl lrp-add router_bm bm-switch 02:ac:10:ff:00:01 10.0.0.1/24
ovn-nbctl lsp-add inside_bm switch-bm
ovn-nbctl lsp-set-type switch-bm router
ovn-nbctl lsp-set-addresses switch-bm "02:ac:10:ff:00:01 10.0.0.1/24"
ovn-nbctl lsp-set-options switch-bm router-port=bm-switch

ovn-nbctl lsp-add inside_bm inside-vtep-gateway
ovn-nbctl lsp-set-addresses inside-vtep-gateway unknown
#ovn-nbctl lsp-set-addresses inside-vtep-gateway "6c:b3:11:1c:cf:fc 10.0.0.201/24"


ovn-nbctl lr-route-add router_bm "0.0.0.0/0" 10.0.9.1
ovn-nbctl lr-route-add router_bm "192.168.10.0/24" 10.0.0.201
ovn-nbctl lr-route-add router_bm "192.168.20.0/24" 10.0.0.201


ovn-nbctl lr-add router_ext
ovn-nbctl lrp-add router_ext external-port3 f0:00:00:00:00:03 192.168.209.77/19
ovn-nbctl lsp-add external router-external-port \
          -- lsp-set-options router-external-port router-port=external-port3 \
          -- lsp-set-type router-external-port router \
          -- lsp-set-addresses router-external-port router

ovn-nbctl ls-add switch_ext

ovn-nbctl lrp-add router_ext router_ext-switch 02:ac:10:ff:09:01 10.0.9.1/24
ovn-nbctl lsp-add switch_ext switch-router_ext
ovn-nbctl lsp-set-type switch-router_ext router
ovn-nbctl lsp-set-addresses switch-router_ext "02:ac:10:ff:09:01 10.0.9.1/24"
ovn-nbctl lsp-set-options switch-router_ext router-port=router_ext-switch

ovn-nbctl lrp-add router_bm  router_bm-switch 02:ac:10:ff:09:fe 10.0.9.254/24
ovn-nbctl lsp-add switch_ext switch-router_bm
ovn-nbctl lsp-set-type switch-router_bm router
ovn-nbctl lsp-set-addresses switch-router_bm "02:ac:10:ff:09:fe 10.0.9.254/24"
ovn-nbctl lsp-set-options switch-router_bm router-port=router_bm-switch

ovn-nbctl set Logical_Router_Port external-port3 ha-chassis-group=`ovn-nbctl --bare --columns _uuid find ha_chassis_group name=hagrp1`
ovn-nbctl lr-route-add router_ext "0.0.0.0/0" 192.168.209.77
ovn-nbctl lr-route-add router_ext "10.0.0.0/24" 10.0.9.254
ovn-nbctl lr-route-add router_ext "192.168.10.0/24" 10.0.9.254
ovn-nbctl lr-route-add router_ext "192.168.20.0/24" 10.0.9.254
ovn-nbctl lr-nat-add router_ext snat 192.168.209.77 10.0.0.0/24
ovn-nbctl lr-nat-add router_ext snat 192.168.209.77 192.168.10.0/24
ovn-nbctl lr-nat-add router_ext snat 192.168.209.77 192.168.20.0/24

# 添加vm
add_vm1
add_vm3
add_vm5
add_vm7

ovn-nbctl lsp-set-type inside-vtep-gateway vtep
ovn-nbctl lsp-set-options inside-vtep-gateway vtep-physical-switch=br0 vtep-logical-switch=ls0