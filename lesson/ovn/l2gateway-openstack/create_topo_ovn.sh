#!/bin/bash -x

/usr/share/ovn/scripts/ovn-ctl start_northd

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovn-nbctl ls-add ls1
ovn-nbctl ls-add ls2
ovn-nbctl ls-add lgs1
ovn-nbctl ls-add lgs2
#ovn-nbctl ls-add external-switch

#ovn-nbctl lsp-add external-switch external-localnet
#ovn-nbctl lsp-set-addresses external-localnet unknown
#ovn-nbctl lsp-set-type external-localnet localnet
#ovn-nbctl lsp-set-options external-localnet network_name=ext

ovn-nbctl lr-add R1
ovn-nbctl lrp-add R1 ls1-port 00:00:10:00:01:01 10.0.1.1/24
ovn-nbctl lrp-add R1 ls2-port 00:00:10:00:02:01 10.0.2.1/24
ovn-nbctl lrp-add R1 lgs1-port 00:00:10:00:00:fe 10.0.0.254/24
ovn-nbctl lrp-add R1 lgs2-port 00:00:20:00:00:fe 20.0.0.254/24

#ovn-nbctl lrp-add R1 external-port 00:00:01:01:02:05 10.20.0.100/24

ovn-nbctl lsp-add ls1 r1-ls1-port \
          -- lsp-set-options r1-ls1-port router-port=ls1-port \
          -- lsp-set-type r1-ls1-port router \
          -- lsp-set-addresses r1-ls1-port router

ovn-nbctl lsp-add ls2 r1-ls2-port \
          -- lsp-set-options r1-ls2-port router-port=ls2-port \
          -- lsp-set-type r1-ls2-port router \
          -- lsp-set-addresses r1-ls2-port router

ovn-nbctl lsp-add lgs1 r1-lgs1-port \
          -- lsp-set-options r1-lgs1-port router-port=lgs1-port \
          -- lsp-set-type r1-lgs1-port router \
          -- lsp-set-addresses r1-lgs1-port router

ovn-nbctl lsp-add lgs2 r1-lgs2-port \
          -- lsp-set-options r1-lgs2-port router-port=lgs2-port \
          -- lsp-set-type r1-lgs2-port router \
          -- lsp-set-addresses r1-lgs2-port router

#ovn-nbctl lsp-add external-switch r1-external-port \
#          -- lsp-set-options r1-external-port router-port=external-port \
#          -- lsp-set-type r1-external-port router \
#          -- lsp-set-addresses r1-external-port 


ovn-nbctl lsp-add ls1 vm1
ovn-nbctl lsp-set-addresses vm1 "00:00:10:00:01:0a 10.0.1.10"

ovn-nbctl lsp-add ls1 vm2
ovn-nbctl lsp-set-addresses vm2 "00:00:10:00:01:0b 10.0.1.11"

ovn-nbctl lsp-add ls2 vm3
ovn-nbctl lsp-set-addresses vm3 "00:00:10:00:02:0a 10.0.2.10"

ovn-nbctl lsp-add ls2 vm4
ovn-nbctl lsp-set-addresses vm4 "00:00:10:00:02:0b 10.0.2.11"

ovn-nbctl lsp-add lgs1 vm5
ovn-nbctl lsp-set-addresses vm5 "00:00:10:00:00:c8 10.0.0.200"

ovn-nbctl lsp-add lgs2 vm6
ovn-nbctl lsp-set-addresses vm6 "00:00:20:00:00:c8 20.0.0.200"

ovn-nbctl lsp-add lgs1 lgs1-l2gateway
ovn-nbctl lsp-set-addresses lgs1-l2gateway unknown
ovn-nbctl lsp-set-type lgs1-l2gateway l2gateway
ovn-nbctl lsp-set-options lgs1-l2gateway network_name=ext1 l2gateway-chassis=gw

ovn-nbctl lsp-add lgs2 lgs2-l2gateway
ovn-nbctl lsp-set-addresses lgs2-l2gateway unknown
ovn-nbctl lsp-set-type lgs2-l2gateway l2gateway
ovn-nbctl lsp-set-options lgs2-l2gateway network_name=ext2 l2gateway-chassis=gw


/usr/share/openvswitch/scripts/ovs-ctl start --system-id=random
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode==secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=tcp:127.0.0.1:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.209.190

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

function add_vm1() {
    ip netns add vm1
    ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
    ip link set vm1 netns vm1
    ip netns exec vm1 ip link set vm1 address 00:00:10:00:01:0a
    ip netns exec vm1 ip addr add 10.0.1.10/24 dev vm1
    ip netns exec vm1 ip link set vm1 up
    ip netns exec vm1 ip route add default via 10.0.1.1
    ovs-vsctl set Interface vm1 external_ids:iface-id=vm1
}

function add_vm3() {
    ip netns add vm3
    ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
    ip link set vm3 netns vm3
    ip netns exec vm3 ip link set vm3 address 00:00:10:00:02:0a
    ip netns exec vm3 ip addr add 10.0.2.10/24 dev vm3
    ip netns exec vm3 ip link set vm3 up
    ip netns exec vm3 ip route add default via 10.0.2.1
    ovs-vsctl set Interface vm3 external_ids:iface-id=vm3
}

add_vm1
add_vm3