#!/bin/bash

echo $'\nnet.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p
echo "VERIFY PLEASE"
sysctl net.ipv4.tcp_congestion_control

