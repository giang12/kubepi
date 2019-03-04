#!/bin/bash -e
node_id=$1
hostname=$2
address=$3

subnet=192.168.42
start_ip=100
node_id=`echo "$start_ip + $node_id" | bc`

sleep 2
./rpc/_setup.sh "lucy" $address "pi"  --del-init-user #raspberry
sleep 2
./rpc/_setup.sh $USER $address "lucy"

sleep 2
./rpc/_set_hostname.sh $USER $address $hostname

sleep 2
./rpc/_set_static_ip.sh $USER $address "$subnet.$node_id"

sleep 2
./rpc/_reboot.sh $USER $address

