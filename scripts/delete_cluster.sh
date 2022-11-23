#!/bin/bash

############################################################
# This script deletes a Kubernetes cluster!
# Be carefull in usage - all data will be lost!
# 
# run as sudo 
############################################################

 
# determine if we run as sudo
userid="${SUDO_USER:-$USER}"
if [ "$userid" == 'root' ]
  then 
    echo "Please run the setup as sudo and not as root!"
    exit 1
fi
if [ "$EUID" -ne 0 ]
  then 
    echo "Please run setup as sudo!"
    exit 1
fi

echo "#############################################"
echo " deleteing cluster!!!"
echo "#############################################"
kubeadm reset
# delete config files and etcd
rm -fr ~/.kube/
rm -fr /etc/cni/

echo " restart cri-o..."
systemctl restart crio
