#!/bin/bash

############################################################
# setup ufw for a public Kubernetes Cluster
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

ufw allow ssh comment 'allow ssh access form anywhere'
# the https rule is only needed on master node
ufw allow 443 comment 'allow https only'

# Uncomment this to allow your kubernetes cluster to access your ceph nodes
# rreplace the public IPs
#ufw allow from x.y.a.b comment 'allow your ceph cluster nodes'
#ufw allow from x.y.a.c
#ufw allow from x.y.a.d

# Allow all outgoing
ufw default allow outgoing
ufw default deny incoming
ufw enable

# setup finished
#############################################################
