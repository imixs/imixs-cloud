#!/bin/sh

############################################################
# Kubernetes Install Script for CentOS 7
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
echo " install docker-ce"
echo "#############################################"

yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    
  
yum install -y docker-ce docker-ce-cli containerd.io

# Enable docker
systemctl start docker && systemctl enable docker


echo "#############################################"
echo " installing kubernetes...."
echo "#############################################"

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl open-iscsi htpasswd --disableexcludes=kubernetes
# Enable kubelet
systemctl enable --now kubelet

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux



cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables



#####################################################################################
# Kubernetes is now installed. To setup a new kubernetes cluster with a master node 
# run:
#  $ kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=[YOUR-NODE-IP-ADDRESS]
#
# This command will setup a new cluster. Follow the instructions of the output.
# The output will show also the command how to join a worker node.
# You can use this script also to install a worker node. 
#####################################################################################


