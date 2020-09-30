#!/bin/bash -x

/usr/share/openvswitch/scripts/ovs-ctl start 
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:system-id=gw1
ovs-vsctl set open . external-ids:ovn-remote=tcp:192.168.200.70:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=192.168.110.6

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl --may-exist add-br br-ext 
ovs-vsctl br-set-external-id br-ext bridge-id br-ext
ovs-vsctl br-set-external-id br-int bridge-id br-int
ovs-vsctl add-port br-ext ens5
ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext:br-ext
