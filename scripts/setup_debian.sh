#!/bin/bash

############################################################
# Kubernetes Install Script for Debian 11 (Bullseye)
# This script installed the container runtime cri-o
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
echo " adding k8s repositories..."
echo "#############################################"
apt-get update
apt-get install -y gnupg curl
# Add kubernetes repository  
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list


echo "#############################################"
echo " configure prerequisites for container runtime"
echo "#############################################"
# Find Details here: https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

echo "#############################################"
echo " installing container runtime CRI-O...."
echo "#############################################"
# See  also: https://github.com/cri-o/cri-o/blob/main/install.md#readme"
OS=Debian_11
VERSION=1.23
# Update repo
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

mkdir -p /usr/share/keyrings
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

apt-get update
apt-get install -y cri-o cri-o-runc
apt-mark hold cri-o cri-o-runc

# Start and enable CRI-O
systemctl daemon-reload
systemctl enable crio --now



echo "#############################################"
echo " installing kubernetes...."
echo "#############################################"
apt install -y kubelet=1.25.4-00 kubeadm=1.25.4-00 kubectl=1.25.4-00 open-iscsi apache2-utils ufw
apt-mark hold kubeadm kubelet kubectl


echo "#############################################"
echo " setup completed."
echo "#############################################"
echo " "
echo " "

echo "#####################################################################################"
echo "# Kubernetes is now installed. To setup a new kubernetes cluster with a master node "
echo "# run:"
echo "#  $ kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[YOUR-NODE-IP-ADDRESS]"
echo "# "
echo "# This command will setup a new cluster. Follow the instructions of the output."
echo "# The output will show also the command how to join a worker node."
echo "# You can use this script also to install a worker node. "
echo "#####################################################################################"


