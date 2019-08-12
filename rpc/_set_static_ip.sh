#!/bin/bash -e
user=$1
address=$2
static_ip=${3:-10.0.0.100}

routers="10.0.0.1"
domain_name_servers="10.0.0.1 8.8.8.8"
search_domains="lucy.local"

ssh $user@$address << EOF
echo "Setting static ip to $static_ip"
  
sudo sh -c 'echo "interface eth0
static ip_address=$static_ip/24
static routers=$routers
static domain_name_servers=$domain_name_servers" >> /etc/dhcpcd.conf'
EOF
