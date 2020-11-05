#!/bin/bash -x

docker run -d -it --name vtep5700 --network host --privileged -v /root/ovn_lab/lesson/ovn/l2gateway-openstack/:/root/ovn_lab -v /var/run/openvswitch:/var/run/openvswitch ovn_lab:v2 bash
