#!/bin/bash -e

host="kubepileader"
address=$1


ssh $USER@$address << EOF  
if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "Kubeadm already initialized. Nothing to do"
else
  echo "Initializing kubeadm"
  sudo kubeadm config images pull -v3
  sudo kubeadm init \
    --token-ttl=0 \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-advertise-address $address
  mkdir ~/pki
  sudo cp /etc/kubernetes/pki/* ~/pki
  sudo chown $USER ~/pki/*
fi
EOF

./login.sh $address
kubectl apply -f manifests/flannel.yml
